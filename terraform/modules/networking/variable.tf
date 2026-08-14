variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
}

variable "public_subnet_1_az" {
  description = "Availability zone for public subnet 1"
  type        = string
}

variable "public_subnet_2_az" {
  description = "Availability zone for public subnet 2"
  type        = string
}

variable "private_subnet_1_az" {
  description = "Availability zone for private subnet 1"
  type        = string
}

variable "private_subnet_2_az" {
  description = "Availability zone for private subnet 2"
  type        = string
}

variable "project" {
  description = "Project name used for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name used for resource tagging"
  type        = string
}