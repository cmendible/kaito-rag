using System.ComponentModel.DataAnnotations;

using KaitoRAG.DataAnnotations;

namespace KaitoRAG.Options;

public sealed class DirectLineOptions
{
    [Required]
    [Uri]
    public Uri DirectLineEndpoint { get; init; }

    [Required]
    public string DirectLineToken { get; init; }
}
