output "policies" {
  description = "Vault policies created for application services."

  value = {
    for service, policy in vault_policy.application :
    service => policy.name
  }
}

output "kubernetes_roles" {
  description = "Vault Kubernetes authentication roles created for application services."

  value = {
    for service, role in vault_kubernetes_auth_backend_role.application :
    service => role.role_name
  }
}