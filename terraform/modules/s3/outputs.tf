output "bucket_name" {
  value = aws_s3_bucket.application.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.application.arn
}

output "kms_key_arn" {
  value = aws_kms_key.application.arn
}