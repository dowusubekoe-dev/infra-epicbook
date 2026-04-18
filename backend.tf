terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatedobepicbook"
    container_name       = "tfstate"
    key                  = "epicbook.tfstate"
  }
}