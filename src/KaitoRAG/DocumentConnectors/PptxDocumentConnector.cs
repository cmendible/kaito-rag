#pragma warning disable SKEXP0050

using System.Text;

using CommunityToolkit.Diagnostics;

using DocumentFormat.OpenXml.Packaging;

using Microsoft.SemanticKernel.Plugins.Document;

namespace KaitoRAG.DocumentConnectors;

/// <summary>
/// Extracts the text from a Microsoft PowerPoint (<c>.pptx</c>) file, just one line for each slide.
/// </summary>
internal sealed class PptxDocumentConnector : IDocumentConnector
{
    /// <inheritdoc/>
    public void AppendText(Stream stream, string text)
    {
        // Intentionally not implemented to comply with the Liskov Substitution Principle...
    }

    /// <inheritdoc/>
    public void Initialize(Stream stream)
    {
        // Intentionally not implemented to comply with the Liskov Substitution Principle...
    }

    /// <inheritdoc/>
    public string ReadText(Stream stream)
    {
        Guard.IsNotNull(stream);

        using var presentation = PresentationDocument.Open(stream, false);

        var slideParts = presentation.PresentationPart?.SlideParts;

        if (slideParts == null)
        {
            return string.Empty;
        }

        var textBuilder = new StringBuilder();

        foreach (var slidePart in slideParts)
        {
            var slideText = GetAllTextInSlide(slidePart).Where(t => !string.IsNullOrWhiteSpace(t));

            if (slideText.Any())
            {
                textBuilder.AppendLine(string.Join(' ', slideText));
                textBuilder.AppendLine(string.Empty);
            }
        }

        return textBuilder.ToString().Trim();
    }

    /// <summary>
    /// Gets the text from the specified <paramref name="slidePart"/>.
    /// </summary>
    /// <param name="slidePart">The slide part to extract text from.</param>
    /// <returns>A collection of strings representing the texts extracted from <paramref name="slidePart"/>.</returns>
    private static IEnumerable<string> GetAllTextInSlide(SlidePart slidePart)
    {
        Guard.IsNotNull(slidePart);

        var slideText = new StringBuilder();

        // Iterate through all the paragraphs in the slide.
        foreach (var paragraph in slidePart.Slide.Descendants<DocumentFormat.OpenXml.Drawing.Paragraph>())
        {
            // Iterate through the lines of the paragraph.
            foreach (var text in paragraph.Descendants<DocumentFormat.OpenXml.Drawing.Text>())
            {
                slideText.Append(text.Text).Append(@". ");
            }
        }

        return [slideText.ToString().Trim()];
    }
}

#pragma warning restore SKEXP0050
