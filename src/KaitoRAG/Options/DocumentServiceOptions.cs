using System.ComponentModel.DataAnnotations;

namespace KaitoRAG.Options;

/// <summary>
/// Options parameters for the <see cref="AttachmentService"/>.
/// </summary>
public sealed class DocumentServiceOptions
{
    [Required]
    public string BlobStorageConnectionString { get; init; }

    /// <summary>
    /// Gets the interval, in chunks, at which to report the progress of file processing. Every <i>N</i> chunks, progress is reported.
    /// </summary>
    /// <remarks>
    /// Default value is 50.
    /// </remarks>
    public int ProgressReportChunksInterval { get; init; } = 5;
}
