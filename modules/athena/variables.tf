variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cloudtrail_bucket_id" {
  description = "S3 bucket ID containing CloudTrail logs"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for Athena encryption"
  type        = string
}