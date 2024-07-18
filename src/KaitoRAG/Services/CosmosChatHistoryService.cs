using Azure;
using Azure.Identity;

using KaitoRAG.Options;

using Microsoft.Azure.Cosmos;

using Microsoft.Extensions.Options;

namespace KaitoRAG.Services;

public class CosmosChatHistoryService
{
    private CosmosClient client;
    private Container container;

    private CosmosChatHistoryServiceOptions options;

    public CosmosChatHistoryService(IOptionsMonitor<CosmosChatHistoryServiceOptions> optionsMonitor)
    {
        BuildCosmosConnection(optionsMonitor.CurrentValue);

        optionsMonitor.OnChange(BuildCosmosConnection);
    }

    public async Task InsertAsync(ChatHistoryRecord record, CancellationToken cancellationToken)
    {
        await container.UpsertItemAsync(record, cancellationToken: cancellationToken);
    }

    public IEnumerable<ChatHistoryRecord> Retrieve(string userId)
    {
        IEnumerable<ChatHistoryRecord> chatHistory = [.. container.GetItemLinqQueryable<ChatHistoryRecord>(true)
                                                           .Where(i => i.UserId == userId)
                                                           .OrderByDescending(i => i.DateTimeUtc)
                                                           .Take(options.MaxRecords * 2)]; // `MaxRecords` is duplicated to ensure that the `Take` method will always get the message from the User and the Assistant.

        var a = chatHistory.ToList();

        a.Reverse();

        return a;
    }

    private void BuildCosmosConnection(CosmosChatHistoryServiceOptions options)
    {
        var oldClient = client;

        client = string.IsNullOrWhiteSpace(options.Key)
            ? new CosmosClient(options.Endpoint.AbsoluteUri, new DefaultAzureCredential())
            : new CosmosClient(options.Endpoint.AbsoluteUri, new AzureKeyCredential(options.Key));

        container = client.GetDatabase(options.DatabaseId).GetContainer(options.ContainerId);

        this.options = options;

        oldClient?.Dispose();
    }
}
