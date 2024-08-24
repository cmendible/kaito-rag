resource "azapi_update_resource" "enable_kaito" {
  type        = "Microsoft.ContainerService/managedClusters@2024-03-02-preview"
  resource_id = var.aks_id

  body = jsonencode({
    properties = {
      aiToolchainOperatorProfile = {
        enabled = true
      }
    }
  })
}

data "azurerm_user_assigned_identity" "kaito_identity" {
  name                = var.kaito_identity_name
  resource_group_name = var.kaito_identity_resource_group_name
}

# # // Gets the User Assigned Identity of the AKS cluster associated with the AI Toolchain Operator
# # data "azurerm_user_assigned_identity" "kaito_user_assigned_identity" {
# #   name                = var.kaito_identity_name
# #   resource_group_name = var.aks_node_resource_group_name
# # }

resource "azurerm_federated_identity_credential" "kaito_federated_identity_credential" {
  name                = "id-federated-kaito"
  resource_group_name = var.aks_node_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = data.azurerm_user_assigned_identity.kaito_user_assigned_identity.id
  subject             = "system:serviceaccount:kube-system:kaito-gpu-provisioner"
}

resource "azurerm_federated_identity_credential" "workload_federated_identity_credential" {
  name                = "id-federated-kaito-workload-${var.kaito_aks_namespace}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = var.ask_workload_managed_identity_id
  subject             = "system:serviceaccount:${var.kaito_aks_namespace}:${var.kaito_service_account_name}"
}

# # resource "azurerm_role_assignment" "kaito_identity_contributor_assignment" {
# #   scope                            = var.resource_group_id
# #   role_definition_name             = "Contributor"
# #   principal_id                     = data.azurerm_user_assigned_identity.kaito_user_assigned_identity.principal_id
# #   skip_service_principal_aad_check = true

# #   depends_on = [
# #     azurerm_federated_identity_credential.kaito_federated_identity_credential
# #   ]
# # }

resource "kubernetes_namespace_v1" "kaito_namespace" {
  metadata {
    name = var.kaito_aks_namespace
  }
}

# # resource "kubectl_manifest" "kaito_service_account" {
# #   yaml_body = <<-EOF
# #     apiVersion: v1
# #     kind: ServiceAccount
# #     metadata:
# #       name: ${var.kaito_service_account_name}
# #       namespace: ${var.kaito_aks_namespace}
# #       annotations:
# #         azure.workload.identity/client-id: ${var.ask_workload_managed_identity_client_id}
# #         azure.workload.identity/tenant-id: ${var.tenant_id}
# #       labels:
# #         azure.workload.identity/use: "true"
# #     EOF

# #   depends_on = [kubernetes_namespace.namespace]
# # }

resource "kubectl_manifest" "kaito_ai_model_workspace" {
  yaml_body = <<-EOF
    apiVersion: kaito.sh/v1alpha1
    kind: Workspace
    metadata:
      name: kaito-${var.kaito_ai_model}
      namespace: ${var.kaito_aks_namespace}
      annotations:
        kaito.sh/enablelb: "False"
    resource:
      count: 1
      instanceType: "${var.kaito_instance_type_vm_size}"
      labelSelector:
        matchLabels:
          apps: ${var.kaito_ai_model}
    inference:
      preset:
        name: "${var.kaito_ai_model}"
    EOF

  depends_on = [
    helm_release.gpu_provisioner,
    kubernetes_namespace_v1.kaito-namespace
  ]
}

resource "kubernetes_ingress_v1" "kaito_ai_model_inference_endpoint_ingress" {
  wait_for_load_balancer = true

  metadata {
    name      = "ingress-kaito-${var.kaito_ai_model}"
    namespace = var.kaito_aks_namespace
    annotations = {
      "kubernetes.io/ingress.class" = "addon-http-application-routing"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/chat"
          path_type = "Prefix"
          backend {
            service {
              name = "kaito-${var.kaito_ai_model}"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  # depends_on = [kubernetes_namespace_v1.kaito_namespace] # Forcefully wait for the namespace to be created before creating the ingress...
}


