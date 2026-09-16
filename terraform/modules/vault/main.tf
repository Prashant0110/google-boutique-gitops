# ============================================================
# STATIC APPLICATION SECRETS - VAULT KV v2
# ============================================================

resource "vault_mount" "kv" {
  path = "secret"
  type = "kv"

  options = {
    version = "2"
  }

  description = "Static application secrets"
}

resource "vault_kv_secret_v2" "application" {
  for_each = var.kv_secrets

  mount = vault_mount.kv.path
  name  = each.key

  data_json = jsonencode(each.value)
}


# ============================================================
# APPLICATION VAULT POLICIES
# ============================================================

resource "vault_policy" "application" {
  for_each = var.services

  name = each.value.policy_name

  policy = <<-EOT
    path "secret/data/${each.value.secret_path}" {
      capabilities = ["read"]
    }
  EOT
}


# ============================================================
# KUBERNETES AUTHENTICATION ROLES
# ============================================================

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

  token_policies = concat(
    [vault_policy.application[each.key].name],
    var.database.enabled && each.key == "paymentservice"
    ? [vault_policy.database_application[0].name]
    : []
  )

  token_ttl = var.token_ttl
}


# ============================================================
# DYNAMIC DATABASE SECRETS - VAULT DATABASE SECRETS ENGINE
# ============================================================

resource "vault_mount" "database" {
  count = var.database.enabled ? 1 : 0

  path = var.database.mount_path
  type = "database"

  description = "Dynamic database credentials"
}


# ============================================================
# MYSQL DATABASE CONNECTION
# ============================================================

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


# ============================================================
# DYNAMIC DATABASE ROLE
# ============================================================

resource "vault_database_secret_backend_role" "application" {
  count = var.database.enabled ? 1 : 0

  backend = vault_mount.database[0].path
  name    = var.database.dynamic_role_name
  db_name = vault_database_secret_backend_connection.mysql[0].name

  creation_statements = var.database.creation_statements

  default_ttl = var.database.default_ttl
  max_ttl     = var.database.max_ttl
}


# ============================================================
# DATABASE SECRET POLICY
# ============================================================

resource "vault_policy" "database_application" {
  count = var.database.enabled ? 1 : 0

  name = "${var.database.dynamic_role_name}-policy"

  policy = <<-EOT
    path "${var.database.mount_path}/creds/${var.database.dynamic_role_name}" {
      capabilities = ["read"]
    }
  EOT
}
