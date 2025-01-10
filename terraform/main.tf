provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  description = "Azure Resource Group Name"
}

variable "location" {
  description = "Azure Region"
}

variable "sql_password" {
  description = "SQL Administrator Password"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# App Service Plan with Autoscaling
resource "azurerm_app_service_plan" "main" {
  name                = "AppServicePlan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "Standard"
    size = "S1"
  }
  dynamic "site_config" {
    for_each = local.autoscale_settings
    content {
      min_instance_count = site_config.value.min_instance_count
      max_instance_count = site_config.value.max_instance_count
      target_cpu_percentage = site_config.value.target_cpu_percentage
    }
  }
}

locals {
  autoscale_settings = {
    default = {
      min_instance_count    = 1
      max_instance_count    = 3
      target_cpu_percentage = 70
    }
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

# Azure SQL Server and Database
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
  extended_auditing_policy {
    storage_account_access_key = azurerm_storage_account.main.primary_access_key
    storage_endpoint           = azurerm_storage_account.main.primary_blob_endpoint
  }
}

# Backup and Recovery for SQL Database
resource "azurerm_backup_protected_vm" "sql_backup" {
  backup_policy_id    = azurerm_backup_policy_vm.main.id
  source_vm_id        = azurerm_virtual_machine.main.id
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  resource_group_name = azurerm_resource_group.main.name
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

# Load Balancer
resource "azurerm_lb" "main" {
  name                = "AppLoadBalancer"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_public_ip" "main" {
  name                = "PublicIP"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
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
