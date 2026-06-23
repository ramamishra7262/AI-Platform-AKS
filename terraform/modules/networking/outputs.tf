output "vnet_id"              { value = azurerm_virtual_network.main.id }
output "vnet_name"            { value = azurerm_virtual_network.main.name }
output "aks_subnet_id"        { value = azurerm_subnet.aks.id }
output "pe_subnet_id"         { value = azurerm_subnet.private_endpoints.id }
output "appgw_subnet_id"      { value = azurerm_subnet.appgw.id }
output "private_dns_zone_ids" { value = { for k, v in azurerm_private_dns_zone.zones : k => v.id } }
