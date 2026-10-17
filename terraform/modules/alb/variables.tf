
variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev, staging, or prod."
  type        = string
}

variable "vpc_id" {
  description = "VPC where the ALB target group is deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs where the internet-facing ALB is deployed."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs for the ALB."
  }
}

variable "security_group_id" {
  description = "Security group attached to the ALB."
  type        = string
}

variable "target_port" {
  description = "Port where the frontend application receives traffic."
  type        = number
  default     = 80

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "The target port must be between 1 and 65535."
  }
}

variable "listener_port" {
  description = "Port where the ALB listens for HTTP client traffic."
  type        = number
  default     = 80

  validation {
    condition     = var.listener_port >= 1 && var.listener_port <= 65535
    error_message = "The listener port must be between 1 and 65535."
  }
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target health check."
  type        = string
  default     = "/"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Empty disables the HTTPS listener."
  type        = string
  default     = ""
}
