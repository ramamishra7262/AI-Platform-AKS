resource "azurerm_user_assigned_identity" "main" {
  for_each            = toset(var.identity_names)
  name                = "${var.prefix}-${each.value}-mi"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Federated credentials for AKS Workload Identity
resource "azurerm_federated_identity_credential" "workload" {
  for_each            = var.federated_credentials
  name                = "${var.prefix}-${each.key}-fedcred"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.main[each.value.identity_name].id
  subject             = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}
