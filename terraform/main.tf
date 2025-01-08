provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "AppResourceGroup"
  location = "East US"
}

# App Service Plan
resource "azurerm_app_service_plan" "main" {
  name                = "AppServicePlan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Backend App Service
resource "azurerm_app_service" "backend" {
  name                = "backend-app-service"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
}

# Frontend App Service
resource "azurerm_app_service" "frontend" {
  name                = "frontend-app-service"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
}

# Storage Account for Monitoring
resource "azurerm_storage_account" "monitoring" {
  name                     = "monitoringstorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Networking Configuration (VPC, Subnets, and Load Balancer)

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "AppVNet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet Definitions
resource "azurerm_subnet" "frontend" {
  name                 = "FrontendSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "BackendSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group (NSG) for frontend
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "FrontendNSG"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowPublicHTTPS"
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

# Load Balancer for Backend
resource "azurerm_lb" "backend_lb" {
  name                = "BackendLoadBalancer"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "FrontendIPConfig"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.backend_lb.id
  name            = "BackendPool"
}

# Load Balancer Rule for Backend
resource "azurerm_lb_rule" "backend_rule" {
  loadbalancer_id                 = azurerm_lb.backend_lb.id
  name                            = "BackendRule"
  protocol                        = "Tcp"
  frontend_port                   = 443
  backend_port                    = 443
  frontend_ip_configuration_name  = "FrontendIPConfig"  # Use the name defined in the frontend_ip_configuration block
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
}




# Output the URLs of the App Services
output "backend_app_service_url" {
  value = azurerm_app_service.backend.default_site_hostname
}

output "frontend_app_service_url" {
  value = azurerm_app_service.frontend.default_site_hostname
}
