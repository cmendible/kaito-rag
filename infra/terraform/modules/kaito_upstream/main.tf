data "azurerm_subscription" "current" {
}

resource "azurerm_role_assignment" "kaito_provisioner_assigned_identity_contributor_role" {
  principal_id         = data.azurerm_user_assigned_identity.kaito_identity.principal_id
  scope                = var.aks_id
  role_definition_name = "Contributor"
}

resource "kubernetes_namespace" "kaito_namespace" {
  metadata {
    name = var.kaito_aks_namespace
  }
}

resource "azapi_update_resource" "enable_kaito" {
  count       = var.use_upstream_version ? 0 : 1
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

  depends_on = [azapi_update_resource.enable_kaito]
}

resource "azurerm_federated_identity_credential" "kaito_federated_identity_credential" {
  name                = "id-federated-kaito"
  resource_group_name = data.azurerm_user_assigned_identity.kaito_identity.resource_group_name
  parent_id           = data.azurerm_user_assigned_identity.kaito_identity.id
  issuer              = var.aks_oidc_issuer_url
  audience            = ["api://AzureADTokenExchange"]
  subject             = var.use_upstream_version ? "system:serviceaccount:gpu-provisioner:gpu-provisioner" : "system:serviceaccount:kube-system:kaito-gpu-provisioner"
}

resource "helm_release" "kaito_workspace" {
  count            = var.use_upstream_version ? 1 : 0
  name             = "kaito-workspace"
  chart            = "${path.module}/charts/kaito/workspace/"
  namespace        = kubernetes_namespace.kaito_namespace.metadata.0.name
  create_namespace = false
}

resource "helm_release" "gpu_provisioner" {
  count = var.use_upstream_version ? 1 : 0
  name  = "kaito-gpu-provisioner"
  chart = "https://github.com/Azure/gpu-provisioner/raw/gh-pages/charts/gpu-provisioner-${var.gpu_provisioner_version}.tgz"
  wait  = true

  set {
    name  = "settings.azure.clusterName"
    value = var.aks_name
  }

  set {
    name  = "replicas"
    value = var.gpu_provisioner_replicas
  }

  set {
    name  = "controller.env[0].name"
    value = "ARM_SUBSCRIPTION_ID"
  }
  set {
    name  = "controller.env[0].value"
    value = data.azurerm_subscription.current.subscription_id
  }

  set {
    name  = "controller.env[1].name"
    value = "LOCATION"
  }
  set {
    name  = "controller.env[1].value"
    value = var.aks_location
  }

  set {
    name  = "controller.env[2].name"
    value = "AZURE_CLUSTER_NAME"
  }
  set {
    name  = "controller.env[2].value"
    value = var.aks_name
  }

  set {
    name  = "controller.env[3].name"
    value = "AZURE_NODE_RESOURCE_GROUP"
  }
  set {
    name  = "controller.env[3].value"
    value = var.aks_node_resource_group_name
  }

  set {
    name  = "controller.env[4].name"
    value = "ARM_RESOURCE_GROUP"
  }
  set {
    name  = "controller.env[4].value"
    value = var.resource_group_name
  }

  set {
    name  = "controller.env[5].name"
    value = "LEADER_ELECT"
  }
  set {
    name  = "controller.env[5].value"
    value = "false"
    type  = "string" # Forcefully set the type as `string` to avoid the error: `…cannot unmarshal bool into Go struct field EnvVar.spec.template.spec.containers.env.value of type string…`
  }

  set {
    name  = "controller.env[6].name"
    value = "E2E_TEST_MODE"
  }
  set {
    name  = "controller.env[6].value"
    value = "false"
    type  = "string" # Forcefully set the type as `string` to avoid the error: `…cannot unmarshal bool into Go struct field EnvVar.spec.template.spec.containers.env.value of type string…`
  }

  set {
    name  = "workloadIdentity.clientId"
    value = data.azurerm_user_assigned_identity.kaito_identity.client_id
  }

  set {
    name  = "workloadIdentity.tenantId"
    value = data.azurerm_user_assigned_identity.kaito_identity.tenant_id
  }
}

resource "kubectl_manifest" "kaito_ai_model" {
  yaml_body = <<-EOF
    apiVersion: kaito.sh/v1alpha1
    kind: Workspace
    metadata:
      name: kaito-${var.kaito_ai_model}
      namespace: ${kubernetes_namespace.kaito_namespace.metadata.0.name}
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
    azapi_update_resource.enable_kaito,
    helm_release.kaito_workspace,
    helm_release.gpu_provisioner
  ]
}

resource "azurerm_network_security_rule" "kaito_ai_model_inference_network_security_rule" {
  name                        = "rule-${var.kaito_aks_namespace}-${var.kaito_inference_port}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 80
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = var.network_security_group_name
}

resource "kubernetes_ingress_v1" "kaito_ai_model_inference_endpoint_ingress" {
  wait_for_load_balancer = true

  metadata {
    name      = "ingress-kaito-${var.kaito_ai_model}"
    namespace = kubernetes_namespace.kaito_namespace.metadata.0.name
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
}
