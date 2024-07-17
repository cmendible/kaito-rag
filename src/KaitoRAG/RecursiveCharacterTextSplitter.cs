using CommunityToolkit.Diagnostics;

using KaitoRAG.Options;

using Microsoft.Extensions.Options;

namespace KaitoRAG;

public sealed class RecursiveCharacterTextSplitter
{
    /// <summary>
    /// Default collection of separator characters to use when splitting the text and creating chunks.
    /// </summary>
    public static readonly string[] DefaultSeparators = { ".", "!", "?", ";", ":", "\r\n", "\n" };

    /// <summary>
    /// Initializes a new instance of the <see cref="RecursiveCharacterTextSplitter"/> class.
    /// </summary>
    /// <param name="options">The options to use when configuring the text splitter.</param>
    /// <exception cref="InvalidOperationException">
    /// Thrown when the configured value for chunk overlap is greater than the configured value for chunk size.
    /// The value of chunks overlap must be smaller than the value of chunk size.
    /// </exception>
    public RecursiveCharacterTextSplitter(IOptionsMonitor<RecursiveCharacterTextSplitterOptions> options)
    {
        var opts = options.CurrentValue;

        ChunkOverlap = opts.ChunkOverlap;
        ChunkSize = opts.ChunkSize;
        Separators = opts.Separators?.Any() == true ? opts.Separators : new List<string>(DefaultSeparators);

        if (ChunkOverlap > ChunkSize)
        {
            throw new InvalidOperationException(@"Configured value for chunk overlap is greater than configured value for chunk size. It must be smaller!");
        }
    }

    /// <summary>
    /// Gets the number of elements (characters, tokens, etc.) overlapping between chunks.
    /// </summary>
    public int ChunkOverlap { get; }

    /// <summary>
    /// Gets the number of elements (characters, tokens, etc.) in each chunk.
    /// </summary>
    public int ChunkSize { get; }

    /// <summary>
    /// Gets the collection of separator characters to use when splitting the text and creating chunks.
    /// </summary>
    public IList<string> Separators { get; }

    /// <summary>
    /// Joins chunks into a single string using the specified separator.
    /// </summary>
    /// <param name="chunks">The collection of chunks to join.</param>
    /// <param name="separator">The separator to use between chunks.</param>
    /// <returns>A single string with all the chunks joined together by the specified separator.</returns>
    public static string JoinChunks(IEnumerable<string> chunks, string separator)
    {
        Guard.IsNotNull(chunks);
        Guard.IsNotNull(separator);

        var text = string.Join(separator, chunks).Trim();

        return text;
    }

    /// <summary>
    /// Splits the specified text, using the specified length function and specified <see cref="RecursiveCharacterTextSplitterOptions"/>.
    /// </summary>
    /// <param name="text">The text to be split.</param>
    /// <param name="lengthFunction">Length function used to calculate the length of a string.</param>
    /// <param name="options">Custom options used for splitting.</param>
    /// <returns>An IEnumerable of smaller text chunks.</returns>
    public IEnumerable<string> Split(string text, Func<string, int> lengthFunction, RecursiveCharacterTextSplitterOptions options)
    {
        var chunks = new List<string>();

        string separator = null;

        foreach (var s in options.Separators)
        {
            if (s == string.Empty || text.Contains(s, StringComparison.OrdinalIgnoreCase))
            {
                separator = s;
                break;
            }
        }

        var splits = (separator != null ? text.Split(separator, StringSplitOptions.RemoveEmptyEntries) : [text]).Select(s => s.Trim());

        var goodSplits = new List<string>();

        foreach (var split in splits)
        {
            if (lengthFunction(split) < options.ChunkSize)
            {
                goodSplits.Add(split);
            }
            else
            {
                if (goodSplits.Any())
                {
                    chunks.AddRange(MergeSplits(goodSplits, separator, lengthFunction, options));
                    goodSplits = [];
                }

                var otherChunks = Split(split, lengthFunction, options);
                chunks.AddRange(otherChunks);
            }
        }

        if (goodSplits.Any())
        {
            chunks.AddRange(MergeSplits(goodSplits, separator, lengthFunction, options));
        }

        return chunks;
    }

    /// <summary>
    /// Splits the specified text, using the specified length function.
    /// </summary>
    /// <param name="text">The text to split.</param>
    /// <param name="lengthFunction">A function to use to calculate the length (or size) of each split, usually specified by <see cref="ChunkSize"/>.</param>
    /// <returns>A collection of text splits.</returns>
    public IEnumerable<string> Split(string text, Func<string, int> lengthFunction)
    {
        return Split(text, lengthFunction, new RecursiveCharacterTextSplitterOptions()
        {
            ChunkOverlap = ChunkOverlap,
            ChunkSize = ChunkSize,
            Separators = Separators,
        });
    }

    /// <summary>
    /// Merges splits into chunks of text, using the specified separator and length function.
    /// </summary>
    /// <param name="splits">The collection of splits to merge into chunks.</param>
    /// <param name="separator">The separator to use between splits.</param>
    /// <param name="lengthFunction">The function to use to calculate the length (or size) of each chunk, as specified by <see cref="ChunkSize"/>.</param>
    /// <returns>A collection of chunks built from the splits.</returns>
    public IEnumerable<string> MergeSplits(IEnumerable<string> splits, string separator, Func<string, int> lengthFunction)
    {
        return MergeSplits(splits, separator, lengthFunction, new RecursiveCharacterTextSplitterOptions()
        {
            ChunkOverlap = ChunkOverlap,
            ChunkSize = ChunkSize,
            Separators = Separators,
        });
    }

    /// <summary>
    /// Merges splits into chunks of text, using the specified separator, length function and <see cref="TextSplitterOptions"/>.
    /// </summary>
    /// <param name="splits">The collection of splits to merge into chunks.</param>
    /// <param name="separator">The separator to use between splits.</param>
    /// <param name="lengthFunction">The function to use to calculate the length (or size) of each chunk, as specified by <paramref name="options"/> <see cref="TextSplitterOptions.ChunkSize"/>.</param>
    /// <param name="options">Custom options used for merge.</param>
    /// <returns>A collection of chunks built from the splits.</returns>
    public IEnumerable<string> MergeSplits(IEnumerable<string> splits, string separator, Func<string, int> lengthFunction, RecursiveCharacterTextSplitterOptions options)
    {
        Guard.IsNotNull(splits);
        Guard.IsNotNull(separator);
        Guard.IsNotNull(lengthFunction);
        Guard.IsNotNull(options);

        string chunk;
        var chunks = new List<string>();
        var currentChunks = new Queue<string>();

        var total = 0;
        var separatorLength = lengthFunction(separator);

        foreach (var split in splits)
        {
            var splitLength = lengthFunction(split);
            var hasCurrentChunks = currentChunks.Any();

            if (hasCurrentChunks && total + splitLength + separatorLength > options.ChunkSize)
            {
                chunk = JoinChunks(currentChunks, separator);

                if (chunk != null)
                {
                    chunks.Add(chunk);
                }

                // Keep on dequeuing if:
                // - There are still chunks and their length is long
                // - There is a larger chunk than the chunk overlap
                while (
                    hasCurrentChunks
                    && (total > options.ChunkOverlap || (total + splitLength + separatorLength > options.ChunkSize && total > 0)))
                {
                    total -= lengthFunction(currentChunks.Dequeue()) + (currentChunks.Count > 1 ? separatorLength : 0);
                    hasCurrentChunks = currentChunks.Any();
                }
            }

            currentChunks.Enqueue(split);
            total += splitLength + (currentChunks.Count > 1 ? separatorLength : 0);
        }

        chunk = JoinChunks(currentChunks, separator);

        if (chunk != null)
        {
            chunks.Add(chunk);
        }

        return chunks;
    }
}
