terraform {
  backend "azurerm" {
    resource_group_name  = "rg-pep-tfstate-dev"
    storage_account_name = "stpeptfstatedeldc"
    container_name       = "tfstate"
    key                  = "state-backend.tfstate"
    use_azuread_auth     = true
  }
}
