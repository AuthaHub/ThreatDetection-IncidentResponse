variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for event logging"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
}