
variable "project" {
  description = "Project name used for resource naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev, staging, or prod."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the launch template."
  type        = string
  default     = "t3.micro"
}

variable "security_group_ids" {
  description = "Security groups attached to frontend instances."
  type        = list(string)
}

variable "instance_profile_name" {
  description = "IAM instance profile attached to frontend instances."
  type        = string
}

variable "user_data" {
  description = "Base64-encoded EC2 user-data script."
  type        = string
  sensitive   = true
}

variable "root_volume_size" {
  description = "Encrypted root EBS volume size in GiB."
  type        = number
  default     = 8
}

variable "subnet_ids" {
  description = "Private subnet IDs used by the Auto Scaling Group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two private subnet IDs for multi-AZ placement."
  }
}

variable "target_group_arns" {
  description = "ALB target group ARNs associated with the Auto Scaling Group."
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of frontend instances."
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Initial desired number of frontend instances."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of frontend instances."
  type        = number
  default     = 4
}

variable "target_cpu_utilization" {
  description = "Target average CPU utilization percentage for Auto Scaling."
  type        = number
  default     = 60

  validation {
    condition     = var.target_cpu_utilization > 0 && var.target_cpu_utilization <= 100
    error_message = "Target CPU utilization must be greater than 0 and no more than 100."
  }
}
