output "audit_bucket_arn" {
  value = aws_s3_bucket.audit.arn
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "kms_key_arn" {
  value = aws_kms_key.audit.arn
}