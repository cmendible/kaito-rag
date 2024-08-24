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
    private static readonly Regex ResponseExtractReferenceNumbersPattern = new(@"\[\$(\d+)\$\]", RegexOptions.Compiled, TimeSpan.FromSeconds(1));

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

            var response = await configuration.KaitoService.GetInferenceAsync(BuildSystemPrompt(query, userId, searchRecords), cancellationToken: cancellationToken);
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
        var sb = new StringBuilder("<<BEGIN CONTEXT>>\n\n");
        var index = 0; // Start index at 1 for human-readable indexing

        foreach (var record in searchRecords)
        {
            sb.AppendLine($"CONTEXT ID {++index}:\n\n{record.Content}\n");
        }

        return sb
                .AppendLine("<<END CONTEXT>>")
                .ToString()
                ;
    }

    private static string BuildChatHistoryPromptSection(IEnumerable<ChatHistoryRecord> chatHistoryRecords)
    {
        var sb = new StringBuilder("<<BEGIN CHAT HISTORY>>");

        if (chatHistoryRecords.Any())
        {
            sb.AppendLine("\n\n")
              .AppendLine(string.Join("\n", chatHistoryRecords.Select(record => $@"{(record.Role == ChatHistoryRecord.ChatHistoryRecordRole.User ? @" - USER" : @" - ASSISTANT")}: {record.Content}")))
              ;
        }

        return sb.AppendLine("<<END CHAT HISTORY>>").ToString();
    }

    private string BuildSystemPrompt(string query, string userId, IList<SearchRecord> searchRecords)
    {
        return searchRecords.Count > 0
            ? $$"""
                <|system|>
                {{BuildContextPromptSection(searchRecords)}}
                <<BEGIN INSTRUCTION>>
                Use the previous pieces of information in the context to answer the question below with the following instructions:
                  1. Select the most relevant information from the context
                  2. Generate a draft response with every selected piece of information, ensuring they are precise and concise, following these rules:
                    2a. Information from a context must always use this format: <information>[$<CONTEXT ID >$]
                    2b. Information from multiple contexts must always use this format: <information>[$CONTEXT ID$], [$CONTEXT ID $], [$CONTEXT ID $],...                    
                    2c. Remember that each context ID is always the number between dollar signs and then brackets, e.g. for a `CONTEXT ID 9` the format must be [$9$]
                    2d. Do not create context IDs that are not present in the context.
                    3d. Do not repeat the same context ID in the same piece of information.
                  3. Avoid repeating the same information in your response.
                  4. Generate your final response after adjusting it to increase accuracy and relevant
                  5. Now only show your final response! Do not provide any explanations or details
                <<END INSTRUCTION>>
                <|end|>
                <|user|>
                {{query}}
                <|end|>
                <|assistant|>
                """
            : $$"""
                <|system|>
                {{BuildChatHistoryPromptSection(configuration.ChatHistoryService.Retrieve(userId))}}
                <<BEGIN INSTRUCTION>>
                Use the chat history to answer the question below with the following instructions:
                    1. Select the most relevant information from the context
                    2. If the chat history does not contain the answer, do not try to make up one and just return `I'm sorry, I don't know about that!` and stop processing.
                    3. Generate a draft response ensuring it is precise and concise
                    3. Avoid repeating the same information in your response.
                    5. Generate your final response after adjusting it to increase accuracy and relevant
                    6. Now only show your final response! Do not provide any explanations or details
                <<END INSTRUCTION>>
                <|end|>
                <|user|>
                {{query}}
                <|end|>
                <|assistant|>
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
