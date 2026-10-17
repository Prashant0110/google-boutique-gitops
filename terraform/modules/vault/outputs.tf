
output "kv_mount_path" {
  description = "Path of the static application KV v2 mount."
  value       = vault_mount.kv.path
}

output "audit_device_path" {
  description = "Path of the configured Vault audit device."
  value       = vault_audit.audit.path
}

output "kubernetes_auth_path" {
  description = "Path of the Kubernetes authentication backend."
  value       = vault_auth_backend.kubernetes.path
}

output "policies" {
  description = "Vault policies created for application services."

  value = {
    for service, policy in vault_policy.application :
    service => policy.name
  }
}

output "kubernetes_roles" {
  description = "Vault Kubernetes roles created for application services."

  value = {
    for service, role in vault_kubernetes_auth_backend_role.application :
    service => role.role_name
  }
}

output "database_mount_path" {
  description = "Dynamic database secrets mount; null when disabled."

  value = try(vault_mount.database[0].path, null)
}

output "database_role_name" {
  description = "Dynamic database role; null when disabled."

  value = try(vault_database_secret_backend_role.application[0].name, null)
}
