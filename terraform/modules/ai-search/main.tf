resource "azurerm_search_service" "main" {
  name                          = "${var.prefix}-search"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  replica_count                 = var.replica_count
  partition_count               = var.partition_count
  public_network_access_enabled = false
  local_authentication_enabled  = false
  semantic_search_sku           = "free"
  tags                          = var.tags

  identity { type = "SystemAssigned" }
}

resource "azurerm_private_endpoint" "search" {
  name                = "${var.prefix}-search-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-search-psc"
    private_connection_resource_id = azurerm_search_service.main.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "search-dns-group"
    private_dns_zone_ids = [var.search_dns_zone_id]
  }
}

resource "azurerm_role_assignment" "search_contributor" {
  for_each             = toset(var.contributor_principal_ids)
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Service Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  for_each             = toset(var.contributor_principal_ids)
  scope                = azurerm_search_service.main.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = each.value
}
