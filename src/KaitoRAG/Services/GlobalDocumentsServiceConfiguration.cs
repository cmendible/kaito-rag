﻿using KaitoRAG.DocumentConnectors;
using KaitoRAG.Options;

using Microsoft.Extensions.Options;

using Microsoft.SemanticKernel;

namespace KaitoRAG.Services;

public sealed record GlobalDocumentsServiceConfiguration(
    DocumentContentExtractor DocumentContentExtractor,
    IKernelBuilder KernelBuilder,
    GlobalSearchService GlobalSearchService,
    IHttpClientFactory HttpClientFactory,
    IOptionsMonitor<DocumentServiceOptions> DocumentServiceOptions)
    //    : AttachmentServiceConfigurationBase(DocumentContentExtractor, Kernel, HttpClientFactory, AttachmentServiceOptions)
    ;