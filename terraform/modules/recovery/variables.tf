variable "project" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "bucket_name_prefix" {
  description = "Globally unique S3 bucket name prefix."
  type        = string
}

variable "retention_days" {
  description = "Number of days to retain current Qdrant backup objects."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 3650
    error_message = "retention_days must be between 30 and 3650."
  }
}

variable "noncurrent_retention_days" {
  description = "Number of days to retain noncurrent object versions."
  type        = number
  default     = 30
}

variable "eks_oidc_provider_arn" {
  description = "Existing EKS OIDC provider ARN. Empty disables IRSA role creation."
  type        = string
  default     = ""
}

variable "eks_oidc_provider_url" {
  description = "Issuer URL of the same EKS OIDC provider, including https://."
  type        = string
  default     = ""
}

variable "backup_service_account_namespace" {
  description = "Kubernetes namespace of the backup service account."
  type        = string
  default     = "retrieval"
}

variable "backup_service_account_name" {
  description = "Kubernetes service account used by the backup workload."
  type        = string
  default     = "qdrant-backup"
}
