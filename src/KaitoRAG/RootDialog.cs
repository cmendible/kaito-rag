using KaitoRAG.Extensions;

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
        var query = activity.Text;

        // End the dialog if the user is not asking anything.
        if (string.IsNullOrWhiteSpace(query))
        {
            return await dc.EndDialogAsync(cancellationToken: cancellationToken);
        }

        var searchRecordsCollection = await Task.WhenAll(configuration.UserSearchService.SearchRecordsAsync(query, activity.GetUserId(), cancellationToken), configuration.GlobalSearchService.SearchRecordsAsync(query, cancellationToken));

        var searchRecords = searchRecordsCollection.Where(x => x != null).SelectMany(x => x!).Select((x, i) => $"CONTEXT {i + 1}:\n{x.Content}\n\nSOURCE URL {i + 1}: {x.Url}");

        var context = string.Join("\n\n --- ", searchRecords);
        var chatHistory = string.Empty;

        var systemPrompt = $$"""
            Answer the question below.
            If you don't know the answer, just say that `I don't know`.
            Take into consideration your chat history with the user.
            Don't try to make up an answer, only use the context below.
            Keep the answer as concise as possible.
            ONLY use the CHAT HISTORY as additional context to understand what the user is asking you about, avoid using it to format your answer.
            
            The format of your response must always be: 
                <ANSWER>[^<A NUMBER STARTING FROM 1>]

                [^<A NUMBER STARTING FROM 1>]: <URL>


            {{context}}
            

            CHAT HISTORY:


            QUESTION: {{query}}
            

            ANSWER:
            """;

        var response = await configuration.KaitoService.GetInferenceAsync(systemPrompt, cancellationToken: cancellationToken);

        await turnContext.SendActivityAsync(MessageFactory.Text(response), cancellationToken);

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
    }
}
