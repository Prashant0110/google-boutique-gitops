
variable "namespace" {
  description = "Kubernetes namespace containing application ServiceAccounts."
  type        = string
}

variable "services" {
  description = "Application services and their Vault identities."
  type = map(object({
    service_account = string
    secret_path     = string
    policy_name     = string
    role_name       = string
  }))
}

variable "token_ttl" {
  description = "TTL in seconds for Vault tokens issued through Kubernetes auth."
  type        = number
  default     = 2400
}

variable "kubernetes_host" {
  description = "Kubernetes API address reachable from the Vault server."
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "audit_file_path" {
  description = "Vault audit output destination. Use stdout for the local lab."
  type        = string
  default     = "stdout"
}

variable "kv_secrets" {
  description = "Optional static KV v2 secrets keyed by secret path."
  type        = map(map(string))
  default     = {}
  sensitive   = true
}

variable "database" {
  description = "Optional dynamic database credential configuration."

  type = object({
    enabled             = bool
    mount_path          = string
    connection_name     = string
    address             = string
    port                = number
    database_name       = string
    admin_username      = string
    admin_password      = string
    dynamic_role_name   = string
    default_ttl         = number
    max_ttl             = number
    creation_statements = list(string)
  })

  default = {
    enabled             = false
    mount_path          = "database"
    connection_name     = "rds-mysql"
    address             = ""
    port                = 3306
    database_name       = ""
    admin_username      = ""
    admin_password      = ""
    dynamic_role_name   = "paymentservice-db"
    default_ttl         = 2400
    max_ttl             = 7200
    creation_statements = []
  }

  sensitive = true
}
