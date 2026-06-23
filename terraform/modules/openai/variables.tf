variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "pe_subnet_id" { type = string }
variable "openai_dns_zone_id" { type = string }
variable "sku_name" { type = string; default = "S0" }
variable "gpt4o_capacity" { type = number; default = 30 }
variable "embedding_capacity" { type = number; default = 30 }
variable "allowed_ips" { type = list(string); default = [] }
variable "tags" { type = map(string) }
