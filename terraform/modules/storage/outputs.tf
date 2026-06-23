output "id"                  { value = azurerm_storage_account.main.id }
output "name"                { value = azurerm_storage_account.main.name }
output "primary_blob_endpoint" { value = azurerm_storage_account.main.primary_blob_endpoint }
output "documents_container" { value = azurerm_storage_container.documents.name }
output "principal_id"        { value = azurerm_storage_account.main.identity[0].principal_id }
