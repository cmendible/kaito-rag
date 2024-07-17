output "name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Specifies the name of the AKS cluster."
}

output "id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "Specifies the resource id of the AKS cluster."
}

output "tags" {
  value       = azurerm_kubernetes_cluster.aks.tags
  description = "Specifies the tags of the AKS cluster."
}

output "aks_identity_principal_id" {
  value       = azurerm_user_assigned_identity.aks_identity.principal_id
  description = "Specifies the principal id of the managed identity of the AKS cluster."
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  description = "Specifies the object id of the kubelet identity of the AKS cluster."
}

output "kube_config_raw" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  description = "Contains the Kubernetes config to be used by kubectl and other compatible tools."
}

output "private_fqdn" {
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
  description = "The FQDN for the Kubernetes Cluster when private link has been enabled, which is only resolvable inside the Virtual Network used by the Kubernetes Cluster."
}

output "node_resource_group" {
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
  description = "Specifies the resource id of the auto-generated Resource Group which contains the resources for this Managed Kubernetes Cluster."
}

output "oidc_issuer_url" {
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  description = "Specifies the URL of the OpenID Connect issuer used by this Kubernetes Cluster."
}

output "admin_client_certificate" {
  description = "The client_certificate in the azurerm_kubernetes_cluster's kube_admin_config block.  Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate, "")
}

output "admin_client_key" {
  description = "The client_key in the azurerm_kubernetes_cluster's kube_admin_config block. Base64 encoded private key used by clients to authenticate to the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key, "")
}

output "admin_cluster_ca_certificate" {
  description = "The cluster_ca_certificate in the azurerm_kubernetes_cluster's kube_admin_config block. Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate, "")
}

output "host" {
  description = "The host in the azurerm_kubernetes_cluster's kube_admin_config block. The Kubernetes cluster server host."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].host, "")
}

output "username" {
  description = "The username in the azurerm_kubernetes_cluster's kube_admin_config block. A username used to authenticate to the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].username, "")
}

output "password" {
  description = "The password in the azurerm_kubernetes_cluster's kube_admin_config block. A password or token used to authenticate to the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].password, "")
}

output "client_certificate" {
  description = "The client_certificate in the azurerm_kubernetes_cluster's kube_admin_config block.  Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate, "")
}

output "client_key" {
  description = "The client_key in the azurerm_kubernetes_cluster's kube_admin_config block. Base64 encoded private key used by clients to authenticate to the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key, "")
}

output "cluster_ca_certificate" {
  description = "The cluster_ca_certificate in the azurerm_kubernetes_cluster's kube_admin_config block. Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster."
  sensitive   = true
  value       = try(azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate, "")
}

output "aks_workload_managed_identity_client_id" {
  value = azurerm_user_assigned_identity.aks_workload_identity.client_id
}

output "aks_workload_managed_identity_id" {
  value = azurerm_user_assigned_identity.aks_workload_identity.id
}

# output "user_node_pool_name" {
#   description = "Specifies the name of the node pool"
#   value       = azurerm_kubernetes_cluster_node_pool.user_node_pool.name
# }

# output "user_node_pool_id" {
#   description = "Specifies the resource id of the node pool"
#   value       = azurerm_kubernetes_cluster_node_pool.user_node_pool.id
# }

# output "user_node_pool_tags" {
#   description = "Specifies the tags of the node pool"
#   value       = azurerm_kubernetes_cluster_node_pool.user_node_pool.tags
# }