variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "project" {
  description = "Project name used for naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name used for naming and tagging"
  type        = string
}
