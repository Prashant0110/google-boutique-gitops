variable "namespace" {
  description = "Kubernetes namespace containing the application ServiceAccounts."
  type        = string
}

variable "services" {
  description = "Application services requiring Vault Kubernetes authentication."
  type = map(object({
    service_account = string
    secret_path     = string
    policy_name     = string
    role_name       = string
  }))
}

variable "token_ttl" {
  description = "TTL in seconds for Vault Kubernetes authentication tokens."
  type        = number
  default     = 3600
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
    default_ttl         = 3600
    max_ttl             = 7200
    creation_statements = []
  }

  sensitive = true
}