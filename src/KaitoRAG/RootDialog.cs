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
        var query = activity.Text;

        // End the dialog if the user is not asking anything.
        if (string.IsNullOrWhiteSpace(query))
        {
            return await dc.EndDialogAsync(cancellationToken: cancellationToken);
        }

        var searchRecordsCollection = await Task.WhenAll(configuration.UserSearchService.SearchRecordsAsync(query, userId, cancellationToken), configuration.GlobalSearchService.SearchRecordsAsync(query, cancellationToken));
        var searchRecords = searchRecordsCollection.Where(x => x != null).SelectMany(x => x!).ToList(); ;

        if (searchRecords.Count == 0)
        {
            await turnContext.SendActivityAsync(MessageFactory.Text(@"I'm sorry, I don't know about that!"), cancellationToken);
        }
        else
        {
            var systemPrompt = $$"""
            {{BuildContextPromptSection(searchRecords)}}
            
            Use the previous pieces of information to answer the question below with the following instructions:
              1. Select the most relevant information from the context.
              2. Generate a draft response concatenating every selected piece of information, ensuring it is precise and concise. 
                2a. If the piece of information reference one context, use this format: `<Your answer>[$<ID Context>$]`
                2b. If the piece of information reference multiple contexts, use this format: `<Your answer>[$<ID Context>$],[$<ID other Context>$],[$<ID another Context>$],...`
              3. Remove duplicate content from the draft response
              4. Generate your final response after adjusting it to increase accuracy and relevant.
              5. Now only show your final response! Do not provide any explanations or details
            
            
            QUESTION: {{query}}
            ANSWER:
            """;

            var response = await configuration.KaitoService.GetInferenceAsync(systemPrompt, cancellationToken: cancellationToken);

            var cleanupResponse = CleanUpString(response);
            var references = ExtractReferenceNumbers(cleanupResponse);

            await turnContext.SendActivityAsync(MessageFactory.Text(cleanupResponse), cancellationToken);

            var now = DateTime.UtcNow;

            await configuration.ChatHistoryService.InsertAsync(new ChatHistoryRecord()
            {
                Content = query,
                DateTimeUtc = now,
                Id = Guid.NewGuid(),
                Role = ChatHistoryRecord.ChatHistoryRecordRole.User,
                UserId = userId,
            }, cancellationToken);

            await configuration.ChatHistoryService.InsertAsync(new ChatHistoryRecord()
            {
                Content = cleanupResponse,
                DateTimeUtc = now,
                Id = Guid.NewGuid(),
                Role = ChatHistoryRecord.ChatHistoryRecordRole.Assistant,
                UserId = userId,
            }, cancellationToken);

        }

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
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

    private static string? BuildChatHistoryPromptSection(IEnumerable<ChatHistoryRecord> chatHistoryRecords)
    {
        if (!chatHistoryRecords.Any())
        {
            return null;
        }

        var chatHistory = string.Join("\n", chatHistoryRecords.Select(record => $@"{(record.Role == ChatHistoryRecord.ChatHistoryRecordRole.User ? @" - USER" : @" - ASSISTANT")}: {record.Content}"));

        return $"User conversation history:\n\n{chatHistory}\n---\n";
    }

    private static string CleanUpString(string input)
    {
        return (ResponseCleanRegexPattern.IsMatch(input) ? ResponseCleanRegexPattern.Replace(input, string.Empty) : input).Trim();
    }

    private static HashSet<int> ExtractReferenceNumbers(string input)
    {
        var referenceNumbers = new HashSet<int>();

        var matches = ResponseExtractReferenceNumbersPattern.Matches(input);

        foreach (Match match in matches)
        {
            if (match.Success)
            {
                referenceNumbers.Add(int.Parse(match.Groups[1].Value));
            }
        }

        return referenceNumbers;
    }
}
