using KaitoRAG.Services;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.Dialogs;

namespace KaitoRAG;

/// <summary>
/// Configuration of a bot's activity handler.
/// </summary>
internal record BotConfiguration(
    ConversationState ConversationState,
    UserState UserState,
    UserAttachmentService AttachmentService,
    IEnumerable<Dialog> Dialogs);
