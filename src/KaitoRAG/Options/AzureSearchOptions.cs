using System.ComponentModel.DataAnnotations;

using KaitoRAG.DataAnnotations;

namespace KaitoRAG.Options;

public class AzureSearchOptions
{
    /// <summary>
    /// Gets the Azure AI Search endpoint, , e.g. "https://contoso.search.windows.net".
    /// </summary>
    [Required]
    [Uri]
    public required Uri Endpoint { get; init; }

    /// <summary>
    /// Gets the key credential used to authenticate to an Azure AI Search resource.
    /// </summary>
    /// <remarks>
    /// If <see langword="null"/>,
    /// credentials to authenticate against the Azure AI Search resource, then a default `Azure.Core.TokenCredential`
    /// authentication flow for applications will be used instead.
    /// </remarks>
    public string Key { get; init; } = string.Empty;

    public double ResultThreshold { get; init; } = 3.0;
}
