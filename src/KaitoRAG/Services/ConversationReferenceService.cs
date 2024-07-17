using System.Collections.Concurrent;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Schema;

namespace KaitoRAG.Services;

internal sealed class ConversationReferenceService
{
    private readonly IBotFrameworkHttpAdapter adapter;
    private readonly IConfiguration configuration;
    private readonly ConcurrentDictionary<string, ConversationReference> conversationReferences = new();

    public ConversationReferenceService(IBotFrameworkHttpAdapter adapter, IConfiguration configuration)
    {
        this.adapter = adapter;
        this.configuration = configuration;
    }

    public void AddConversationReference(IActivity activity)
    {
        var conversationReference = activity.GetConversationReference();

        conversationReferences.AddOrUpdate(activity.Conversation.Id, conversationReference, (key, newValue) => conversationReference);
    }

    public ConversationReference GetConversationReference(string conversationId)
    {
        return conversationReferences[conversationId];
    }

    public async Task SendMessageAsync(string conversationId, string message, CancellationToken cancellationToken = default)
    {
        var conversationReference = GetConversationReference(conversationId);

        await ((BotAdapter)adapter).ContinueConversationAsync(configuration[@"MicrosoftAppId"], conversationReference, BotCallback, cancellationToken);

        Task BotCallback(ITurnContext turnContext, CancellationToken cancellationToken)
        {
            return turnContext.SendActivityAsync(MessageFactory.Text(message), cancellationToken);
        }
    }
}
