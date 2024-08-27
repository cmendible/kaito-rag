using System.Text;
using System.Text.RegularExpressions;

using KaitoRAG.Extensions;
using KaitoRAG.Services;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Schema;

namespace KaitoRAG;

internal class RootDialog(RootDialogConfiguration configuration) : Dialog
{
    private static readonly Regex ResponseExtractReferenceNumbersPattern = new(@"\[\^(\d+)\^\]", RegexOptions.Compiled, TimeSpan.FromSeconds(1));

    /// <inheritdoc/>>
    public override async Task<DialogTurnResult> BeginDialogAsync(DialogContext dc, object options = null, CancellationToken cancellationToken = default)
    {
        var turnContext = dc.Context;
        var activity = turnContext.Activity;
        var userId = activity.GetUserId();
        var query = activity.Text?.Trim();

        // Do not start the dialog if the user is not asking anything...
        if (!string.IsNullOrWhiteSpace(query))
        {
            var searchTasks = new[]
            {
                configuration.UserSearchService.SearchRecordsAsync(query, userId, cancellationToken),
                configuration.GlobalSearchService.SearchRecordsAsync(query, cancellationToken),
            };

            var searchRecords = (await Task.WhenAll(searchTasks)).SelectMany(x => x ?? []).ToList();

            var prompt = BuildSystemPrompt(query, userId, searchRecords);
            var response = await configuration.KaitoService.GetInferenceAsync(prompt, cancellationToken: cancellationToken);
            var markdownResponse = MarkdownReferenceFormatter(response, searchRecords);

            var responseActivity = MessageFactory.Text(markdownResponse);
            responseActivity.TextFormat = TextFormatTypes.Markdown;

            await turnContext.SendActivityAsync(responseActivity, cancellationToken);
            await LogConversationAsync(userId, query, response, cancellationToken);
        }

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
    }

    private static string MarkdownReferenceFormatter(string input, IList<SearchRecord> searchRecords)
    {
        var footnotes = new StringBuilder();
        var footnoteReferencesIndexMap = new Dictionary<string, int>(); // A dictionary to map each URL to its final footnote index
        var footnoteIndex = 1; // Starting index for footnotes

        var formattedInput = ResponseExtractReferenceNumbersPattern.Replace(input, m =>
        {
            var footnoteReferenceNumber = int.Parse(m.Groups[1].Value);

            // With some Small Language Models (SMLs), hallucinations are sometimes inevitable.
            // If the reference number is out of bounds, because it's a hallucination, return an empty string.
            if (footnoteReferenceNumber > searchRecords.Count)
            {
                return string.Empty;
            }

            var footnoteSearchRecord = searchRecords[footnoteReferenceNumber - 1];
            var url = footnoteSearchRecord.Url;
            var title = footnoteSearchRecord.Title;

            // Check if the URL already has an assigned footnote index
            if (!footnoteReferencesIndexMap.TryGetValue(url, out var index))
            {
                index = footnoteIndex++;                                    // If not, assign the next available index
                footnoteReferencesIndexMap[url] = index;                    // Add the URL and its index to the map
                footnotes.AppendLine($"[{index}]: {url} \"{title}\"");      // Append the formatted footnote to the footnotes collection
            }

            // Return the markdown footnote reference (index) to replace the original reference number in the input
            return $"[{index}]";
        }).Trim();

        return $"{formattedInput}\n\n{footnotes}";
    }

    private static string BuildContextPromptSection(IEnumerable<SearchRecord> searchRecords)
    {
        var sb = new StringBuilder();
        var index = 0; // Start index at 1 for human-readable indexing

        foreach (var record in searchRecords)
        {
            sb.AppendLine($"[^{++index}^]: {record.Content?.Replace("\r\n", " ").Replace('\n', ' ')}\n---");
        }

        return sb.ToString();
    }

    private static string BuildChatHistoryPromptSection(IEnumerable<ChatHistoryRecord> chatHistoryRecords)
    {
        var sb = new StringBuilder();

        if (chatHistoryRecords.Any())
        {
            sb.AppendLine(string.Join("\n\n", chatHistoryRecords.Select(record => $@"{(record.Role == ChatHistoryRecord.ChatHistoryRecordRole.User ? @" - ME" : @" - YOU")}: {record.Content}")));
        }

        return sb.ToString();
    }

    private string BuildSystemPrompt(string query, string userId, IList<SearchRecord> searchRecords)
    {
        return searchRecords.Count > 0
            ? $$"""
                <|user|>Use the following information to answer my question. Each relevant piece of information starts with its unique reference identifier. Do not invent reference identifiers.

                {{BuildContextPromptSection(searchRecords)}}
                Follow these instructions to create your answer:

                  1. Never use your own knowledge. ONLY use the given information. DO NOT hallucinate or make up any information.
                  2. Select the most relevant information and follow it with its corresponding reference identifier.
                  3. DO NOT repeat information in your answer.
                  4. ONLY show your final response! DO NOT provide anything else, like explanations or details.

                For example, with the following contexts:

                 [^1^]: The sky is blue.
                 ---
                 [^2^]: The grass is green.
                 ---
                 [^3^]: The sun is yellow.
                 ---

                If I ask you "What color is the sky?" you should generate the following response: "The sky is blue[^1^]."
                If I ask you "What color is the sky and the sun?" you should generate the following response: "The sky is blue[^1^] and the sun is yellow[^3^]."

                My question is: {{query}}<|end|><|assistant|>
                """
            : $$"""
                <|user|>This is our chat history:

                {{BuildChatHistoryPromptSection(configuration.ChatHistoryService.Retrieve(userId))}}
                        
                NEVER use your own knowledge. ONLY use information from chat history. Use the chat history above to generate a brief and concise answer to my question. If you can't just say that you don't know. My question is: {{query}}<|end|><|assistant|>
                """;
    }

    private async Task LogConversationAsync(string userId, string query, string response, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;

        var userRecord = new ChatHistoryRecord()
        {
            Content = query,
            DateTimeUtc = now,
            Id = Guid.NewGuid(),
            Role = ChatHistoryRecord.ChatHistoryRecordRole.User,
            UserId = userId,
        };

        var assistantRecord = new ChatHistoryRecord()
        {
            Content = response,
            DateTimeUtc = now,
            Id = Guid.NewGuid(),
            Role = ChatHistoryRecord.ChatHistoryRecordRole.Assistant,
            UserId = userId,
        };

        await configuration.ChatHistoryService.InsertAsync(userRecord, cancellationToken);
        await configuration.ChatHistoryService.InsertAsync(assistantRecord, cancellationToken);
    }
}
