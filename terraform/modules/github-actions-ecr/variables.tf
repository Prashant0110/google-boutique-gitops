variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the role"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository that GitHub Actions can push to"
  type        = string
}

variable "role_name" {
  description = "Name of the GitHub Actions IAM role"
  type        = string
}

variable "policy_name" {
  description = "Name of the GitHub Actions ECR policy"
  type        = string
}
