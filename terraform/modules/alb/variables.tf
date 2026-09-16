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
}

variable "security_group_id" {
  description = "Security group attached to the ALB."
  type        = string
}

variable "target_id" {
  description = "ID of the application instance registered with the target group."
  type        = string
}

variable "target_port" {
  description = "Port where the application receives traffic."
  type        = number
  default     = 80
}

variable "listener_port" {
  description = "Port where the ALB listens for client traffic."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target health check."
  type        = string
  default     = "/"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate used by the HTTPS listener."
  type        = string
  default     = ""
}