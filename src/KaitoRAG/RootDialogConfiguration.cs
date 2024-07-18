using KaitoRAG.Services;

using Microsoft.SemanticKernel;

namespace KaitoRAG;

internal record RootDialogConfiguration(
    IKernelBuilder KernelBuilder,
    KaitoService KaitoService,
    GlobalSearchService GlobalSearchService,
    UserSearchService UserSearchService);
