#pragma warning disable SKEXP0001

using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Azure.Storage.Blobs.Specialized;
using Azure.Storage.Sas;

using KaitoRAG.Options;

using Microsoft.Extensions.Options;

using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Embeddings;

namespace KaitoRAG.Services;

public sealed class GlobalDocumentsService
{
    private const string GlobalDocumentsContainerName = @"global-documents";

    private BlobContainerClient blobContainerClient;
    private DocumentServiceOptions documentServiceOptions;

    private readonly ILogger logger;
    private readonly GlobalDocumentsServiceConfiguration configuration;

    public GlobalDocumentsService(GlobalDocumentsServiceConfiguration configuration, ILogger<GlobalDocumentsService> logger)
    {
        this.configuration = configuration;
        this.logger = logger;

        documentServiceOptions = configuration.DocumentServiceOptions.CurrentValue;

        BuildBlobContainerClient(documentServiceOptions);

        configuration.DocumentServiceOptions.OnChange(BuildBlobContainerClient);
    }

    public Task<bool> HasDocumentsAsync(CancellationToken cancellationToken)
    {
        return configuration.GlobalSearchService.HasSearchRecordsAsync(cancellationToken);
    }

    public async Task LoadGlobalDocumentsAsync(CancellationToken cancellationToken)
    {
        logger.LogInformation(@"Start loading global documents.");

        var now = DateTime.UtcNow;
        var accessExpirationDateUtc = now.AddYears(1);
        var searchRecords = new List<SearchRecord>();
        var kernel = configuration.KernelBuilder.Build();
        var embeddingGenerationService = kernel.GetRequiredService<ITextEmbeddingGenerationService>();

        logger.LogInformation(@"Getting blobs for global documents.");

        var blobs = blobContainerClient.GetBlobsAsync(cancellationToken: cancellationToken);

        logger.LogInformation(@"Retrieved blobs for global documents.");

        await foreach (var blob in blobs)
        {
            logger.LogInformation($@"Start processing blob for document '{blob.Name}'.");

            var fileName = blob.Name;
            var blobClient = blobContainerClient.GetBlobClient(fileName);
            var sasBuilder = new BlobSasBuilder
            {
                BlobContainerName = GlobalDocumentsContainerName,
                BlobName = fileName,
                ExpiresOn = accessExpirationDateUtc,
                Resource = @"b", // The value "b" (according to the documentation) should be used if the shared resource is a blob, granting access to the content and metadata of the blob.
            };
            sasBuilder.SetPermissions(BlobContainerSasPermissions.Read);

            logger.LogInformation($@"Creating chunks for document '{blob.Name}'.");

            var documentChunks = configuration.DocumentContentExtractor.GetDocumentContent(await blobClient.OpenReadAsync(new BlobOpenReadOptions(false), cancellationToken), Path.GetExtension(fileName)).ToList();

            logger.LogInformation($@"Creating Azure AI Search records for document '{blob.Name}'.");

            var documentChunksCount = documentChunks.Count;

            for (var i = 0; i < documentChunksCount; i++)
            {
                logger.LogInformation($@"Creating record {i + 1}/{documentChunksCount} for document '{blob.Name}'.");

                var chunk = string.Join(string.Empty, documentChunks[i]);

                searchRecords.Add(new SearchRecord()
                {
                    CreatedAtUtc = now,
                    Title = fileName,
                    Content = chunk,
                    Embedding = await embeddingGenerationService.GenerateEmbeddingAsync(chunk, kernel, cancellationToken),
                    Id = SearchRecord.EncodeId($@"{fileName}-{i}"),
                    Url = blobClient.GenerateSasUri(sasBuilder).AbsoluteUri,
                });

                logger.LogInformation($@"Created record {i + 1}/{documentChunksCount} for document '{blob.Name}'.");
            }
        }

        logger.LogInformation($@"Inserting records of global documents.");

        await configuration.GlobalSearchService.InsertRecordsBatchAsync(searchRecords, cancellationToken);

        logger.LogInformation(@"Finish loading global documents.");
    }

    public async Task UnloadGlobalDocumentsAsync(CancellationToken cancellationToken)
    {
        await configuration.GlobalSearchService.DeleteAllMemoryRecordsAsync(cancellationToken);
    }

    public async Task ReloadGlobalDocumentsAsync(CancellationToken cancellationToken)
    {
        await UnloadGlobalDocumentsAsync(cancellationToken);
        await LoadGlobalDocumentsAsync(cancellationToken);
    }

    private void BuildBlobContainerClient(DocumentServiceOptions documentServiceOptions)
    {
        blobContainerClient = new BlobContainerClient(documentServiceOptions.BlobStorageConnectionString, GlobalDocumentsContainerName);
        blobContainerClient.CreateIfNotExists();
    }
}

#pragma warning restore SKEXP0001
