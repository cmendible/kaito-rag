using Microsoft.Bot.Builder;
using Microsoft.Bot.Connector.Authentication;

namespace KaitoRAG;

internal sealed record CloudAdapterWithErrorHandlerConfiguration(BotFrameworkAuthentication BotFrameworkAuthentication,
    ConversationState ConversationState,
    UserState UserState,
    IBotTelemetryClient BotTelemetryClient,
    IHttpContextAccessor HttpContextAccessor,
    ILogger<CloudAdapterWithErrorHandler> Logger,
    ITranscriptLogger TranscriptLogger);
