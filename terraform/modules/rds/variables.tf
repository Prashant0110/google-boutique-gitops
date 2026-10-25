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

variable "backup_retention_period" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when destroying the database."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance."
  type        = bool
  default     = true
}
variable "multi_az" {
  description = "Deploy RDS as a Multi-AZ DB instance for availability."
  type        = bool
  default     = false
}
