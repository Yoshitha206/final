#output "sql_mi_id" {
 # value = azurerm_mssql_managed_instance.sql_mi.id
#}

output "app_service_id" {
  value = azurerm_windows_web_app.appservice_app.id
}
output "sql_server_id" {
  value = azurerm_sql_server.sql_server.id
}

output "sql_database_id" {
  value = azurerm_sql_database.sql_database.id
}
