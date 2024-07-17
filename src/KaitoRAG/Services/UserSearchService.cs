using Azure.Search.Documents;

using KaitoRAG.Options;

using Microsoft.Extensions.Options;
using Microsoft.SemanticKernel;

namespace KaitoRAG.Services;

internal class UserSearchService : SearchServiceBase
{
    public UserSearchService(IKernelBuilder kernelBuilder, ILogger<UserSearchService> logger, IOptionsMonitor<AzureSearchOptions> azureAISearchOptions)
        : base(@"user-documents", kernelBuilder, logger, azureAISearchOptions)
    {
    }

    public new Task<IEnumerable<SearchRecord>?> SearchRecordsAsync(string query, string userId, CancellationToken cancellationToken)
    {
        return base.SearchRecordsAsync(query, $"{SearchRecord.UserIdField} eq '{userId}'", cancellationToken);
    }

    public async Task<bool> DeleteUserRecordsAsync(string userId, CancellationToken cancellationToken)
    {
        var searchOptions = new SearchOptions
        {
            Filter = $"{SearchRecord.UserIdField} eq '{userId}'",
            Select = { SearchRecord.IdField },
        };

        return await DeleteMemoryRecordsAsync(searchOptions, cancellationToken);
    }
}
