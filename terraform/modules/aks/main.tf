resource "azurerm_kubernetes_cluster" "main" {
  name                      = "${var.prefix}-aks"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "${var.prefix}-aks"
  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  tags                      = var.tags

  default_node_pool {
    name                        = "system"
    node_count                  = var.system_node_count
    vm_size                     = var.system_node_vm_size
    vnet_subnet_id              = var.aks_subnet_id
    only_critical_addons_enabled = true
    os_disk_size_gb             = 100
    os_disk_type                = "Ephemeral"
    temporary_name_for_rotation = "systemtemp"
    upgrade_settings { max_surge = "33%" }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.cluster_identity_id]
  }

  kubelet_identity {
    client_id                 = var.kubelet_identity_client_id
    object_id                 = var.kubelet_identity_object_id
    user_assigned_identity_id = var.kubelet_identity_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    ebpf_data_plane     = "cilium"
    dns_service_ip      = "172.16.0.10"
    service_cidr        = "172.16.0.0/16"
    outbound_type       = "userAssignedNATGateway"
  }

  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  azure_policy_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
    scale_down_delay_after_add       = "5m"
    scale_down_unneeded              = "5m"
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  lifecycle { ignore_changes = [default_node_pool[0].node_count] }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  min_count             = 2
  max_count             = var.user_node_max_count
  enable_auto_scaling   = true
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_type          = "Ephemeral"
  node_labels           = { "workload" = "genai", "node-pool" = "user" }
  tags                  = var.tags
  upgrade_settings { max_surge = "33%" }
  lifecycle { ignore_changes = [node_count] }
}
