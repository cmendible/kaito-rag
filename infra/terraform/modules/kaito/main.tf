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

// Gets the User Assigned Identity of the AKS cluster associated with the AI Toolchain Operator
data "azurerm_user_assigned_identity" "kaito_user_assigned_identity" {
  name                = var.kaito_identity_name
  resource_group_name = var.aks_node_resource_group_name

  depends_on = [azapi_update_resource.enable_kaito]
}

resource "azurerm_federated_identity_credential" "kaito_federated_identity_credential" {
  name                = "id-federated-kaito"
  resource_group_name = var.aks_node_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = data.azurerm_user_assigned_identity.kaito_user_assigned_identity.id
  subject             = "system:serviceaccount:kube-system:kaito-gpu-provisioner"

  depends_on = [
    azapi_update_resource.enable_kaito,
    data.azurerm_user_assigned_identity.kaito_user_assigned_identity
  ]
}

resource "azurerm_role_assignment" "kaito_identity_contributor_assignment" {
  scope                            = var.resource_group_id
  role_definition_name             = "Contributor"
  principal_id                     = data.azurerm_user_assigned_identity.kaito_user_assigned_identity.principal_id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_federated_identity_credential.kaito_federated_identity_credential
  ]
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.kaito_aks_namespace
  }
}

resource "kubectl_manifest" "kaito_service_account" {
  yaml_body = <<-EOF
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${var.kaito_service_account_name}
      namespace: ${var.kaito_aks_namespace}
      annotations:
        azure.workload.identity/client-id: ${var.ask_workload_managed_identity_client_id}
        azure.workload.identity/tenant-id: ${var.tenant_id}
      labels:
        azure.workload.identity/use: "true"
    EOF

  depends_on = [kubernetes_namespace.namespace]
}

resource "kubectl_manifest" "kaito_workspace_mistral_7b_instruct" {
  yaml_body = <<-EOF
    apiVersion: kaito.sh/v1alpha1
    kind: Workspace
    metadata:
      name: workspace-mistral-7b-instruct
      namespace: ${var.kaito_aks_namespace}
      annotations:
        kaito.sh/enablelb: "False"
    resource:
      count: 1
      instanceType: "${var.kaito_instance_type_vm_size}"
      labelSelector:
        matchLabels:
          apps: mistral-7b-instruct
    inference:
      preset:
        name: "mistral-7b-instruct"
    EOF

  depends_on = [
    azurerm_federated_identity_credential.kaito_federated_identity_credential,
    kubectl_manifest.kaito_service_account
  ]
}

# # resource "kubectl_manifest" "ingress_kaito_workspace_mistral_7b_instruct" {
# #   yaml_body = <<-EOF
# #     apiVersion: networking.k8s.io/v1
# #     kind: Ingress
# #     metadata:
# #       name: kaito-mistral-7b-instruct
# #       annotations:
# #         cert-manager.io/cluster-issuer: letsencrypt-nginx
# #         cert-manager.io/acme-challenge-type: http01 
# #         nginx.ingress.kubernetes.io/affinity: "cookie"
# #         nginx.ingress.kubernetes.io/proxy-connect-timeout: "600"
# #         nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
# #         nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
# #         nginx.ingress.kubernetes.io/upstream-keepalive-timeout: "600"
# #         nginx.ingress.kubernetes.io/keep-alive: "600"
# #         nginx.ingress.kubernetes.io/proxy-buffering: "off"
# #         nginx.ingress.kubernetes.io/enable-cors: "true"
# #         nginx.ingress.kubernetes.io/cors-allow-origin: "*"
# #         nginx.ingress.kubernetes.io/cors-allow-credentials: "false"
# #     spec:
# #       ingressClassName: nginx
# #       tls:
# #       - hosts:
# #         - kaito-mistral-7b-instruct.${var.dns_zone_name}
# #         secretName: kaito-mistral-7b-instruct-tls
# #       rules:
# #       - host: kaito-mistral-7b-instruct.${var.dns_zone_name}
# #         http:
# #           paths:
# #           - path: /
# #             pathType: Prefix
# #             backend:
# #               service:
# #                 name: workspace-mistral-7b-instruct
# #                 port:
# #                   number: 80
# #     EOF

# #   depends_on = [
# #     kubectl_manifest.kaito_workspace_mistral_7b_instruct
# #   ]
# # }


resource "azurerm_federated_identity_credential" "workload_federated_identity_credential" {
  name                = "id-federated-kaito-workload-${var.kaito_aks_namespace}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = var.ask_workload_managed_identity_id
  subject             = "system:serviceaccount:${var.kaito_aks_namespace}:${var.kaito_service_account_name}"
}
