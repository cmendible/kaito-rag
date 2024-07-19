using System.Text;
using System.Text.RegularExpressions;

using KaitoRAG.Extensions;
using KaitoRAG.Services;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;

namespace KaitoRAG;

internal class RootDialog(RootDialogConfiguration configuration) : Dialog
{
    // Handles the removal of a footnote reference only when it's not followed by its corresponding footnote.
    private static readonly Regex ResponseCleanRegexPattern = new(@"\[\^([^\]]+)\](?=\s*$)(?!.*?\[\^\1\]:)", RegexOptions.Compiled | RegexOptions.Singleline, TimeSpan.FromSeconds(3));
    private static readonly Regex ResponseExtractReferenceNumbersPattern = new(@"\[\$(\d+)\$\]", RegexOptions.Compiled, TimeSpan.FromSeconds(3));

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

            var searchRecordsCollection = await Task.WhenAll(searchTasks);
            var searchRecords = searchRecordsCollection.SelectMany(x => x ?? []).ToList();

            var chatHistoryRecords = configuration.ChatHistoryService.Retrieve(userId);

            var systemPrompt = GenerateSystemPrompt(searchRecords, chatHistoryRecords, query);

            var response = await configuration.KaitoService.GetInferenceAsync(systemPrompt, cancellationToken: cancellationToken);
            var cleanupResponse = CleanUpString(response);
            var markdownResponse = MarkdownReferenceFormatter(cleanupResponse, searchRecords);

            await turnContext.SendActivityAsync(MessageFactory.Text(markdownResponse), cancellationToken);
            await LogConversationAsync(userId, query, cleanupResponse, cancellationToken);
        }

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
    }

    private static Dictionary<string, (string Title, HashSet<int> Ids)> ExtractReferenceNumbers(string input, IList<SearchRecord> searchRecords)
    {
        var refs = new Dictionary<string, (string Title, HashSet<int> Ids)>();

        var matches = ResponseExtractReferenceNumbersPattern.Matches(input);

        foreach (var groups in matches.Select(match => match.Groups))
        {
            var val = int.Parse(groups[1].Value);
            var url = searchRecords[val - 1].Url;
            var title = searchRecords[val - 1].Title;

            if (refs.TryGetValue(url, out var value))
            {
                value.Ids.Add(val);
            }
            else
            {
                var h = new HashSet<int>
                {
                    val,
                };

                refs.Add(url, new(title, h));
            }
        }

        return refs;
    }

    private static string MarkdownReferenceFormatter(string input, IList<SearchRecord> searchRecords)
    {
        var footnotes = new HashSet<string>();

        var refs = ExtractReferenceNumbers(input, searchRecords);

        var formattedInput = ResponseExtractReferenceNumbersPattern.Replace(input, m =>
        {
            var x = m.Groups[1].Value;
            var y = int.Parse(x);

            var item = refs.Single(item => item.Value.Ids.Contains(y));

            var p = refs.Keys.ToList().IndexOf(item.Key);

            var z = $"[^{p + 1}]";

            ////footnotes.Add($"{z}: [{item.Value.Title}]({item.Key})");
            footnotes.Add($"{z}: {item.Key}");

            return z;
        });

        return $"{formattedInput}\n\n{string.Join("\n", footnotes)}";
    }

    private static string GenerateSystemPrompt(IList<SearchRecord> searchRecords, IList<ChatHistoryRecord> chatHistoryRecords, string query)
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
                {{BuildChatHistoryPromptSection(chatHistoryRecords)}}
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

    private static string CleanUpString(string input)
    {
        return (ResponseCleanRegexPattern.IsMatch(input) ? ResponseCleanRegexPattern.Replace(input, string.Empty) : input).Trim();
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
