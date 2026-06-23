variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "environment" { type = string }
variable "pe_subnet_id" { type = string }
variable "storage_dns_zone_id" { type = string }
variable "tags" { type = map(string) }
