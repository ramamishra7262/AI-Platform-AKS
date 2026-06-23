output "identities" {
  value = { for k, v in azurerm_user_assigned_identity.main : k => {
    id           = v.id
    principal_id = v.principal_id
    client_id    = v.client_id
  }}
}
