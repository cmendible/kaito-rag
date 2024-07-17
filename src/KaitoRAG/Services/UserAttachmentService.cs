#pragma warning disable SKEXP0001

using Azure.Storage.Blobs;
using Azure.Storage.Sas;

using KaitoRAG.Extensions;

using Microsoft.Bot.Schema;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Embeddings;

namespace KaitoRAG.Services;

internal sealed class UserAttachmentService : AttachmentServiceBase
{
    private const string UserDocumentsContainerName = @"user-documents";

    private readonly BlobContainerClient blobContainerClient;

    private readonly UserAttachmentServiceConfiguration configuration;

    public UserAttachmentService(UserAttachmentServiceConfiguration configuration, ILogger<UserAttachmentService> logger)
        : base(configuration, logger)
    {
        this.configuration = configuration;

        blobContainerClient = new BlobContainerClient(Options.BlobStorageConnectionString, UserDocumentsContainerName);
        blobContainerClient.CreateIfNotExists();
    }

    /// <inheritdoc/>>
    protected override async Task InnerProcessAttachmentAsync(IActivity activity, Attachment attachment)
    {
        var userId = activity.GetUserId();
        var conversationId = activity.Conversation.Id;

        await configuration.ConversationReferenceService.SendMessageAsync(conversationId, $@"Starting to process `{attachment.Name}`. I'll let you know once it's ready!");

        // Copy the stream to read it multiple times...
        using var memoryStream = new MemoryStream((int)attachment.Content.Length);
        await attachment.Content.CopyToAsync(memoryStream);

        try
        {
            var blobUri = await UploadAttachmentToBlobStorageAsync(userId, memoryStream, attachment);
            await UploadAttachmentToSearchAsync(conversationId, userId, memoryStream, attachment, blobUri);

            await configuration.ConversationReferenceService.SendMessageAsync(conversationId, $@"Document `{attachment.Name}` is ready. You can start asking question about it!");
        }
        catch (Exception ex)
        {
            var message = $@"Failed to upload attachment '{attachment.Name}' to blob storage.";
            Logger.LogError(ex, message);
            await configuration.ConversationReferenceService.SendMessageAsync(conversationId, message);
        }
    }

    private async Task<Uri> UploadAttachmentToBlobStorageAsync(string userId, Stream data, Attachment attachment)
    {
        try
        {
            var blobClient = blobContainerClient.GetBlobClient($@"{UserDocumentsContainerName}/{userId}/{attachment.Name}");

            data.Position = 0;
            await blobClient.UploadAsync(data, overwrite: true);

            var sasBuilder = new BlobSasBuilder
            {
                BlobContainerName = UserDocumentsContainerName,
                BlobName = blobClient.Name,
                ExpiresOn = DateTimeOffset.UtcNow.AddDays(1),
                Resource = @"b", // The value "b" (according to the documentation) should be used if the shared resource is a blob, granting access to the content and metadata of the blob.
            };

            sasBuilder.SetPermissions(BlobContainerSasPermissions.Read);

            return blobClient.GenerateSasUri(sasBuilder);
        }
        catch (Exception exception)
        {
            throw new InvalidOperationException($@"Error uploading attachment '{attachment.Name}' to blob storage!", exception);
        }
    }

    private async Task UploadAttachmentToSearchAsync(string conversationId, string userId, Stream data, Attachment attachment, Uri url, CancellationToken cancellationToken = default)
    {
        data.Position = 0;

        var documentChunks = configuration.DocumentContentExtractor.GetDocumentContent(data, attachment.Extension).ToList();
        var chunksCount = documentChunks.Count;
        var searchRecords = new List<SearchRecord>();

        var progressReportInterval = Options.ProgressReportChunksInterval;

        var now = DateTime.UtcNow;

        var kernel = configuration.KernelBuilder.Build();
        var embeddingGenerationService = kernel.GetRequiredService<ITextEmbeddingGenerationService>();

        for (var i = 0; i < chunksCount; i++)
        {
            if (progressReportInterval > 0 && i > 0 && i % progressReportInterval == 0)
            {
                await configuration.ConversationReferenceService.SendMessageAsync(conversationId, $@"Processing document '{attachment.Name}' at {i * 100 / chunksCount}%...", cancellationToken);
            }

            var chunk = string.Join(string.Empty, documentChunks[i]);

            searchRecords.Add(new SearchRecord()
            {
                CreatedAtUtc = now,
                Title = attachment.Name,
                Content = chunk,
                Embedding = await embeddingGenerationService.GenerateEmbeddingAsync(chunk, kernel, cancellationToken),
                UserId = userId,
                Id = SearchRecord.EncodeId($@"{userId}-{i}"),
                Url = url.AbsoluteUri,
            });
        }

        await configuration.UserSearchService.InsertRecordsBatchAsync(searchRecords, cancellationToken);

        await configuration.ConversationReferenceService.SendMessageAsync(conversationId, $@"Processing document '{attachment.Name}' at 100%...", cancellationToken);
    }
}

#pragma warning restore SKEXP0001
