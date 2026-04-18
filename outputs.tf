output "app_public_ip" {
  value = azurerm_public_ip.app.ip_address
}

output "db_host" {
  value = azurerm_mysql_flexible_server.main.fqdn
}