module "recovery" {
  source = "../../modules/recovery"

  project            = "google-boutique"
  environment        = "dev"
  bucket_name_prefix = "google-boutique-dev-recovery"

  retention_days            = 90
  noncurrent_retention_days = 30

  # Keep empty for local KinD testing.
  # Set both values only for the approved EKS cluster's real OIDC provider.
  eks_oidc_provider_arn = ""
  eks_oidc_provider_url = ""

  backup_service_account_namespace = "retrieval"
  backup_service_account_name      = "qdrant-backup"
}

output "recovery_bucket_name" {
  description = "S3 bucket for Qdrant recovery snapshots."
  value       = module.recovery.bucket_name
}

output "recovery_kms_key_arn" {
  description = "KMS key encrypting recovery snapshots."
  value       = module.recovery.kms_key_arn
}

output "recovery_backup_policy_arn" {
  description = "Least-privilege recovery workload policy."
  value       = module.recovery.backup_policy_arn
}

output "recovery_irsa_role_arn" {
  description = "Dedicated EKS backup role ARN, or null until OIDC is configured."
  value       = module.recovery.irsa_role_arn
}
