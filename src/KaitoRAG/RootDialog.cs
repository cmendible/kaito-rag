using System.Text;
using System.Text.RegularExpressions;

using KaitoRAG.Extensions;
using KaitoRAG.Services;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;

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

            await turnContext.SendActivityAsync(MessageFactory.Text(markdownResponse), cancellationToken);
            await LogConversationAsync(userId, query, response, cancellationToken);
        }

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
    }

    private static string MarkdownReferenceFormatter(string input, IList<SearchRecord> searchRecords)
    {
        var footnotes = new List<string>();
        ////var refs = ExtractReferenceNumbers(input, searchRecords);
        var refIndexMap = new Dictionary<string, int>();
        var footnoteIndex = 1;

        var formattedInput = ResponseExtractReferenceNumbersPattern.Replace(input, m =>
        {
            var val = int.Parse(m.Groups[1].Value);
            var searchRecord = searchRecords[val - 1];
            var url = searchRecord.Url;

            if (!refIndexMap.TryGetValue(url, out var index))
            {
                index = footnoteIndex++;
                refIndexMap[url] = index;
                footnotes.Add($"[^{index}]: {url}");
            }

            return $"[^{index}]";
        });

        return $"{formattedInput}\n\n{string.Join("\n", footnotes)}";
    }

    private static string BuildContextPromptSection(IEnumerable<SearchRecord> searchRecords)
    {
        var sb = new StringBuilder("<<BEGIN CONTEXT>>\n\n");
        var index = 0; // Start index at 1 for human-readable indexing

        foreach (var record in searchRecords)
        {
            sb.AppendLine($"CONTEXT ID {++index}:\n\n{record.Content}\n");
        }

        return sb.AppendLine("<<END CONTEXT>>").ToString();
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
                {{BuildContextPromptSection(searchRecords)}}
                Use the previous pieces of information to answer the question below with the following instructions:
                  1. Select the most relevant information from the context
                  2. Generate a draft response with every selected piece of information, ensuring they are precise and concise, following these rules:
                    2a. Information from a context must always use this format: <information>[$<ID of a Context>$]
                    2b. Information from multiple contexts must always use this format: <information>[$ID of a Context$], [$ID of other Context$], [$ID of another Context$],...
                  3. Remove duplicate content from the draft response, including any duplicate context references
                  4. Generate your final response after adjusting it to increase accuracy and relevant
                  5. Now only show your final response! Do not provide any explanations or details
        
                QUESTION: {{query}}
                ANSWER:
                """
            : $$"""
                {{BuildChatHistoryPromptSection(configuration.ChatHistoryService.Retrieve(userId))}}
                Use the chat history to answer the question below with the following instructions:
                    1. Select the most relevant information from the context
                    2. If the chat history does not contain the answer, do not try to make up one and just return `I'm sorry, I don't know about that!` ending the conversation without any further explanation
                    3. Generate a draft response ensuring it is precise and concise
                    4. Remove duplicate content from the draft response
                    5. Generate your final response after adjusting it to increase accuracy and relevant
                    6. Now only show your final response! Do not provide any explanations or details
        
                QUESTION: {{query}}
                ANSWER:
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
