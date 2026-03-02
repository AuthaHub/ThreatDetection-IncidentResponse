variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications"
  type        = string
}

variable "cloudtrail_log_group_name" {
  description = "CloudWatch log group name for CloudTrail logs"
  type        = string
}