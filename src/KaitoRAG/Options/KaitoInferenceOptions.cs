// Ignore Spelling: kaito
// Ignore Spelling: https

using System.ComponentModel.DataAnnotations;

using KaitoRAG.DataAnnotations;

namespace KaitoRAG.Options;

/// <summary>
/// 
/// </summary>
public class KaitoInferenceOptions
{
    /// <summary>
    /// Gets the Kaito inference service endpoint. 
    /// </summary>
    [Uri]
    [Required]
    [RegularExpression(@"^https?:\/\/.*\/chat$", ErrorMessage = "The Kaito inference endpoint must end with `/chat`.")]
    public Uri InferenceEndpoint { get; init; }

    [Range(0.1, 1.0)]
    public double Temperature { get; init; } = 0.1;

    [Range(0.1, 1.0)]
    public double TopP { get; init; } = 1.0;

    [Range(1, 4096)]
    public int MaxLength { get; init; } = 3000;
}
