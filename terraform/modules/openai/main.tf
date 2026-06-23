resource "azurerm_cognitive_account" "main" {
  name                          = "${var.prefix}-aoai"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.sku_name
  public_network_access_enabled = false
  custom_subdomain_name         = "${var.prefix}-aoai"
  tags                          = var.tags

  identity { type = "SystemAssigned" }

  network_acls {
    default_action = "Deny"
    ip_rules       = var.allowed_ips
  }
}

resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.main.id
  sku { name = "Standard"; capacity = var.gpt4o_capacity }
  model { format = "OpenAI"; name = "gpt-4o"; version = "2024-08-06" }
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-3-large"
  cognitive_account_id = azurerm_cognitive_account.main.id
  sku { name = "Standard"; capacity = var.embedding_capacity }
  model { format = "OpenAI"; name = "text-embedding-3-large"; version = "1" }
  version_upgrade_option = "OnceNewDefaultVersionAvailable"
  depends_on = [azurerm_cognitive_deployment.gpt4o]
}

resource "azurerm_private_endpoint" "openai" {
  name                = "${var.prefix}-aoai-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-aoai-psc"
    private_connection_resource_id = azurerm_cognitive_account.main.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "aoai-dns-group"
    private_dns_zone_ids = [var.openai_dns_zone_id]
  }
}
