variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for Macie scanning"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for Macie scanning"
  type        = string
}