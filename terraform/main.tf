data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  log_retention_days  = var.environment == "prod" ? 365 : 90
  alert_email_addresses = []
  aks_cluster_ids    = [module.aks.cluster_id]
  tags               = local.common_tags
}

module "networking" {
  source              = "./modules/networking"
  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  aks_subnet_cidr     = var.aks_subnet_cidr
  pe_subnet_cidr      = var.pe_subnet_cidr
  appgw_subnet_cidr   = var.appgw_subnet_cidr
  tags                = local.common_tags
}

module "managed_identity" {
  source              = "./modules/managed-identity"
  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  identity_names      = ["aks-cluster", "aks-kubelet", "backend", "rag", "ingestion"]
  aks_oidc_issuer_url = module.aks.oidc_issuer_url
  federated_credentials = {
    backend   = { identity_name = "backend",   namespace = "genai", service_account = "backend-sa" }
    rag       = { identity_name = "rag",       namespace = "genai", service_account = "rag-sa" }
    ingestion = { identity_name = "ingestion", namespace = "genai", service_account = "ingestion-sa" }
  }
  tags = local.common_tags
  depends_on = [module.aks]
}

module "aks" {
  source                     = "./modules/aks"
  prefix                     = local.prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  kubernetes_version         = var.kubernetes_version
  aks_subnet_id              = module.networking.aks_subnet_id
  system_node_count          = var.system_node_count
  system_node_vm_size        = var.system_node_vm_size
  user_node_count            = var.user_node_count
  user_node_vm_size          = var.user_node_vm_size
  user_node_max_count        = var.user_node_max_count
  log_analytics_workspace_id = module.monitoring.law_id
  cluster_identity_id        = module.managed_identity.identities["aks-cluster"].id
  kubelet_identity_id        = module.managed_identity.identities["aks-kubelet"].id
  kubelet_identity_client_id = module.managed_identity.identities["aks-kubelet"].client_id
  kubelet_identity_object_id = module.managed_identity.identities["aks-kubelet"].principal_id
  tags                       = local.common_tags
  depends_on                 = [module.networking, module.monitoring]
}

module "acr" {
  source                   = "./modules/acr"
  prefix                   = local.prefix
  location                 = var.location
  resource_group_name      = azurerm_resource_group.main.name
  pe_subnet_id             = module.networking.pe_subnet_id
  acr_dns_zone_id          = module.networking.private_dns_zone_ids["privatelink.azurecr.io"]
  managed_identity_id      = module.managed_identity.identities["aks-cluster"].id
  aks_kubelet_principal_id = module.aks.kubelet_principal_id
  tags                     = local.common_tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  pe_subnet_id        = module.networking.pe_subnet_id
  kv_dns_zone_id      = module.networking.private_dns_zone_ids["privatelink.vaultcore.azure.net"]
  admin_principal_ids = [data.azurerm_client_config.current.object_id]
  reader_principal_ids = [
    module.managed_identity.identities["backend"].principal_id,
    module.managed_identity.identities["rag"].principal_id,
    module.managed_identity.identities["ingestion"].principal_id,
  ]
  openai_api_key = module.openai.primary_key
  search_api_key = module.ai_search.primary_key
  tags           = local.common_tags
  depends_on     = [module.openai, module.ai_search]
}

module "openai" {
  source             = "./modules/openai"
  prefix             = local.prefix
  location           = var.location
  resource_group_name = azurerm_resource_group.main.name
  pe_subnet_id       = module.networking.pe_subnet_id
  openai_dns_zone_id = module.networking.private_dns_zone_ids["privatelink.openai.azure.com"]
  sku_name           = var.openai_sku
  gpt4o_capacity     = var.gpt4o_capacity
  embedding_capacity = var.embedding_capacity
  tags               = local.common_tags
}

module "ai_search" {
  source              = "./modules/ai-search"
  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  pe_subnet_id        = module.networking.pe_subnet_id
  search_dns_zone_id  = module.networking.private_dns_zone_ids["privatelink.search.windows.net"]
  sku                 = var.search_sku
  contributor_principal_ids = [
    module.managed_identity.identities["rag"].principal_id,
    module.managed_identity.identities["ingestion"].principal_id,
  ]
  tags = local.common_tags
}

module "storage" {
  source              = "./modules/storage"
  prefix              = local.prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  environment         = var.environment
  pe_subnet_id        = module.networking.pe_subnet_id
  storage_dns_zone_id = module.networking.private_dns_zone_ids["privatelink.blob.core.windows.net"]
  tags                = local.common_tags
}
