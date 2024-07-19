﻿#pragma warning disable SKEXP0050

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
    private static readonly GptEncoding DefaultGptEncoding = GptEncoding.GetEncoding(@"cl100k_base");

    private readonly RecursiveCharacterTextSplitter recursiveCharacterTextSplitter;

    private DocumentContentExtractorOptions options;

    public DocumentContentExtractor(RecursiveCharacterTextSplitter recursiveCharacterTextSplitter, IOptionsMonitor<DocumentContentExtractorOptions> optionsMonitor)
    {
        this.recursiveCharacterTextSplitter = recursiveCharacterTextSplitter;

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

        var content = connector.ReadText(stream);

        var splits = recursiveCharacterTextSplitter.Split(content, content => DefaultGptEncoding.Encode(content).Count);

        ////// Azure OpenAI currently supports input arrays up to 16 for `text-embedding-ada-002` (Version 2).
        ////// Both require the max input token limit per API request to remain under 8191 for this model.
        //////var chunks = ChunkByAggregate(splits, seed: 0, aggregator: (tokenCount, paragraph) => tokenCount + DefaultGptEncoding.Encode(paragraph).Count, predicate: (tokenCount, index) => tokenCount < 8191 && index < 16);

        //////return chunks.ToList();

        return splits.ToList();
    }

    private IDocumentConnector GetDocumentConnector(string fileExtension)
    {
        return GetDocumentConnector(fileExtension, true)!;
    }

    private IDocumentConnector? GetDocumentConnector(string fileExtension, bool throwException)
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