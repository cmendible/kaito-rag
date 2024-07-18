using System.Text;

using KaitoRAG.Extensions;
using KaitoRAG.Services;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;

namespace KaitoRAG;

internal class RootDialog(RootDialogConfiguration configuration) : Dialog
{
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
        var searchRecords = searchRecordsCollection.Where(x => x != null).SelectMany(x => x!);

        var systemPrompt = $$"""
            Answer the question below.
            Take into consideration your chat history.
            Never use your own knowledge, only use the context below.
            If you don't know the answer, just say that `I don't know`.
            Keep the answer as concise as possible.
            ONLY use the CHAT HISTORY as additional context to understand what the user is asking you about, avoid using it to format your answer.
            Never forget to add the SOURCE URL from the context and only use `https://www.bing.com` if you don't know the answer.
            
            The format of your response must always be: 
                <ANSWER>[^<A NUMBER STARTING FROM 1>]

                [^<A NUMBER STARTING FROM 1>]: <SORUCE URL>
            
            ---
            {{BuildChatHistoryPromptSection(configuration.ChatHistoryService.Retrieve(userId))}}
            {{BuildContextPromptSection(searchRecords)}}
            QUESTION: {{query}}
            ANSWER:
            """;

        var response = await configuration.KaitoService.GetInferenceAsync(systemPrompt, cancellationToken: cancellationToken);

        await turnContext.SendActivityAsync(MessageFactory.Text(response), cancellationToken);

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
            Content = response,
            DateTimeUtc = now,
            Id = Guid.NewGuid(),
            Role = ChatHistoryRecord.ChatHistoryRecordRole.Assistant,
            UserId = userId,
        }, cancellationToken);

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
    }

    private static string BuildContextPromptSection(IEnumerable<SearchRecord> searchRecords)
    {
        if (!searchRecords.Any())
        {
            return "CONTEXT: N/A\n\n---\n";
        }

        var sb = new StringBuilder();
        var index = 1; // Start index at 1 for human-readable indexing

        foreach (var record in searchRecords)
        {
            sb.AppendLine($"CONTEXT {index}:\n{record.Content}\n")
              .AppendLine($"SOURCE URL {index}: {record.Url}\n");

            index++;
        }

        return sb.Append("---\n").ToString();
    }

    private static string? BuildChatHistoryPromptSection(IEnumerable<ChatHistoryRecord> chatHistoryRecords)
    {
        if (!chatHistoryRecords.Any())
        {
            return null;
        }

        var chatHistory = string.Join(Environment.NewLine,
                                      chatHistoryRecords.Select(record => $@"{(record.Role == ChatHistoryRecord.ChatHistoryRecordRole.User ? @"QUESTION" : @"ANSWER")}: {record.Content}" +
                                                                              (record.Role == ChatHistoryRecord.ChatHistoryRecordRole.Assistant ? "\n" : string.Empty)));

        return $"\nCHAT HISTORY:\n\n{chatHistory}\n---\n";
    }
}
