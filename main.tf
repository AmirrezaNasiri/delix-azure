terraform {
  required_providers  {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.79.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.6.3"

}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  skip_provider_registration = "true"

  # Connection to Azure
  subscription_id = var.azure_subscription_id
  client_id = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id = var.azure_tenant_id
}

locals {
  tags = {workspace = "${terraform.workspace}", env = var.env}
}

resource "azurerm_resource_group" "main" {
  name = "delix"
  location = "West Europe"
  tags = local.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                        = "delix-keyvault"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "random_password" "core-mysql-password" {
  length           = 32
  special          = true
}

resource "azurerm_key_vault_secret" "core-mysql-password" {
  name         = "core-mysql-password"
  value        = random_password.core-mysql-password.result
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_mysql_server" "core-mysql-server" {
  name                = "core-mysql-server"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  administrator_login          = "delix-admin"
  administrator_login_password = random_password.core-mysql-password.result

  sku_name   = "B_Gen4_1"
  storage_mb = 5120
  version    = "8.0"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = true
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"

  # TODO: threat_detection_policy
}

resource "azurerm_mysql_database" "example" {
  name                = "core-mysql-database"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_server.core-mysql-server.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_general_ci"
}

