resource "vault_policy" "application" {
  for_each = var.services

  name = each.value.policy_name

  policy = <<-EOT
    path "secret/data/${each.value.secret_path}" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "application" {
  for_each = var.services

  backend   = "kubernetes"
  role_name = each.value.role_name

  bound_service_account_names = [
    each.value.service_account
  ]

  bound_service_account_namespaces = [
    var.namespace
  ]

  token_policies = [
    vault_policy.application[each.key].name
  ]

  token_ttl = var.token_ttl
}