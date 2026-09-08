terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "backend-rg-donot-delete"
    storage_account_name = "pipelinestg001"
    container_name       = "pipcontainer"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
