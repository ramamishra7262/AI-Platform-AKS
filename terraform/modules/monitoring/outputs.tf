output "law_id"                       { value = azurerm_log_analytics_workspace.main.id }
output "law_workspace_id"             { value = azurerm_log_analytics_workspace.main.workspace_id }
output "appi_connection_string"        { value = azurerm_application_insights.main.connection_string; sensitive = true }
output "appi_instrumentation_key"     { value = azurerm_application_insights.main.instrumentation_key; sensitive = true }
