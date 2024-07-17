using System.Text.Json;
using System.Threading;

using KaitoRAG.Options;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Connector;
using Microsoft.Bot.Schema;
using Microsoft.Bot.Schema.Teams;

using Microsoft.Extensions.Options;

namespace KaitoRAG.Services;

internal abstract class AttachmentServiceBase
{
    private static readonly JsonSerializerOptions JsonSerializerOptions = new()
    {
        AllowTrailingCommas = true,
        PropertyNameCaseInsensitive = true,
    };

    private readonly string currentlySupportedFileFormats;
    private readonly HttpClient httpClient;
    private readonly AttachmentServiceConfigurationBase configuration;

    protected AttachmentServiceBase(AttachmentServiceConfigurationBase configuration, ILogger logger)
    {
        this.configuration = configuration;

        Logger = logger;
        Options = configuration.AttachmentServiceOptions.CurrentValue;

        httpClient = configuration.HttpClientFactory.CreateClient();

        currentlySupportedFileFormats = string.Join(@", ", configuration.DocumentContentExtractor.GetSupportedFileExtension());

        configuration.AttachmentServiceOptions.OnChange(value => { Options = value; });
    }

    protected ILogger Logger { get; private set; }

    protected DocumentServiceOptions Options { get; private set; }

    public async Task ProcessAttachmentsAsync(ITurnContext turnContext, CancellationToken cancellationToken)
    {
        var attachments = await GetAttachmentsAsync(turnContext, cancellationToken);

        if (attachments == null || attachments.Count == 0)
        {
            Logger.LogInformation(@"No attachments to process!");
            return;
        }

        var activity = turnContext.Activity;

        configuration.ConversationReferenceService.AddConversationReference(activity);

        await turnContext.SendActivityAsync(MessageFactory.Text(@"Starting processing your documents..."), cancellationToken);

        _ = Task.Run(async () =>
        {
            foreach (var attachment in attachments)
            {
                var downloadedAttachment = await DownloadAttachmentContentAsync(attachment);
                await InnerProcessAttachmentAsync(activity, downloadedAttachment);
            }
        }, CancellationToken.None);
    }

    protected abstract Task InnerProcessAttachmentAsync(IActivity activity, Attachment attachment);

    private async Task<List<Attachment>?> GetAttachmentsAsync(ITurnContext turnContext, CancellationToken cancellationToken)
    {
        var activity = turnContext.Activity;

        if (activity.Attachments == null || activity.Attachments.Count == 0)
        {
            return null;
        }

        var attachments = activity.ChannelId == Channels.Msteams
                            ? activity.Attachments
                                .Where(a => a.ContentType == FileDownloadInfo.ContentType)
                                .Select(teamsAttachment => new Attachment(JsonSerializer.Deserialize<FileDownloadInfo>(teamsAttachment.Content.ToString()!, JsonSerializerOptions)!.DownloadUrl, teamsAttachment.Name, Path.GetExtension(teamsAttachment.Name), Stream.Null))
                            : activity.Attachments.Select(attachment => new Attachment(attachment.ContentUrl, attachment.Name, Path.GetExtension(attachment.Name), Stream.Null));

        var validAttachments = new List<Attachment>();
        var unsupportedAttachments = new List<string>();

        foreach (var attachment in attachments)
        {
            if (!configuration.DocumentContentExtractor.IsSupportedFileExtension(attachment.Extension))
            {
                unsupportedAttachments.Add(attachment.Name);
                continue;
            }

            validAttachments.Add(attachment);
        }

        if (unsupportedAttachments.Count != 0)
        {
            var unsupportedMessage = $"@File format of the '{string.Join(", ", unsupportedAttachments)}' file(s) is not supported and will be ignored. Currently supported file formats are: {currentlySupportedFileFormats}";
            await turnContext.SendActivityAsync(MessageFactory.Text(unsupportedMessage), cancellationToken);
        }

        return validAttachments;
    }

    private async Task<Attachment> DownloadAttachmentContentAsync(Attachment attachment)
    {
        var response = await httpClient.GetAsync(attachment.DownloadUrl);

        return attachment with { Content = await response.Content.ReadAsStreamAsync() };
    }

    protected sealed record Attachment(string DownloadUrl, string Name, string Extension, Stream Content);
}
