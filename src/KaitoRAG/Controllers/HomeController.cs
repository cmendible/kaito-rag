using System.Diagnostics;

using KaitoRAG.Models;
using KaitoRAG.Options;
using KaitoRAG.Services;

using Microsoft.AspNetCore.Mvc;

using Microsoft.Extensions.Options;

namespace KaitoRAG.Controllers;

public class HomeController : Controller
{
    private readonly IConfiguration configuration;
    private readonly ILogger logger;

    private readonly DirectLineOptions directLineOptions;
    private readonly GlobalDocumentsService globalDocumentsService;

    public HomeController(GlobalDocumentsService globalDocumentsService, IConfiguration configuration, IOptions<DirectLineOptions> directLineOptions, ILogger<HomeController> logger)
    {
        this.logger = logger;
        this.configuration = configuration;
        this.directLineOptions = directLineOptions.Value;
        this.globalDocumentsService = globalDocumentsService;
    }

    public async Task<IActionResult> IndexAsync(string? actionName, CancellationToken cancellationToken)
    {
        return View(await BuildHomeModelAsync(cancellationToken));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<PartialViewResult> LoadGlobalDocumentsAsync(CancellationToken cancellationToken)
    {
        await globalDocumentsService.LoadGlobalDocumentsAsync(cancellationToken);
        var model = await BuildHomeModelAsync(cancellationToken);
        return PartialView(@"_HomeActionsPartial", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<PartialViewResult> ReloadGlobalDocuments(CancellationToken cancellationToken)
    {
        await globalDocumentsService.ReloadGlobalDocumentsAsync(cancellationToken);
        var model = await BuildHomeModelAsync(cancellationToken);
        return PartialView(@"_HomeActionsPartial", model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<PartialViewResult> UnloadGlobalDocuments(CancellationToken cancellationToken)
    {
        await globalDocumentsService.UnloadGlobalDocumentsAsync(cancellationToken);
        var model = await BuildHomeModelAsync(cancellationToken);
        return PartialView(@"_HomeActionsPartial", model);
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }

    private async Task<HomeModel> BuildHomeModelAsync(CancellationToken cancellationToken)
    {
        return new HomeModel()
        {
            BotModel = new BotModel()
            {
                DirectlineEndpoint = directLineOptions.DirectLineEndpoint,
                DirectLineToken = directLineOptions.DirectLineToken,
            },
            TeamsUrl = new Uri($@"https://teams.microsoft.com/l/chat/0/0?users=28:{configuration[@"MicrosoftAppId"]}"),
            AreGlobalDocumentsLoad = await globalDocumentsService.HasDocumentsAsync(cancellationToken),
        };
    }
}
