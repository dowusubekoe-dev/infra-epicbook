variable "rg_name" {
  description = "Resource group name"
  type        = string
  default     = "epicbook-rg"
}

variable "vnet_cidr" {
  description = "VNet CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_subnet_cidr" {
  description = "App subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "db_subnet_cidr" {
  description = "DB subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "azureuser"
}

variable "db_name" {
  description = "Database name"
}

variable "db_admin_user" {
  description = "Admin username for MySQL"
  type        = string
  default     = "azuredbadmin"
}

variable "db_password" {
  description = "Admin password for MySQL"
  sensitive   = true
}

variable "db_zone" {
  description = "Database SKU zone"
  type = number
  default = 3
}

variable "ssh_public_key" {
  type = string
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "epicbook-dob"

}

variable "vm_size" {
  type    = string
  default = "Standard_B2ats_v2"
}

variable "location" {
  type    = string
  default = "westeurope"

  validation {
    condition = contains([
      "westeurope"
    ], var.location)

    error_message = "Only westeurope is allowed in this environment."
  }
}