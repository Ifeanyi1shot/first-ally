provider "azurerm" {
  features {}
}

variable "subscription_id" {
  description = "Azure Subscription ID"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# App Service Plan 
resource "azurerm_app_service_plan" "main" {
  name                = "AppServicePlan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "Basic"
    size = "B1"
  }
}

# Backend App Service
resource "azurerm_app_service" "backend" {
  name                = "backend-app-service"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "AZURE_SQL_CONNECTION"     = azurerm_sql_server.main.connection_string
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }
}

# Frontend App Service
resource "azurerm_app_service" "frontend" {
  name                = "frontend-app-service"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

# Azure SQL Database
resource "azurerm_sql_server" "main" {
  name                         = "backend-sql-server"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  administrator_login          = "adminuser"
  administrator_login_password = azurerm_key_vault_secret.sql_password.value
  version                      = "12.0"
}

resource "azurerm_sql_database" "main" {
  name                = "backend-sql-database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = azurerm_sql_server.main.name
  sku_name            = "Basic"
}

# Virtual Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "AppVNet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "backend" {
  name                 = "BackendSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Private Endpoint for Backend SQL
resource "azurerm_private_endpoint" "sql_endpoint" {
  name                = "sql-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.backend.id
  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_sql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

# Private DNS Zone for SQL
resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_a_record" "sql_record" {
  name                = azurerm_sql_server.main.name
  zone_name           = azurerm_private_dns_zone.sql_dns.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql_endpoint.private_ip_address]
}

# Networking Security Groups for Frontend
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "FrontendNSG"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "AppKeyVault"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = var.sql_password 
  key_vault_id = azurerm_key_vault.main.id
}

# User Assigned Identity
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "AppIdentity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Key Vault Access Policy
resource "azurerm_key_vault_access_policy" "app_policy" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_identity.principal_id

  secret_permissions = ["get"]
}
