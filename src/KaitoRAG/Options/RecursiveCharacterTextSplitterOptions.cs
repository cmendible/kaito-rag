using System.ComponentModel.DataAnnotations;

namespace KaitoRAG.Options;

/// <summary>
/// Options for a recursive character text splitter.
/// </summary>
public sealed class RecursiveCharacterTextSplitterOptions
{
    /// <summary>
    /// Gets the number of elements (characters, tokens, etc.) overlapping between chunks.
    /// </summary>
    [Required]
    [Range(0, int.MaxValue)]
    public int ChunkOverlap { get; init; } = 10;

    /// <summary>
    /// Gets the number of elements (characters, tokens, etc.) in each chunk.
    /// </summary>
    [Required]
    [Range(0, int.MaxValue)]
    public int ChunkSize { get; init; } = 100;

    /// <summary>
    /// Gets the collection of separator characters to use when splitting the text and creating chunks.
    /// </summary>
    public IList<string> Separators { get; init; }
}
