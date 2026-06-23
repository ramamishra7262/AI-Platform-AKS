resource "azurerm_container_registry" "main" {
  name                          = replace("${var.prefix}acr", "-", "")
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  zone_redundancy_enabled       = var.zone_redundancy
  tags                          = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  georeplications {
    location                  = var.geo_replication_location
    zone_redundancy_enabled   = false
    regional_endpoint_enabled = true
  }
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${var.prefix}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.main.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-group"
    private_dns_zone_ids = [var.acr_dns_zone_id]
  }
}

resource "azurerm_role_assignment" "aks_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_principal_id
}
