variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "pe_subnet_id" { type = string }
variable "acr_dns_zone_id" { type = string }
variable "managed_identity_id" { type = string }
variable "aks_kubelet_principal_id" { type = string }
variable "geo_replication_location" { type = string; default = "westus" }
variable "zone_redundancy" { type = bool; default = false }
variable "tags" { type = map(string) }
