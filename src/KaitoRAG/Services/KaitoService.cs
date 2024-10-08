﻿// Ignore Spelling: kaito

using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.Json.Serialization;

using KaitoRAG.Options;

using Microsoft.Extensions.Options;

using SharpToken;

namespace KaitoRAG.Services;

public class KaitoService
{
    private static readonly GptEncoding GptEncoding = GptEncoding.GetEncoding(@"cl100k_base");

    private static readonly JsonSerializerOptions JsonSerializerOptions = new()
    {
        AllowTrailingCommas = true,
        PropertyNameCaseInsensitive = true,
    };

    private readonly ILogger logger;

    private readonly HttpClient httpClient;

    private KaitoInferenceOptions options;

    public KaitoService(IHttpClientFactory httpClientFactory, ILogger<KaitoService> logger, IOptionsMonitor<KaitoInferenceOptions> optionsMonitor)
    {
        this.logger = logger;
        httpClient = httpClientFactory.CreateClient();

        options = optionsMonitor.CurrentValue;

        optionsMonitor.OnChange(newOptions => options = newOptions);
    }

    public async Task<string> GetInferenceAsync(string prompt, CancellationToken cancellationToken = default)
    {
        var request = new KaitoRequest()
        {
            Prompt = prompt,
            KaitoKeywordArguments = new KaitoKeywordArguments()
            {
                MaxLength = GptEncoding.Encode(prompt).Count + options.MaxLength,
                Temperature = options.Temperature,
                TopP = options.TopP,
            },
        };

        logger.LogInformation($"Kaito request:\n\n{JsonSerializer.Serialize(request, JsonSerializerOptions)}\n\n");

        using var httpRequestMessage = new HttpRequestMessage(HttpMethod.Post, options.InferenceEndpoint);
        httpRequestMessage.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue(@"application/json"));
        httpRequestMessage.Content = JsonContent.Create(request, new MediaTypeWithQualityHeaderValue(@"application/json"), JsonSerializerOptions);

        using var httpResponseMessage = await httpClient.SendAsync(httpRequestMessage, cancellationToken);

        if (httpResponseMessage.IsSuccessStatusCode)
        {
            var response = await httpResponseMessage.Content.ReadFromJsonAsync<KaitoResponse>(JsonSerializerOptions, cancellationToken);
            return response!.Value;
        }
        else
        {
            logger.LogError($@"Error retrieving answer from Kaito. Status code: {httpResponseMessage.StatusCode}. Error: {await httpResponseMessage.Content.ReadAsStringAsync(cancellationToken)}");
            return @"We're sorry for the inconvenience. Something didn't go as planned. Please give it another try in a few minutes, and we'll do our best to have everything running smoothly.";
        }
    }

    private sealed class KaitoRequest
    {
        [JsonPropertyName(@"prompt")]
        public string Prompt { get; init; } = string.Empty;

        [JsonPropertyName(@"return_full_text")]
        public bool ReturnFullText { get; init; } = false;

        [JsonPropertyName(@"clean_up_tokenization_spaces")]
        public bool CleanUpTokenizationSpaces { get; init; } = true;

        [JsonPropertyName(@"generate_kwargs")]
        public KaitoKeywordArguments KaitoKeywordArguments { get; set; } = new();
    }

    private sealed class KaitoResponse
    {
        [JsonPropertyName(@"result")]
        public string Value { get; init; } = string.Empty;
    }

    private sealed class KaitoKeywordArguments
    {
        [JsonPropertyName(@"max_length")]
        public int MaxLength { get; set; } = 4096;

        [JsonPropertyName(@"temperature")]
        public double Temperature { get; set; } = 1.0;

        [JsonPropertyName(@"top_p")]
        public double TopP { get; set; } = 1.0;
    }
}
