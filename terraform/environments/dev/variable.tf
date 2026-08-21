variable "aws_region" {
  description = "AWS region for the environment"
  type        = string
  default     = "us-west-2"
}

variable "vault_address" {
  description = "Address of the Vault server."
  type        = string
  default     = "http://127.0.0.1:8200"
}

variable "rds_username" {
  description = "Initial master username for the development RDS instance."
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "Initial master password for the development RDS instance."
  type        = string
  sensitive   = true
}