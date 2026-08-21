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

resource "vault_mount" "database" {
  count = var.database.enabled ? 1 : 0

  path = var.database.mount_path
  type = "database"
}

resource "vault_database_secret_backend_connection" "mysql" {
  count = var.database.enabled ? 1 : 0

  backend       = vault_mount.database[0].path
  name          = var.database.connection_name
  allowed_roles = [var.database.dynamic_role_name]

  mysql {
    connection_url = "mysql://{{username}}:{{password}}@${var.database.address}:${var.database.port}/${var.database.database_name}"

    username = var.database.admin_username
    password = var.database.admin_password
  }
}

resource "vault_database_secret_backend_role" "application" {
  count = var.database.enabled ? 1 : 0

  backend = vault_mount.database[0].path
  name    = var.database.dynamic_role_name
  db_name = vault_database_secret_backend_connection.mysql[0].name

  creation_statements = var.database.creation_statements

  default_ttl = var.database.default_ttl
  max_ttl     = var.database.max_ttl
}

resource "vault_policy" "database_application" {
  count = var.database.enabled ? 1 : 0

  name = "${var.database.dynamic_role_name}-policy"

  policy = <<-EOT
    path "${var.database.mount_path}/creds/${var.database.dynamic_role_name}" {
      capabilities = ["read"]
    }
  EOT
}