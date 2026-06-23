variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "kubernetes_version" { type = string }
variable "aks_subnet_id" { type = string }
variable "system_node_count" { type = number; default = 3 }
variable "system_node_vm_size" { type = string; default = "Standard_D4s_v5" }
variable "user_node_count" { type = number; default = 2 }
variable "user_node_vm_size" { type = string; default = "Standard_D8s_v5" }
variable "user_node_max_count" { type = number; default = 10 }
variable "log_analytics_workspace_id" { type = string }
variable "cluster_identity_id" { type = string }
variable "kubelet_identity_id" { type = string }
variable "kubelet_identity_client_id" { type = string }
variable "kubelet_identity_object_id" { type = string }
variable "tags" { type = map(string) }
