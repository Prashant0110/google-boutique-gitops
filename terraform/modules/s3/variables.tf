variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "bucket_suffix" {
  type        = string
  description = "Unique suffix used to create a globally unique S3 bucket name."
}