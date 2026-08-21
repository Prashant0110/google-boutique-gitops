variable "vpc_id" {
  description = "VPC where the RDS database will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs used by the RDS DB subnet group."
  type        = list(string)
}

variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev or prod."
  type        = string
}

variable "db_name" {
  description = "Initial database name created by RDS."
  type        = string
}

variable "username" {
  description = "Initial RDS master username."
  type        = string
}

variable "password" {
  description = "Initial RDS master password."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect to MySQL on port 3306."
  type        = list(string)
  default     = []
}
