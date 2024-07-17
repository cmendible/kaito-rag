using KaitoRAG.Extensions;

using Microsoft.Bot.Builder.Dialogs;

namespace KaitoRAG;

internal class RootDialog(RootDialogConfiguration configuration) : Dialog
{
    /// <inheritdoc/>>
    public override async Task<DialogTurnResult> BeginDialogAsync(DialogContext dc, object options = null, CancellationToken cancellationToken = default)
    {
        var turnContext = dc.Context;
        var activity = turnContext.Activity;
        var conversationId = activity.Conversation.Id;
        var userId = activity.GetUserId();
        var query = activity.Text;

        // If the user is not asking anything, then end the dialog.
        if (string.IsNullOrWhiteSpace(query))
        {
            return await dc.EndDialogAsync(cancellationToken: cancellationToken);
        }

        var searchRecords = await Task.WhenAll(configuration.UserSearchService.SearchRecordsAsync(query, userId, cancellationToken), configuration.GlobalSearchService.SearchRecordsAsync(query, cancellationToken));

        
        

        return await dc.EndDialogAsync(cancellationToken: cancellationToken);
    }
}
