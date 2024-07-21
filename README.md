# Kaito-RAG

A simple document-based RAG application that uses Small Language Models (SLM) like [Microsoft Phi-3](https://azure.microsoft.com/en-us/products/phi-3), [Falcon 7b](https://falconllm.tii.ae/falcon-models.html) or [Mitral 7b](https://mistral.ai/news/announcing-mistral-7b/) to answer questions from the content of documents.

This RAG application uses the new [Kubernetes AI toolchain operator (Kaito)](https://learn.microsoft.com/en-us/azure/aks/ai-toolchain-operator), a Kubernetes operator that simplifies the experience of running Open-Source Software (OSS) AI models on your AKS cluster, which in turn uses [Karpenter](https://karpenter.sh/) under the hood to automatically provision the necessary GPU nodes based on a specification provided in the Workspace custom resource definition (CRD) and sets up the inference server as an endpoint for your AI models. This add-on reduces onboarding time and allows you to focus on AI model usage and development rather than infrastructure setup.

## High-level Architecture

The following diagram shows the high-level architecture of the **Kaito-RAG** solution:

![High-level Architecture](/assets/Architecture%20v0.1.png)
[Visio File](/assets/Architecture%20v0.1.vsdx)

## Prerequisites

-   An active [Azure subscription](https://docs.microsoft.com/en-us/azure/guides/developer/azure-developer-guide#understanding-accounts-subscriptions-and-billing). If you don't have one, create a [free Azure account](https://azure.microsoft.com/free/) before you begin.
-   [Visual Studio Code](https://code.visualstudio.com/) installed on one of the [supported platforms](https://code.visualstudio.com/docs/supporting/requirements#_platforms) along with the [HashiCorp Terraform](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform) and the [C# Development Kit](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.csdevkit).
-   Azure CLI version 2.59.0 or later installed. To install or upgrade, see [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).
-   `aks-preview` Azure CLI extension of version `2.0.0b8` or later installed
-   [Terraform v1.9.0 or later](https://developer.hashicorp.com/terraform/downloads).
-   The deployment must be started by a user who has sufficient permissions to assign roles, such as a `User Access Administrator` or `Owner`.
-   Your Azure account also needs `Microsoft.Resources/deployments/write` permissions at the subscription level.
-   During deployment, the script will create an application registrations on Microsoft Entra ID. Please verify that your user account has the necessary privileges.

## Infrastructure as Code - IaC

The Kaito-RAG solution provides Terraform scripts to deploy the infrastructure on your Azure subcriotion. Please revire the variables (and parameters) configuration before deployment to ensure that the default values suit your needs and requirements.

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.

Any use of third-party trademarks or logos are subject to those third-party's policies.
