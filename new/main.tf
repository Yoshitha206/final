terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.20.0"
    }
  }

  cloud {
    hostname = "app.terraform.io"
    organization = "yoshi1"
    workspaces {
      name = "new1_workspace"
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
delegation {
    name = "sql-mi-delegation"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
    }
  }
}

resource "azurerm_subnet" "subnet3" {
  provider             = azurerm.subscription1
  name                 = "subnet3"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_service_plan" "app_plan" {
  provider            = azurerm.subscription1
  name                = "yoshithaappserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type             = "Windows"  # Specify "Windows" or "Linux" based on your needs
  sku_name            = "S1"       # Specify the SKU name directly
  #sku_tier            = "Standard" # Specify the SKU tier
  maximum_elastic_worker_count = 1
}

resource "azurerm_windows_web_app" "appservice_app" {
  provider            = azurerm.subscription1
  name                = "yoshi-webapp"  # Ensure this name is unique
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_plan.id  # Correct reference

  site_config {
    always_on = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

resource "azurerm_mssql_managed_instance" "sql_mi" {
  provider                    = azurerm.subscription1
  name                        = "example-sqlmi"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  subnet_id                   = azurerm_subnet.subnet2.id
  administrator_login         = "sqladmin"
  administrator_login_password = "P@ssw0rd!"
  sku_name                    = "GP_Gen5"
  storage_size_in_gb          = 32
  license_type                = "LicenseIncluded"
  vcores                      = 1
}

resource "azurerm_private_endpoint" "pe_webapp" {
  provider            = azurerm.subscription1
  name                = "pe-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet3.id

  private_service_connection {
    name                           = "webapp-psc"
    private_connection_resource_id = azurerm_windows_web_app.appservice_app.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}

resource "azurerm_private_endpoint" "pe_sqlmi" {
  provider            = azurerm.subscription1
  name                = "pe-sqlmi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet3.id

  private_service_connection {
    name                           = "sqlmi-psc"
    private_connection_resource_id = azurerm_mssql_managed_instance.sql_mi.id
    is_manual_connection           = false
    subresource_names              = ["sqlManagedInstance"]
  }
}

