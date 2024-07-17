using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Builder.Teams;
using Microsoft.Bot.Connector;
using Microsoft.Bot.Schema;

namespace KaitoRAG;

internal sealed class Bot(BotConfiguration configuration) : TeamsActivityHandler
{
    /// <inheritdoc/>
    protected override async Task OnMessageActivityAsync(ITurnContext<IMessageActivity> turnContext, CancellationToken cancellationToken)
    {
        if (turnContext.Activity.ChannelId == Channels.Msteams)
        {
            turnContext.Activity.RemoveRecipientMention();
        }

        await base.OnMessageActivityAsync(turnContext, cancellationToken);

        await configuration.AttachmentService.ProcessAttachmentsAsync(turnContext, cancellationToken).ConfigureAwait(false);

        await configuration.Dialogs.Single(d => d is RootDialog)
                                   .RunAsync(turnContext, configuration.ConversationState.CreateProperty<DialogState>(nameof(DialogState)), cancellationToken);
    }
}
