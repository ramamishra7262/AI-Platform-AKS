variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "pe_subnet_id" { type = string }
variable "search_dns_zone_id" { type = string }
variable "sku" { type = string; default = "standard" }
variable "replica_count" { type = number; default = 1 }
variable "partition_count" { type = number; default = 1 }
variable "contributor_principal_ids" { type = list(string); default = [] }
variable "tags" { type = map(string) }
