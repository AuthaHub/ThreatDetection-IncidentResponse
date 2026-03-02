variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for GuardDuty findings export"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for GuardDuty findings encryption"
  type        = string
}