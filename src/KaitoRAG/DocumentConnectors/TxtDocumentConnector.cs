﻿#pragma warning disable SKEXP0050

using System.Text;

using CommunityToolkit.Diagnostics;

using Microsoft.SemanticKernel.Plugins.Document;

namespace KaitoRAG.DocumentConnectors;

/// <summary>
/// Extract text from a text (<c>.txt</c>) file.
/// </summary>
internal sealed class TxtDocumentConnector : IDocumentConnector
{
    private readonly Encoding encoding;

    /// <summary>
    /// Initializes a new instance of the <see cref="TxtDocumentConnector"/> class.
    /// </summary>
    /// <param name="encoding">The encoding to use when reading the text file.</param>
    public TxtDocumentConnector(Encoding encoding)
    {
        this.encoding = encoding;
    }

    /// <inheritdoc/>
    public string ReadText(Stream stream)
    {
        Guard.IsNotNull(stream);

        using var reader = new StreamReader(stream, encoding);
        return reader.ReadToEnd();
    }

    /// <inheritdoc/>
    public void Initialize(Stream stream)
    {
        // Intentionally not implemented to comply with the Liskov Substitution Principle...
    }

    /// <inheritdoc/>
    public void AppendText(Stream stream, string text)
    {
        // Intentionally not implemented to comply with the Liskov Substitution Principle...
    }
}

#pragma warning restore SKEXP0050
