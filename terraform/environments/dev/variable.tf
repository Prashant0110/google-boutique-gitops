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