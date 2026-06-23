variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "log_retention_days" { type = number; default = 90 }
variable "alert_email_addresses" { type = list(string); default = [] }
variable "aks_cluster_ids" { type = list(string); default = [] }
variable "tags" { type = map(string) }
