variable "user_name" {
  description = "IAM user name for the Kind Image Updater"
  type        = string
}

variable "environment" {
  description = "Environment associated with the IAM user"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the Image Updater can read"
  type        = string
}
