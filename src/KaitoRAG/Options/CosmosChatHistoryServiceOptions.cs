using System.ComponentModel.DataAnnotations;

using KaitoRAG.DataAnnotations;

namespace KaitoRAG.Options;

public class CosmosChatHistoryServiceOptions
{
    /// <summary>
    /// Gets the Cosmos DB service endpoint to use.
    /// </summary>
    [Required]
    [Uri]
    public required Uri Endpoint { get; init; }

    /// <summary>
    /// Gets the key credential used to authenticate to Cosmos DB service.
    /// </summary>
    /// <remarks>
    /// If <see langword="null"/>,
    /// credentials to authenticate against the Azure AI Search resource, then a default `Azure.Core.TokenCredential`
    /// authentication flow for applications will be used instead.
    /// </remarks>
    public string Key { get; init; } = string.Empty;

    /// <summary>
    /// Gets the Cosmos DB database name (usually its unique identifier).
    /// </summary>
    [Required]
    public required string DatabaseId { get; init; }

    /// <summary>
    /// Gets the name of the container in the Cosmos DB database.
    /// </summary>
    [Required]
    public required string ContainerId { get; init; }

    /// <summary>
    /// Gets the maximum number of records to retrieve.
    /// </summary>
    /// <remarks>
    /// The range is between 1 and 10. Default is 3.
    /// </remarks>
    [Range(1, 10)]
    public int MaxRecords { get; init; } = 3;
}
