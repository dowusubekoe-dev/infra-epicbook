output "app_public_ip" {
  value = azurerm_public_ip.app.ip_address
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.main.fqdn
}