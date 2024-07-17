using Microsoft.AspNetCore.Mvc;

using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Builder;

namespace KaitoRAG.Controllers;

[ApiController]
[Route(@"api/messages")]
public sealed class BotController : ControllerBase
{
    private readonly IBot bot;
    private readonly IBotFrameworkHttpAdapter adapter;

    /// <summary>
    /// Initializes a new instance of the <see cref="BotController"/> class.
    /// </summary>
    /// <param name="adapter">A bot adapter to use.</param>
    /// <param name="bot">A bot that can operate on incoming activities.</param>
    public BotController(IBotFrameworkHttpAdapter adapter, IBot bot)
    {
        this.adapter = adapter;
        this.bot = bot;
    }

    /// <summary>
    /// Handles a request for the bot.
    /// </summary>
    /// <remarks>
    /// This asynchronous method does not uses a <see cref="CancellationToken"/> to prevent issues request that takes a lot of time to be processed.
    /// </remarks>
    /// <returns>
    /// A <see cref="Task"/> that represents the asynchronous operation of handling the request for the bot.
    /// </returns>
    [HttpGet]
    [HttpPost]
    public Task HandleAsync()
    {
        return adapter.ProcessAsync(Request, Response, bot);
    }
}
