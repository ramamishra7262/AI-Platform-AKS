variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "pe_subnet_id" { type = string }
variable "kv_dns_zone_id" { type = string }
variable "admin_principal_ids" { type = list(string); default = [] }
variable "reader_principal_ids" { type = list(string); default = [] }
variable "openai_api_key" { type = string; sensitive = true; default = "" }
variable "search_api_key" { type = string; sensitive = true; default = "" }
variable "tags" { type = map(string) }
