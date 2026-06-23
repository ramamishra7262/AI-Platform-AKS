output "resource_group_name"    { value = azurerm_resource_group.main.name }
output "aks_cluster_name"       { value = module.aks.cluster_name }
output "acr_login_server"       { value = module.acr.login_server }
output "keyvault_name"          { value = module.keyvault.name }
output "keyvault_uri"           { value = module.keyvault.uri }
output "openai_endpoint"        { value = module.openai.endpoint }
output "search_endpoint"        { value = module.ai_search.endpoint }
output "storage_account_name"   { value = module.storage.name }
output "law_id"                 { value = module.monitoring.law_id }
output "appi_connection_string" { value = module.monitoring.appi_connection_string; sensitive = true }
