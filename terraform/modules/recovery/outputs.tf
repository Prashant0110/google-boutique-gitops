output "bucket_name" {
  description = "S3 bucket used for recovery snapshots."
  value       = aws_s3_bucket.recovery.bucket
}

output "bucket_arn" {
  description = "ARN of the recovery bucket."
  value       = aws_s3_bucket.recovery.arn
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt recovery snapshots."
  value       = aws_kms_key.recovery.arn
}

output "backup_policy_arn" {
  description = "IAM policy ARN for the recovery workload."
  value       = aws_iam_policy.backup.arn
}

output "irsa_role_arn" {
  description = "EKS IRSA role ARN, or null when no OIDC inputs are provided."
  value       = try(aws_iam_role.backup[0].arn, null)
}
