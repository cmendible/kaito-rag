terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.15.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14.0"
    }
  }
}
