output "access_key_id" {
  description = "Access key ID for the Kind Image Updater IAM user"
  value       = aws_iam_access_key.kind_image_updater.id
}

output "secret_access_key" {
  description = "Secret access key for the Kind Image Updater IAM user"
  value       = aws_iam_access_key.kind_image_updater.secret
  sensitive   = true
}

output "user_name" {
  description = "Name of the Kind Image Updater IAM user"
  value       = aws_iam_user.kind_image_updater.name
}
