terraform {
  required_version = ">= 0.11.10"
  backend "azurerm" {}
}

provider "azurerm" {
  version = "1.29.0"
}

provider "local" {
  version = "1.2.2"
}
