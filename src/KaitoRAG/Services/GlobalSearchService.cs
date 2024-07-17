using KaitoRAG.Options;

using Microsoft.Extensions.Options;
using Microsoft.SemanticKernel;

namespace KaitoRAG.Services;

public class GlobalSearchService : SearchServiceBase
{
    public GlobalSearchService(IKernelBuilder kernelBuilder, ILogger<GlobalSearchService> logger, IOptionsMonitor<AzureSearchOptions> azureAISearchOptions)
        : base(@"global-documents", kernelBuilder, logger, azureAISearchOptions)
    {
    }

    public Task<IEnumerable<SearchRecord>?> SearchRecordsAsync(string query, CancellationToken cancellationToken)
    {
        return SearchRecordsAsync(query, null, cancellationToken);
    }
}
