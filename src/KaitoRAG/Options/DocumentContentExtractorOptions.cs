using System.ComponentModel.DataAnnotations;

namespace KaitoRAG.Options;

public sealed class DocumentContentExtractorOptions
{
    [Range(1, int.MaxValue)]
    public int MaxTokensPerLine { get; init; }

    [Range(1, int.MaxValue)]
    public int MaxTokensPerParagraph { get; init; }
}
