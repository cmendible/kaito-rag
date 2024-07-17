using System.ComponentModel.DataAnnotations;

using KaitoRAG.DataAnnotations;

namespace KaitoRAG.Options;

internal sealed class AzureOpenAIOptions
{
    /// <summary>
    /// Gets the <see cref="Uri "/> for an Azure OpenAI resource. This should include protocol and host name.
    /// </summary>
    [Required]
    [Uri]
    public Uri Endpoint { get; init; }

    /// <summary>
    /// Gets the key credential used to authenticate to an Azure OpenAI resource. If <see langword="null"/>, credentials to authenticate against the Azure OpenAI resource,
    /// then a default `Azure.Core.TokenCredential` authentication flow for applications will be used instead.
    /// </summary>
    public string? Key { get; init; }

    /// <summary>
    /// Gets the model deployment name on the LLM (for example OpenAI) to use for embeddings.
    /// </summary>
    /// <remarks>
    /// <b>WARNING</b>: The model name does not necessarily have to be the same as the model ID. For example, a model of type `text-embedding-ada-002` might be called `MyEmbeddings`;
    /// this means that the value of this property does not necessarily indicate the model implemented behind it.
    /// </remarks>
    [Required]
    public string EmbeddingsModelDeploymentName { get; init; }
}
