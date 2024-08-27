#pragma warning disable SKEXP0050

using System.Text;

using KaitoRAG.Options;

using Microsoft.Extensions.Options;
using Microsoft.SemanticKernel.Plugins.Document;
using Microsoft.SemanticKernel.Plugins.Document.OpenXml;
using Microsoft.SemanticKernel.Text;

using SharpToken;

namespace KaitoRAG.DocumentConnectors;

public sealed class DocumentContentExtractor
{
    private static readonly Dictionary<string, IDocumentConnector> DocumentConnectors = new()
    {
        { @".DOCX", new WordDocumentConnector() },
        { @".PDF", new PdfDocumentConnector() },
        { @".PPTX", new PptxDocumentConnector() },
        { @".TXT", new TxtDocumentConnector(Encoding.UTF8) },
        { @".MD", new TxtDocumentConnector(Encoding.UTF8) },
    };

    // Currently, the encoding `cl100k_base` is used by the `text-embedding-ada-002`, `text-embedding-3-small` and `text-embedding-3-large` embedding models.
    private static readonly GptEncoding GptEncoding = GptEncoding.GetEncoding(@"cl100k_base");

    private DocumentContentExtractorOptions options;

    /// <summary>
    /// Initializes a new instance of the <see cref="DocumentContentExtractor"/> class.
    /// </summary>
    /// <param name="optionsMonitor">A monitor for this class options.</param>
    public DocumentContentExtractor(IOptionsMonitor<DocumentContentExtractorOptions> optionsMonitor)
    {
        options = optionsMonitor.CurrentValue;

        optionsMonitor.OnChange(newOptions => options = newOptions);
    }

    public bool IsSupportedFileExtension(string fileExtension)
    {
        return DocumentConnectors.ContainsKey(fileExtension.ToUpperInvariant());
    }

    public IEnumerable<string> GetSupportedFileExtension()
    {
        return DocumentConnectors.Keys;
    }

    public List<string> GetDocumentContent(Stream stream, string fileExtension)
    {
        var connector = GetDocumentConnector(fileExtension);
        var content = connector.ReadText(stream).Replace(@"- ", string.Empty); // Reads the whole text and fixes any words that are split by a hyphen.

        var lines = TextChunker.SplitPlainTextLines(content, maxTokensPerLine: options.MaxTokensPerLine, tokenCounter: TokenCounter);
        var paragraphs = TextChunker.SplitPlainTextParagraphs(lines, maxTokensPerParagraph: options.MaxTokensPerParagraph, tokenCounter: TokenCounter);

        return paragraphs;
    }

    private static int TokenCounter(string content) => GptEncoding.Encode(content).Count;

    private static IDocumentConnector GetDocumentConnector(string fileExtension)
    {
        return GetDocumentConnector(fileExtension, true)!;
    }

    private static IDocumentConnector? GetDocumentConnector(string fileExtension, bool throwException)
    {
        if (DocumentConnectors.TryGetValue(fileExtension.ToUpperInvariant(), out var value))
        {
            return value;
        }

        if (throwException)
        {
            throw new InvalidOperationException($@"File extension '{fileExtension}' is not supported!");
        }

        return null;
    }
}

#pragma warning restore SKEXP0050
