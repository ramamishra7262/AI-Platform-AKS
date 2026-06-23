variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "identity_names" { type = list(string) }
variable "aks_oidc_issuer_url" { type = string; default = "" }
variable "federated_credentials" {
  type = map(object({ identity_name = string; namespace = string; service_account = string }))
  default = {}
}
variable "tags" { type = map(string) }
