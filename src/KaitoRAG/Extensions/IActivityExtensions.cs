using Microsoft.Bot.Schema;

namespace KaitoRAG.Extensions;

/// <summary>
/// Contains extension methods for <see cref="IActivity"/> class.
/// </summary>
public static class IActivityExtensions
{
    /// <summary>
    /// Gets the user ID from the provided activity.
    /// If the Azure Active Directory (AAD) object ID is present, it is used; otherwise, falls back to the user ID.
    /// </summary>
    /// <param name="activity">The activity from which to extract the user ID.</param>
    /// <returns>The user ID associated with the activity.</returns>
    public static string GetUserId(this IActivity activity)
    {
        var from = activity.From;

        return string.IsNullOrWhiteSpace(from.AadObjectId)
            ? from.Id
            : from.AadObjectId;
    }
}
