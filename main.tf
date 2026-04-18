terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.69"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "azurerm" {
  features {}
}

############################
# RANDOM SUFFIX
############################
resource "random_string" "mysql_suffix" {
  length  = 6
  upper   = false
  special = false
}

############################
# RESOURCE GROUP
############################
resource "azurerm_resource_group" "rg" {
  name     = "epicbook-rg"
  location = var.location
}

############################
# VIRTUAL NETWORK
############################
resource "azurerm_virtual_network" "vnet" {
  name                = "epicbook-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

############################
# APP SUBNET
############################
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

############################
# DB SUBNET (MYSQL DELEGATED)
############################
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "mysql-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

############################
# NSG
############################
resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

############################
# NSG ASSOCIATION (FIXED)
############################
resource "azurerm_subnet_network_security_group_association" "web_nsa" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

############################
# PUBLIC IP
############################
resource "azurerm_public_ip" "app" {
  name                = "app-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

############################
# NIC
############################
resource "azurerm_network_interface" "app_nic" {
  name                = "app-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app.id
  }
}

############################
# MYSQL PRIVATE DNS
############################
resource "azurerm_private_dns_zone" "mysql_dns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

############################
# LINUX VM (APP)
############################
resource "azurerm_linux_virtual_machine" "app_vm" {
  name                = "epicbook-app-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.app_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

############################
# MYSQL FLEXIBLE SERVER (FIXED VERSION)
############################
resource "azurerm_mysql_flexible_server" "main" {
  name                = "epicbook-mysql-${random_string.mysql_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  administrator_login    = var.db_admin_user
  administrator_password = var.db_admin_password

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"

  zone = "3"

  delegated_subnet_id = azurerm_subnet.db_subnet.id
  private_dns_zone_id = azurerm_private_dns_zone.mysql_dns.id

  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql_dns_link
  ]
}

############################
# MYSQL DATABASE
############################
resource "azurerm_mysql_flexible_database" "db" {
  name                = "epicbookdb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}