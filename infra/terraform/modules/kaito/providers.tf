terraform {
  required_version = ">= 1.4.6"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.14.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14.0"
    }
    # kubectl = {
    #   source  = "alekc/kubectl"
    #   version = "~>2.0"
    # }

  }
}
