terraform {
  backend "remote" {
    organization = "<your_organization_name>"
    workspaces {
      name = "<your_workspace_name>"
    }
  }
}

provider "azurerm" {
  features {}

  alias = "subscription1"
  subscription_id = var.subscription1_id
  client_id       = var.subscription1_client_id
  client_secret   = var.subscription1_client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  provider = azurerm.subscription1
  name     = "rg-subscription1"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet1" {
  provider            = azurerm.subscription1
  name                = "vnet1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  provider             = azurerm.subscription1
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  provider             = azurerm.subscription1
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "subnet3" {
  provider             = azurerm.subscription1
  name                 = "subnet3"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_app_service_plan" "example_plan" {
  provider            = azurerm.subscription1
  name                = "example-appserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "example_app" {
  provider            = azurerm.subscription1
  name                = "example-appservice"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.example_plan.id

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_sql_managed_instance" "example_sql_mi" {
  provider                    = azurerm.subscription1
  name                        = "example-sqlmi"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  subnet_id                   = azurerm_subnet.subnet2.id
  administrator_login         = "sqladmin"
  administrator_login_password = "P@ssw0rd!"
  sku_name                    = "GP_Gen5_2"
  storage_size_in_gb          = 32
   license_type                = "LicenseIncluded"
   vcores                      = 4

}

resource "azurerm_private_endpoint" "example_pe_webapp" {
  provider            = azurerm.subscription1
  name                = "example-pe-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet3.id

  private_service_connection {
    name                           = "example-webapp-psc"
    private_connection_resource_id = azurerm_app_service.example_app.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}

resource "azurerm_private_endpoint" "example_pe_sqlmi" {
  provider            = azurerm.subscription1
  name                = "example-pe-sqlmi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet3.id

  private_service_connection {
    name                           = "example-sqlmi-psc"
    private_connection_resource_id = azurerm_sql_managed_instance.example_sql_mi.id
    is_manual_connection           = false
    subresource_names              = ["sqlManagedInstance"]
  }
}
