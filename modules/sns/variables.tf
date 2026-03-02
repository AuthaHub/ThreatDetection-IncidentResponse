variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alert_email" {
  description = "Email address for security alerts"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for SNS encryption"
  type        = string
}