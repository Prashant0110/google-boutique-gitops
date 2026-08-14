variable "project" {
  description = "Project name used for IAM resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name used for IAM resource naming and tagging"
  type        = string
}

variable "ssm_policy_arn" {
  description = "ARN of the IAM policy attached to the EC2 SSM role"
  type        = string
}

variable "ecr_read_policy_arn" {
  description = "ARN of the IAM policy allowing the EC2 instance to pull images from ECR"
  type        = string
}
