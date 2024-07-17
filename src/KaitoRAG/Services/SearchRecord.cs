// Ignore Spelling: Utc

using System.Globalization;
using System.Text;
using System.Text.Json.Serialization;

namespace KaitoRAG.Services;

public class SearchRecord
{
    /// <summary>
    /// ID field name.
    /// </summary>
    public const string IdField = @"Id";

    /// <summary>
    /// Text field name.
    /// </summary>
    public const string ContentField = @"Content";

    /// <summary>
    /// Embedding field name.
    /// </summary>
    public const string EmbeddingField = @"Embedding";
    
    /// <summary>
    /// Created at field name.
    /// </summary>
    public const string CreatedAtUtcField = @"CreatedAtUtc";

    /// <summary>
    /// User ID field name.
    /// </summary>
    public const string UserIdField = @"UserId";

    /// <summary>
    /// The url of the document.
    /// </summary>
    public const string UrlField = @"Url";

    /// <summary>
    /// Title of the document field, usually the document name.
    /// </summary>
    public const string TitleField = @"Title";

    /// <summary>
    /// Gets or sets the record ID.
    /// </summary>
    [JsonPropertyName(IdField)]
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the content.
    /// </summary>
    [JsonPropertyName(ContentField)]
    public string? Content { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the content embedding.
    /// </summary>
    [JsonPropertyName(EmbeddingField)]
    public ReadOnlyMemory<float> Embedding { get; set; }

    /// <summary>
    /// Gets or sets the date and time when the record was created.
    /// </summary>
    [JsonPropertyName(CreatedAtUtcField)]
    public DateTime CreatedAtUtc { get; set; }

/// <summary>
    /// Gets or sets the user ID.
    /// </summary>
    [JsonPropertyName(UserIdField)]
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the url of the document.
    /// </summary>
    [JsonPropertyName(UrlField)]
    public string Url { get; set; } = string.Empty; // TODO - Check if this can be of Uri type instead of string

    /// <summary>
    /// Gets or sets the title of the document.
    /// </summary>
    [JsonPropertyName(TitleField)]
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// Encodes a specified unique identifier using a URL-safe algorithm.
    /// </summary>
    /// <remarks>
    /// Azure AI Search keys can contain only letters, digits, underscore, dash, equal sign, recommending
    /// to encode values with a URL-safe algorithm.
    /// </remarks>
    /// <param name="id">The original unique identifier to encode.</param>
    /// <returns>The encoded unique identifier as URL-safe for Azure AI Search.</returns>
    public static string EncodeId(string id)
    {
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(id));
    }

    /// <summary>
    /// Parses a date time offset from a string.
    /// </summary>
    /// <param name="value">The string to parse.</param>
    /// <returns>The parsed date time offset or null if the string is not a valid date time offset.</returns>
    public static DateTimeOffset? ParseDateTimeOffset(string? value)
    {
        return DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, out var parsed) // This successfully parses `yyyy-MM-dd` and `yyyy-MM`
                || DateTimeOffset.TryParseExact(value, @"yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed) // This successfully parses `yyyy`
                    ? parsed
                    : null;
    }
}
