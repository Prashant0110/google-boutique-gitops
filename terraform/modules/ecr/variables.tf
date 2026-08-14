variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "environment" {
  description = "Environment associated with the repository"
  type        = string
}

variable "project" {
  description = "Project name used for resource tagging"
  type        = string
}
