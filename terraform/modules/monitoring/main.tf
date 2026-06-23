resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "${var.prefix}-appi"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_monitor_action_group" "critical" {
  name                = "${var.prefix}-critical-ag"
  resource_group_name = var.resource_group_name
  short_name          = "critical"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.alert_email_addresses
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }
}

resource "azurerm_monitor_metric_alert" "aks_cpu" {
  name                = "${var.prefix}-aks-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = var.aks_cluster_ids
  description         = "AKS node CPU > 85% for 5 minutes"
  severity            = 2
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action { action_group_id = azurerm_monitor_action_group.critical.id }
}
