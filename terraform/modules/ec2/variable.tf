variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet where the EC2 instance will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to the EC2 instance"
  type        = list(string)
}

variable "user_data" {
  description = "EC2 initialization script content"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile attached to the EC2 instance"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
}

variable "project" {
  description = "Project name used for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name used for resource tagging"
  type        = string
}