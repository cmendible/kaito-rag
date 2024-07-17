#pragma warning disable SKEXP0001

using System.Diagnostics.CodeAnalysis;
using System.Text;
using System.Text.Json;

using Azure;
using Azure.Identity;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using Azure.Search.Documents.Models;

using KaitoRAG.Options;

using Microsoft.Extensions.Options;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Embeddings;

namespace KaitoRAG.Services;

public abstract class SearchServiceBase
{
    ////private static readonly JsonSerializerOptions DocumentInsightsJsonSerializerOptions = new()
    ////{
    ////    PropertyNameCaseInsensitive = true,
    ////};

    private readonly ILogger<SearchServiceBase> logger;

    protected SearchServiceBase(string indexName, IKernelBuilder kernelBuilder, ILogger<SearchServiceBase> logger, IOptionsMonitor<AzureSearchOptions> azureAISearchOptions)
    {
        this.logger = logger;

        IndexName = indexName.ToLowerInvariant();

        KernelBuilder = kernelBuilder;

        BuildSearchClients(azureAISearchOptions.CurrentValue);

        azureAISearchOptions.OnChange(BuildSearchClients);
    }

    protected string IndexName { get; private set; }

    protected IKernelBuilder KernelBuilder { get; private set; }

    protected SearchClient SearchClient { get; private set; }

    protected SearchIndexClient SearchIndexClient { get; private set; }

    public async Task DeleteAllMemoryRecordsAsync(CancellationToken cancellationToken)
    {
        var searchResult = await SearchClient.SearchAsync<SearchRecord>(@"*", cancellationToken: cancellationToken);

        var keysToRemove = (await searchResult.Value
                .GetResultsAsync() // This takes care of pagination if necessary and retrieves all results
                .ToListAsync(cancellationToken))
                .Select(document => document.Document.Id)
                .Distinct()
                .Where(id => !string.IsNullOrWhiteSpace(id))
                .ToList()
                ;

        if (keysToRemove.Count > 0)
        {
            await SearchClient.DeleteDocumentsAsync(SearchRecord.IdField, keysToRemove, new IndexDocumentsOptions { ThrowOnAnyError = false }, cancellationToken);
        }

        await WaitForRecordsToBeAvailableAsync(0, cancellationToken);
    }

    protected async Task<bool> DeleteMemoryRecordsAsync(SearchOptions searchOptions, CancellationToken cancellationToken)
    {
        try
        {
            var searchResult = await SearchClient.SearchAsync<SearchRecord>(searchOptions, cancellationToken);

            var keysToRemove = (await searchResult.Value
                .GetResultsAsync() // This takes care of pagination if necessary and retrieves all results
                .ToListAsync(cancellationToken))
                .Select(document => document.Document.Id)
                .Distinct()
                .Where(id => !string.IsNullOrWhiteSpace(id))
                .ToList()
                ;

            // If there are no documents to delete, exit.
            if (keysToRemove.Count == 0)
            {
                return false;
            }

            // Delete the found documents.
            await SearchClient.DeleteDocumentsAsync(SearchRecord.IdField, keysToRemove, new IndexDocumentsOptions { ThrowOnAnyError = true }, cancellationToken);

            return true;
        }
        catch (RequestFailedException e) when (e.Status == 404)
        {
            return false;
        }
    }

    /// <summary>
    /// Inserts a batch of document memory records asynchronously.
    /// </summary>
    /// <param name="records">The list of document memory records to insert.</param>
    /// <param name="cancellationToken">A cancellation token that can be used to cancel the operation.</param>
    /// <returns>A task that represents the asynchronous operation.</returns>
    public async Task InsertRecordsBatchAsync(IList<SearchRecord> records, CancellationToken cancellationToken)
    {
        if (records.Count < 1)
        {
            return;
        }

        await CreateIfNotExistsAsync(cancellationToken);

        // When adding documents into a specified index, batching (up to 1000 documents per batch, or about 16 MB per batch) is recommended and will significantly improve indexing performance...
        // Reference: https://learn.microsoft.com/en-us/rest/api/searchservice/addupdate-or-delete-documents
        const int maxBatchSize = 1000;
        const int maxBatchSizeMb = 14; // Azure AI Search has a limit of 16 MB per batch, leaving a small margin of error because the SearchClient document serialization might result in slightly larger sizes...

        var batches = GetBatches(records, maxBatchSize, maxBatchSizeMb);
        var batchTasks = batches.Select(batch => SearchClient.IndexDocumentsAsync(batch, new IndexDocumentsOptions
        {
            ThrowOnAnyError = false,
        }, cancellationToken)).ToList();

        var results = await Task.WhenAll(batchTasks);

        if (results.ToList().TrueForAll(r => r.Value.Results.Count == 0))
        {
            throw new InvalidOperationException(@"Memory write returned `null` or an empty set!");
        }

        await WaitForRecordsToBeAvailableAsync(records.Count, cancellationToken);
    }

    protected async Task CreateIfNotExistsAsync(CancellationToken cancellationToken)
    {
        try
        {
            await SearchIndexClient.GetIndexAsync(IndexName, cancellationToken); // The current size of vectors in OpenAI is 1536.
        }
        catch (RequestFailedException e) when (e.Status == 404)
        {
            await CreateIndexAsync(1536, cancellationToken).ConfigureAwait(false);
        }
    }

    protected Task<Response<SearchIndex>> CreateIndexAsync(int embeddingSize, CancellationToken cancellationToken)
    {
        if (embeddingSize < 1)
        {
            throw new ArgumentOutOfRangeException(nameof(embeddingSize), @"Invalid embedding size: the value must be greater than zero.");
        }

        const string profileName = @"default";
        const string algorithmName = @"exhaustiveKnnProfile";
        const string contentAnaluzerName = @"en.microsoft";

        var newIndex = new SearchIndex(IndexName)
        {
            Fields =
            [
                new SimpleField(SearchRecord.IdField, SearchFieldDataType.String) { IsKey = true },
                new SearchableField(SearchRecord.ContentField) { IsFilterable = true, AnalyzerName = contentAnaluzerName },
                new VectorSearchField(SearchRecord.EmbeddingField, embeddingSize, profileName),
                new SimpleField(SearchRecord.CreatedAtUtcField, SearchFieldDataType.DateTimeOffset) { IsFilterable = true },
                new SimpleField(SearchRecord.UserIdField, SearchFieldDataType.String) { IsFilterable = true },
                new SimpleField(SearchRecord.UrlField, SearchFieldDataType.String) { IsFilterable = true },
                new SearchableField(SearchRecord.TitleField) { IsFilterable = true },
            ],
            SemanticSearch = new()
            {
                Configurations =
                {
                    new SemanticConfiguration(Constants.SemanticRanker.ConfigurationName, new()
                    {
                        TitleField = new SemanticField(SearchRecord.TitleField),
                        ContentFields =
                        {
                            new SemanticField(SearchRecord.ContentField),
                        },
                    }),
                },
            },
            VectorSearch = new VectorSearch
            {
                Algorithms =
                {
                    new ExhaustiveKnnAlgorithmConfiguration(algorithmName)
                    {
                        Parameters = new ExhaustiveKnnParameters
                        {
                            Metric = VectorSearchAlgorithmMetric.Cosine,
                        },
                    },
                },
                Profiles =
                {
                    new VectorSearchProfile(profileName, algorithmName),
                },
            },
        };

        return SearchIndexClient.CreateIndexAsync(newIndex, cancellationToken);
    }

    public async Task<bool> HasSearchRecordsAsync(CancellationToken cancellationToken)
    {
        try
        {
            return (await SearchClient.GetDocumentCountAsync(cancellationToken)).Value > 0;
        }
        catch
        {
            // If the index does not exists, an exception will be thrown. Interpret this as no records.
            return false;
        }
    }

    protected async Task<IEnumerable<SearchRecord>?> SearchRecordsAsync(string query, string? filter, CancellationToken cancellationToken)
    {
        if (!await HasSearchRecordsAsync(cancellationToken))
        {
            return null;
        }

        var kernel = KernelBuilder.Build();
        var embeddingGenerationService = kernel.GetRequiredService<ITextEmbeddingGenerationService>();

        SearchResults<SearchRecord> results = await SearchClient.SearchAsync<SearchRecord>(query, new SearchOptions()
        {
            Filter = filter,
            QueryType = SearchQueryType.Semantic,
            SemanticSearch = new SemanticSearchOptions()
            {
                SemanticConfigurationName = Constants.SemanticRanker.ConfigurationName,
                QueryCaption = new(QueryCaptionType.Extractive),
                QueryAnswer = new(QueryAnswerType.Extractive)
                {
                    Count = 3,
                    Threshold = 0,
                },
            },
            VectorSearch = new()
            {
                Queries =
                {
                    new VectorizedQuery(await embeddingGenerationService.GenerateEmbeddingAsync(query, kernel, cancellationToken))
                    {
                        KNearestNeighborsCount = 5,
                        Fields =
                        {
                            SearchRecord.EmbeddingField,
                        },
                    },
                },
            },
        }, cancellationToken);

        return await results.GetResultsAsync().Select(item => item.Document).ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Generates batches of <see cref="IndexDocumentsBatch"/>> from a collection of records, ensuring each batch
    /// meets size constraints in terms of both item count and serialized byte size.
    /// </summary>
    /// <typeparam name="T">The type of records in the collection.</typeparam>
    /// <param name="records">The collection of records to batch process.</param>
    /// <param name="maxBatchSize">The maximum number of records allowed in each batch.</param>
    /// <param name="maxBatchMb">The maximum size limit in megabytes for each batch.</param>
    /// <param name="batchSizeReductionStep">The step size to reduce the batch size when it exceeds the byte limit.</param>
    /// <returns>An enumerable collection of document batches.</returns>
    private static IEnumerable<IndexDocumentsBatch<T>> GetBatches<T>(ICollection<T> records, int maxBatchSize, int maxBatchMb, int batchSizeReductionStep = 50)
    {
        // This method might appear better or more optimal at first glance, but it's important to consider that serialization operations are costly.
        // Therefore, we need to be cautious when making modifications to it.

        long maxBatchBytesInBytes = maxBatchMb * 1024 * 1024;

        var i = 0;
        while (i < records.Count)
        {
            var batch = records.Skip(i).Take(maxBatchSize).ToList();
            var documentBatch = IndexDocumentsBatch.Upload(batch);

            var batchSize = Encoding.UTF8.GetByteCount(JsonSerializer.Serialize(documentBatch));

            if (batchSize <= maxBatchBytesInBytes)
            {
                yield return documentBatch;
                i += batch.Count; // Move index forward by the size of the batch
            }
            else
            {
                // Reduce batch size until it fits within the byte limit
                for (var j = maxBatchSize - batchSizeReductionStep; j > 0; j -= batchSizeReductionStep)
                {
                    var subBatch = batch.Take(j).ToList();
                    var subDocumentBatch = IndexDocumentsBatch.Upload(subBatch);

                    var subBatchSize = Encoding.UTF8.GetByteCount(JsonSerializer.Serialize(subDocumentBatch));

                    if (subBatchSize <= maxBatchBytesInBytes)
                    {
                        maxBatchSize = j; // Adjust maxBatchSize assuming similar batch sizes

                        yield return subDocumentBatch;

                        i += subBatch.Count; // Move index forward by the size of the sub-batch

                        break;
                    }
                }
            }
        }
    }

    [MemberNotNull(nameof(SearchClient), nameof(SearchIndexClient))]
    private void BuildSearchClients(AzureSearchOptions azureSearchOptions)
    {
        SearchIndexClient = string.IsNullOrWhiteSpace(azureSearchOptions.Key)
                               ? new SearchIndexClient(azureSearchOptions.Endpoint, new DefaultAzureCredential())
                               : new SearchIndexClient(azureSearchOptions.Endpoint, new AzureKeyCredential(azureSearchOptions.Key));

        SearchClient = SearchIndexClient.GetSearchClient(IndexName);
    }

    private async Task WaitForRecordsToBeAvailableAsync(int expectedCount, CancellationToken cancellationToken)
    {
        var attempt = 0;
        const int maxAttempts = 10;
        const int delayBetweenAttemptsInSeconds = 1;

        while (attempt < maxAttempts)
        {
            try
            {
                var currentCount = (await SearchClient.GetDocumentCountAsync(cancellationToken)).Value;

                // When deleting all records, the expected count should be zero (0), therefore this method must validate and wait for the current count to be zero.
                // When inserting records, the expected count should be greater than zero (0), therefore this method must validate and wait for the current count to be greater or equal to the expected count.
                var condition = expectedCount == 0
                       ? currentCount == expectedCount
                       : currentCount >= expectedCount;

                if (condition)
                {
                    logger.LogInformation($@"Records are ready in Azure AI Search. Attempts: {attempt}");
                    return;
                }
            }
            catch (Exception exception)
            {
                logger.LogError($@"Error waiting for records in Azure AI Search to be available. Error was: {exception.Message}.", exception);
            }

            await Task.Delay(TimeSpan.FromSeconds(delayBetweenAttemptsInSeconds), cancellationToken);
            attempt++;
        }

        logger.LogWarning($@"Attempted {maxAttempts} waiting for records to be ready in Azure AI Search. It is not clear if they are already available.");
    }
}

#pragma warning restore SKEXP0001
