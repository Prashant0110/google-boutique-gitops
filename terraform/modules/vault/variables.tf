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