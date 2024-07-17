using Microsoft.Bot.Builder.Integration.ApplicationInsights.Core;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Microsoft.Bot.Builder.TraceExtensions;

namespace KaitoRAG;

internal sealed class CloudAdapterWithErrorHandler : CloudAdapter
{
    private IBotTelemetryClient adapterBotTelemetryClient;

    public CloudAdapterWithErrorHandler(CloudAdapterWithErrorHandlerConfiguration configuration)
            : base(configuration.BotFrameworkAuthentication, configuration.Logger)
    {
        //Use telemetry client so that we can trace exceptions into Application Insights
        adapterBotTelemetryClient = configuration.BotTelemetryClient;

        var telemetryLoggerMiddleware = new TelemetryLoggerMiddleware(adapterBotTelemetryClient, logPersonalInformation: true);
        var telemetryInitializerMiddleware = new TelemetryInitializerMiddleware(configuration.HttpContextAccessor, telemetryLoggerMiddleware, logActivityTelemetry: true);
        var showTypingMiddleware = new ShowTypingMiddleware();
        var autoSaveStateMiddleware = new AutoSaveStateMiddleware(configuration.ConversationState, configuration.UserState);
        var transcriptLoggerMiddleware = new TranscriptLoggerMiddleware(configuration.TranscriptLogger);

        Use(telemetryInitializerMiddleware); // IMPORTANT - This middleware calls 'TelemetryLoggerMiddleware'. Adding 'TelemetryLoggerMiddleware' as middleware will produce repeated or duplicated log entries.
        Use(transcriptLoggerMiddleware);
        Use(showTypingMiddleware);
        Use(autoSaveStateMiddleware);

        OnTurnError = async (turnContext, exception) =>
        {
            // Track exceptions into Application Insights
            // Set up some properties for our exception tracing to give more information
            var properties = new Dictionary<string, string>
                { { @"Bot exception caught in", $@"{nameof(CloudAdapterWithErrorHandler)} - {nameof(OnTurnError)}" } };

            //Send the exception telemetry:
            adapterBotTelemetryClient.TrackException(exception, properties);

            // Log any leaked exception from the application.
            // NOTE: In production environment, you should consider logging this to
            // Azure Application Insights. Visit https://aka.ms/bottelemetry to see how
            // to add telemetry capture to your bot.
            configuration.Logger.LogError(exception, $@"[OnTurnError] unhandled error : {exception.Message}");

            // Send a message to the user
            var errorMessageText = @"The bot encountered an error or bug.";
            var errorMessage = MessageFactory.Text(errorMessageText, errorMessageText, InputHints.IgnoringInput);
            await turnContext.SendActivityAsync(errorMessage);

            errorMessageText = @"To continue to run this bot, please fix the bot source code.";
            errorMessage = MessageFactory.Text(errorMessageText, errorMessageText, InputHints.ExpectingInput);
            await turnContext.SendActivityAsync(errorMessage);

            if (configuration.ConversationState != null)
            {
                try
                {
                    // Delete the conversationState for the current conversation to prevent the
                    // bot from getting stuck in a error-loop caused by being in a bad state.
                    // ConversationState should be thought of as similar to "cookie-state" in a Web pages.
                    await configuration.ConversationState.DeleteAsync(turnContext);
                }
                catch (Exception e)
                {
                    configuration.Logger.LogError(e, $@"Exception caught on attempting to Delete ConversationState : {e.Message}");
                }
            }

            // Send a trace activity, which will be displayed in the Bot Framework Emulator
            await turnContext.TraceActivityAsync(@"OnTurnError Trace", exception.Message, @"https://www.botframework.com/schemas/error", @"TurnError");
        };
    }
}

