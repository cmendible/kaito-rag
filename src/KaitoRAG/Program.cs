#pragma warning disable SKEXP0010

using System.Diagnostics;

using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;

using DocumentFormat.OpenXml.Office2016.Drawing.ChartDrawing;

using KaitoRAG;
using KaitoRAG.DocumentConnectors;
using KaitoRAG.Options;
using KaitoRAG.Services;

using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;

using Microsoft.Bot.Builder;
using Microsoft.Bot.Builder.ApplicationInsights;
using Microsoft.Bot.Builder.Dialogs;
using Microsoft.Bot.Builder.Integration.ApplicationInsights.Core;
using Microsoft.Bot.Builder.Integration.AspNet.Core;
using Microsoft.Bot.Connector.Authentication;

using Microsoft.Extensions.Configuration.AzureAppConfiguration;
using Microsoft.Extensions.Options;

using Microsoft.SemanticKernel;

/* Load Configuration */

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = Directory.GetCurrentDirectory(),
});

builder.Configuration.SetBasePath(Directory.GetCurrentDirectory());

if (Debugger.IsAttached)
{
    builder.Configuration.AddJsonFile(@"appsettings.debug.json", optional: true, reloadOnChange: true);
}

builder.Configuration.AddJsonFile($@"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true)
                     .AddJsonFile($@"appsettings.{Environment.UserName}.json", optional: true, reloadOnChange: true)
                     .AddEnvironmentVariables()
                     ;

// Load configuration from Azure App Configuration, and set Key Vault client for secrets...
var appConfigurationConnectionString = builder.Configuration.GetConnectionString(@"AppConfig");

var useAppConfiguration = !string.IsNullOrWhiteSpace(appConfigurationConnectionString);

if (useAppConfiguration)
{
    var azureCredentials = new ChainedTokenCredential(new DefaultAzureCredential(), new EnvironmentCredential());

    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        var label = $@"{builder.Environment.EnvironmentName}-{typeof(Program).Assembly.GetName().Name}";

        options.Connect(appConfigurationConnectionString)
               .ConfigureKeyVault(keyVault =>
               {
                   keyVault.SetCredential(azureCredentials);
               })
               .Select(KeyFilter.Any, LabelFilter.Null) // Load configuration values with no label
               .Select(KeyFilter.Any, label) // Override with any configuration values specific to current application
               .ConfigureRefresh(refreshOptions =>
               {
                   refreshOptions.Register(@"Sentinel", label, refreshAll: true);
                   refreshOptions.SetCacheExpiration(TimeSpan.FromSeconds(86400)); // Default is 30 seconds (https://learn.microsoft.com/en-us/azure/azure-app-configuration/enable-dynamic-configuration-aspnet-core#reload-data-from-app-configuration), set this to a day.
               })
               ;
    }, optional: false);

    builder.Services.AddAzureAppConfiguration();
}

var isDevelopment = builder.Environment.IsDevelopment();
var isStaging = builder.Environment.IsStaging(); // Usually, staging environments are used for testing purposes...

/* Load Options */

builder.Services.AddOptionsWithValidateOnStart<AzureOpenAIOptions>().Bind(builder.Configuration.GetSection(nameof(AzureOpenAIOptions))).ValidateDataAnnotations();
builder.Services.AddOptionsWithValidateOnStart<AzureSearchOptions>().Bind(builder.Configuration.GetSection(nameof(AzureSearchOptions))).ValidateDataAnnotations();
builder.Services.AddOptionsWithValidateOnStart<DirectLineOptions>().Bind(builder.Configuration.GetSection(nameof(DirectLineOptions))).ValidateDataAnnotations();
builder.Services.AddOptionsWithValidateOnStart<DocumentContentExtractorOptions>().Bind(builder.Configuration.GetSection(nameof(DocumentContentExtractorOptions))).ValidateDataAnnotations();
builder.Services.AddOptionsWithValidateOnStart<DocumentServiceOptions>().Bind(builder.Configuration.GetSection(nameof(DocumentServiceOptions))).ValidateDataAnnotations();
builder.Services.AddOptionsWithValidateOnStart<KaitoInferenceOptions>().Bind(builder.Configuration.GetSection(nameof(KaitoInferenceOptions))).ValidateDataAnnotations();
builder.Services.AddOptionsWithValidateOnStart<RecursiveCharacterTextSplitterOptions>().Bind(builder.Configuration.GetSection(nameof(RecursiveCharacterTextSplitterOptions))).ValidateDataAnnotations();

/* Logging Configuration */

var applicationInsightsConnectionString = builder.Configuration.GetConnectionString(Constants.ConnectionStrings.ApplicationInsights);

builder.Logging.AddApplicationInsights((telemetryConfiguration) => telemetryConfiguration.ConnectionString = applicationInsightsConnectionString, (_) => { })
               .AddConsole()
               ;

if (Debugger.IsAttached)
{
    builder.Logging.AddDebug();
}

/* Application Services */

builder.Services.AddApplicationInsightsTelemetry(builder.Configuration)
                .AddLogging(loggingBuilder => loggingBuilder.AddApplicationInsights())
                .AddRouting()
                .AddHttpClient()
                .AddSingleton<ConversationReferenceService>()
                .AddSingleton<DocumentContentExtractor>()
                .AddSingleton<GlobalSearchService>()
                .AddSingleton<UserSearchService>()
                .AddSingleton<UserAttachmentService>()
                .AddSingleton<UserAttachmentServiceConfiguration>()
                .AddSingleton<GlobalDocumentsService>()
                .AddSingleton<GlobalDocumentsServiceConfiguration>()
                .AddSingleton<RecursiveCharacterTextSplitter>()
                .AddSingleton<KaitoService>()
                .AddHealthChecks()
                ;

var mvcBuilder = builder.Services.AddControllersWithViews(options =>
{
    options.SuppressAsyncSuffixInActionNames = true;
});

if (isDevelopment)
{
    mvcBuilder.AddRazorRuntimeCompilation();
}

/* Bot Configuration */

builder.Services.AddSingleton<BotFrameworkAuthentication, ConfigurationBotFrameworkAuthentication>()
                .AddSingleton<IBotTelemetryClient>(new BotTelemetryClient(new TelemetryClient(new TelemetryConfiguration { ConnectionString = applicationInsightsConnectionString })))
                .AddSingleton<ITelemetryInitializer, OperationCorrelationTelemetryInitializer>()
                .AddSingleton<ITelemetryInitializer, TelemetryBotIdInitializer>()
                .AddSingleton<ITranscriptLogger, MemoryTranscriptStore>()
                .AddSingleton<IStorage, MemoryStorage>() // Create the bot storage for the `User` and `Conversation` states.
                .AddSingleton<ConversationState>()
                .AddSingleton<UserState>()
                .AddSingleton<CloudAdapterWithErrorHandlerConfiguration>()
                .AddSingleton<IBotFrameworkHttpAdapter, CloudAdapterWithErrorHandler>()
                .AddSingleton<IBot, Bot>()
                .AddSingleton<BotConfiguration>()
                .AddSingleton<Dialog, RootDialog>()
                .AddSingleton<RootDialogConfiguration>()
                ;

/* OpenAI & Semantic Kernel Configuration */

builder.Services.AddSingleton(serviceProvider =>
{
    var oaiOptionsMonitor = serviceProvider.GetRequiredService<IOptions<AzureOpenAIOptions>>();
    var oaiOptions = oaiOptionsMonitor.Value;

    var oaiClient = string.IsNullOrWhiteSpace(oaiOptions.Key)
                        ? new OpenAIClient(oaiOptions.Endpoint, new DefaultAzureCredential())
                        : new OpenAIClient(oaiOptions.Endpoint, new AzureKeyCredential(oaiOptions.Key));

    var kernelBuilder = Kernel.CreateBuilder();

    kernelBuilder.Services.AddLogging(configure =>
    {
        configure.AddApplicationInsights(configureTelemetryConfiguration: (telemetryConfiguration) =>
        {
            telemetryConfiguration.ConnectionString = serviceProvider.GetRequiredService<IConfiguration>().GetConnectionString(@"ApplicationInsights");
        }, configureApplicationInsightsLoggerOptions: (options) => { })
        .AddConsole()
        ;
    });

    kernelBuilder.AddAzureOpenAITextEmbeddingGeneration(oaiOptions.EmbeddingsModelDeploymentName, oaiClient);

    return kernelBuilder;
});

/* Application Middleware Configuration and HTTP request pipeline */

var app = builder.Build();

app.UseStaticFiles();

if (!isDevelopment)
{
    app.UseExceptionHandler(@"/Home/Error")
       .UseHsts() // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
       ;
}

if (isDevelopment || isStaging)
{
    app.UseDeveloperExceptionPage();
}

if (useAppConfiguration)
{
    app.UseAzureAppConfiguration();
}

app.UseRouting()
   .UseAuthentication()
   .UseAuthorization()
   .UseEndpoints(endpoints =>
   {
       endpoints.MapControllers();
       endpoints.MapControllerRoute(name: @"default", pattern: @"{controller=Home}/{action=Index}/{id?}");
   })
   ;

await app.RunAsync();

#pragma warning restore SKEXP0010
