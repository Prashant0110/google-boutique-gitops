
# ============================================================
# VAULT AUDIT LOGGING
# ============================================================

resource "vault_audit" "audit" {
  type        = "file"
  path        = "file"
  description = "Vault audit logging for security and operations"

  options = {
    file_path = var.audit_file_path
  }
}

# ============================================================
# KV V2 - STATIC APPLICATION SECRETS
# ============================================================

resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  description = "Static application secrets"

  options = {
    version = "2"
  }
}

resource "vault_kv_secret_v2" "application" {
  for_each = nonsensitive(toset([
    for secret_path, _ in var.kv_secrets : secret_path
  ]))

  mount = vault_mount.kv.path
  name  = each.key

  data_json = jsonencode(var.kv_secrets[each.key])
}

# ============================================================
# KUBERNETES AUTHENTICATION
# ============================================================

resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes"
  description = "Kubernetes workload authentication"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = var.kubernetes_host

  # Vault runs inside Kubernetes. Allow Vault to use its
  # mounted Kubernetes service-account token and CA.
  disable_local_ca_jwt = false
}

# ============================================================
# APPLICATION POLICIES - LEAST PRIVILEGE
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
# KUBERNETES AUTH ROLES
# ============================================================

resource "vault_kubernetes_auth_backend_role" "application" {
  for_each = var.services

  backend   = vault_auth_backend.kubernetes.path
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

  # Ensure authentication configuration exists before roles.
  depends_on = [
    vault_kubernetes_auth_backend_config.kubernetes
  ]
}

# ============================================================
# DYNAMIC DATABASE CREDENTIALS
# Disabled in the current dev environment.
# ============================================================

resource "vault_mount" "database" {
  count = var.database.enabled ? 1 : 0

  path        = var.database.mount_path
  type        = "database"
  description = "Dynamic database credentials"
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
