using KaitoRAG.DocumentConnectors;
using KaitoRAG.Options;

using Microsoft.Extensions.Options;
using Microsoft.SemanticKernel;

namespace KaitoRAG.Services;

internal sealed record UserAttachmentServiceConfiguration(
    ConversationReferenceService ConversationReferenceService,
    DocumentContentExtractor DocumentContentExtractor,
    UserSearchService UserSearchService,
    IKernelBuilder KernelBuilder, 
    IHttpClientFactory HttpClientFactory,
    IOptionsMonitor<DocumentServiceOptions> AttachmentServiceOptions)
        : AttachmentServiceConfigurationBase(ConversationReferenceService, DocumentContentExtractor, KernelBuilder, HttpClientFactory, AttachmentServiceOptions);
