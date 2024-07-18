using Newtonsoft.Json;

namespace KaitoRAG.Services;

public class ChatHistoryRecord
{
    public enum ChatHistoryRecordRole
    {
        Assistant,

        User,
    }

    [JsonProperty(@"id")]
    public Guid Id { get; init; }

    [JsonProperty(@"userId")]
    public string UserId { get; init; }

    [JsonProperty(@"content")]
    public string Content { get; init; }

    [JsonProperty(@"timestamp")]
    public DateTime DateTimeUtc { get; init; }

    [JsonProperty(@"role")]
    public ChatHistoryRecordRole Role { get; init; }
}
