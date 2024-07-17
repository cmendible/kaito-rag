using KaitoRAG.Services;

using Microsoft.SemanticKernel;

namespace KaitoRAG;

internal record RootDialogConfiguration(
    IKernelBuilder KernelBuilder,
    GlobalSearchService GlobalSearchService,
    UserSearchService UserSearchService);
