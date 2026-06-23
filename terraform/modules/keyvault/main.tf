data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                          = "${var.prefix}-kv"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "premium"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  tags                          = var.tags
}

resource "azurerm_private_endpoint" "kv" {
  name                = "${var.prefix}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-group"
    private_dns_zone_ids = [var.kv_dns_zone_id]
  }
}

# RBAC role assignments
resource "azurerm_role_assignment" "admin" {
  for_each             = toset(var.admin_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "readers" {
  for_each             = toset(var.reader_principal_ids)
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

# Platform secrets
resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-api-key"
  value        = var.openai_api_key
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "search_key" {
  name         = "search-api-key"
  value        = var.search_api_key
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
  tags         = var.tags
}
