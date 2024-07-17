#pragma warning disable SKEXP0050

using System.Text;

using Microsoft.SemanticKernel.Plugins.Document;

using UglyToad.PdfPig;
using UglyToad.PdfPig.Content;
using UglyToad.PdfPig.Core;
using UglyToad.PdfPig.DocumentLayoutAnalysis;
using UglyToad.PdfPig.DocumentLayoutAnalysis.PageSegmenter;
using UglyToad.PdfPig.DocumentLayoutAnalysis.ReadingOrderDetector;
using UglyToad.PdfPig.DocumentLayoutAnalysis.WordExtractor;

namespace KaitoRAG.DocumentConnectors;

internal sealed class PdfDocumentConnector : IDocumentConnector
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
        if (stream == null)
        {
            throw new ArgumentNullException(nameof(stream));
        }

        using var document = PdfDocument.Open(stream);

        var textBlocks = new List<TextBlock>();
        foreach (var page in document.GetPages())
        {
            var pageTextBlocks = GetTextBlocks(page);

            textBlocks.AddRange(pageTextBlocks);
        }

        var cleanedTextBlocks = CleanTextBlocks(document, textBlocks);

        var sb = new StringBuilder();
        foreach (var block in cleanedTextBlocks)
        {
            sb.Append(block.Text);
            sb.AppendLine();
        }

        return sb.ToString();
    }

    /// <summary>
    /// Extracts <see cref="TextBlock"/> from a given page of a PDF document.
    /// </summary>
    /// <param name="page">The page from which to extract text blocks.</param>
    /// <returns>An enumerable collection of <see cref="TextBlock" /> extracted from the page.</returns>
    private static IEnumerable<TextBlock> GetTextBlocks(Page page)
    {
        // 1. Extract words
        var words = NearestNeighbourWordExtractor.Instance.GetWords(page.Letters);

        // 2. Segment page
        var pageSegmenterOptions = new DocstrumBoundingBoxes.DocstrumBoundingBoxesOptions()
        {
            LineSeparator = " ",
        };
        var pageSegmenter = new DocstrumBoundingBoxes(pageSegmenterOptions);
        var textBlocks = pageSegmenter.GetBlocks(words);

        // 3. Post-processing
        var orderedTextBlocks = RenderingReadingOrderDetector.Instance.Get(textBlocks);

        return orderedTextBlocks;
    }

    /// <summary>
    /// Cleans the extracted text blocks from a PDF document by removing common words that overlap across pages and excluding non-horizontal text.
    /// </summary>
    /// <param name="document">The PDF document.</param>
    /// <param name="textBlocks">The extracted text blocks.</param>
    /// <returns>The cleaned text blocks.</returns>
    private static IEnumerable<TextBlock> CleanTextBlocks(PdfDocument document, IEnumerable<TextBlock> textBlocks)
    {
        var horizontalTextBlocks = textBlocks
            .Where(tb => tb.TextOrientation == TextOrientation.Horizontal)
            .Select(textBlock => new TextBlockElement(textBlock));

        return RemoveCommonTextElements(document, horizontalTextBlocks);
    }

    /// <summary>
    /// Removes common text elements from a collection of text elements based on their repetition in the same position throughout the document.
    /// </summary>
    /// <typeparam name="T">The type of text elements (e.g., Word, TextBlock).</typeparam>
    /// <param name="document">The PDF document.</param>
    /// <param name="elements">The collection of text elements from which to remove common elements.</param>
    /// <returns>An IEnumerable containing the non-common text elements.</returns>
    private static IEnumerable<T> RemoveCommonTextElements<T>(PdfDocument document, IEnumerable<TextElement<T>> elements)
    {
        var textElements = elements.ToList();

        var commonTextElements = GetCommonTextElements(document, textElements);

        return RemoveCommonTextElements(textElements, commonTextElements);
    }

    /// <summary>
    /// Removes common text elements from a collection of text elements based on a list of common elements.
    /// </summary>
    /// <typeparam name="T">The type of text elements (e.g., Word, TextBlock).</typeparam>
    /// <param name="elements">The collection of text elements from which to remove common elements.</param>
    /// <param name="commonElements">The list of common text elements to be removed.</param>
    /// <returns>An IEnumerable containing the non-common text elements.</returns>
    private static IEnumerable<T> RemoveCommonTextElements<T>(IEnumerable<TextElement<T>> elements, IEnumerable<TextElement<T>> commonElements)
    {
        var textElements = elements.ToList();

        var nonCommonTextElements = textElements.Where(textElement => !IsCommonTextElement(textElement, commonElements)).Select(textElement => textElement.Element);

        return nonCommonTextElements;
    }

    /// <summary>
    /// Checks if a given word is a common word by comparing it with a collection of common words.
    /// </summary>
    /// <typeparam name="T">The type of text elements (e.g., Word, TextBlock).</typeparam>
    /// <param name="textElement">The word to check.</param>
    /// <param name="commonTextElements">The collection of common words to compare against.</param>
    /// <returns>True if the word is common; otherwise, false.</returns>
    private static bool IsCommonTextElement<T>(TextElement<T> textElement, IEnumerable<TextElement<T>> commonTextElements)
    {
        return commonTextElements.Any(w => w.Text == textElement.Text && w.BoundingBox.Equals(textElement.BoundingBox));
    }

    /// <summary>
    /// Retrieves common text elements from a PDF document. It is based on the repetition of the same text element in the same position throughout the document.
    /// </summary>
    /// <typeparam name="T">The type of text elements (e.g., Word, TextBlock).</typeparam>
    /// <param name="document">The PDF document.</param>
    /// <param name="elements">The list of text elements from which to retrieve common elements.</param>
    /// <returns>A collection of common text elements.</returns>
    private static IList<TextElement<T>> GetCommonTextElements<T>(PdfDocument document, IEnumerable<TextElement<T>> elements)
    {
        // We want to remove common words that overlap on pages, so we need to find the minimum number of overlaps a word must have to be considered common.
        // In this case, we will consider a word to be common if it overlaps on at least a quarter of its pages.
        var minOverlaps = document.NumberOfPages / 4;

        // Edge case...
        if (minOverlaps < 2)
        {
            minOverlaps = 2;
        }

        var result = new List<TextElement<T>>();
        var textElementCount = new Dictionary<TextElement<T>, int>();
        var textElements = elements.ToList();

        for (var i = 0; i < textElements.Count; i++)
        {
            var currentTextElement = textElements[i];

            for (var j = i + 1; j < textElements.Count; j++)
            {
                var nextTextElement = textElements[j];

                if (currentTextElement.Text == nextTextElement.Text && RectanglesOverlap(currentTextElement.BoundingBox, nextTextElement.BoundingBox))
                {
                    IncrementTextElementCount(textElementCount, currentTextElement);
                }
            }
        }

        foreach (var textElement in textElementCount.Keys)
        {
            if (textElementCount[textElement] >= minOverlaps)
            {
                result.Add(textElement);
            }
        }

        return result;
    }

    private static void IncrementTextElementCount<T>(IDictionary<TextElement<T>, int> textElementCount, TextElement<T> currentTextElement)
    {
        if (textElementCount.ContainsKey(currentTextElement))
        {
            textElementCount[currentTextElement]++;
        }
        else
        {
            textElementCount[currentTextElement] = 1;
        }
    }

    private static bool RectanglesOverlap(PdfRectangle rect1, PdfRectangle rect2)
    {
        return rect1.Left < rect2.Right && rect1.Right > rect2.Left && rect1.Bottom < rect2.Top && rect1.Top > rect2.Bottom;
    }

    private class TextElement<T>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="TextElement{T}"/> class with the specified element.
        /// </summary>
        /// <param name="element">The specific text element.</param>
        public TextElement(T element)
        {
            Element = element;
        }

        /// <summary>
        /// Gets the text content of the text element.
        /// </summary>
        public string Text { get; protected init; }

        /// <summary>
        /// Gets the bounding box of the text element.
        /// </summary>
        public PdfRectangle BoundingBox { get; protected init; }

        /// <summary>
        /// Gets the specific text element.
        /// </summary>
        public T Element { get; }
    }

    private sealed class TextBlockElement : TextElement<TextBlock>
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="TextBlockElement"/> class with the specified TextBlock element.
        /// </summary>
        /// <param name="textBlock">The specific Word element.</param>
        public TextBlockElement(TextBlock textBlock) : base(textBlock)
        {
            Text = textBlock.Text;
            BoundingBox = textBlock.BoundingBox;
        }
    }
}

#pragma warning restore SKEXP0050
