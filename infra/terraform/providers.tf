terraform {
  required_version = ">= 1.4.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.112.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.14.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.31.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = false
  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
    resource_group {
      # This flag is set to mitigate an open bug in Terraform.
      # For instance, the Resource Group is not deleted when a `Failure Anomalies` resource is present.
      # As soon as this is fixed, we should remove this.
      # Reference: https://github.com/hashicorp/terraform-provider-azurerm/issues/18026
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

provider "azuread" {}

provider "kubernetes" {
  host                   = module.aks.host
  username               = module.aks.username
  password               = module.aks.password
  client_key             = base64decode(module.aks.client_key)
  client_certificate     = base64decode(module.aks.client_certificate)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = module.aks.host
  username               = module.aks.username
  password               = module.aks.password
  client_key             = base64decode(module.aks.client_key)
  client_certificate     = base64decode(module.aks.client_certificate)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}
