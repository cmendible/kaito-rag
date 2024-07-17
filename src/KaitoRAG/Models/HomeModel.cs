namespace KaitoRAG.Models;

public class HomeModel
{
    public BotModel BotModel { get; init; }

    public Uri TeamsUrl { get; init; }

    public bool AreGlobalDocumentsLoad { get; set; }
}
