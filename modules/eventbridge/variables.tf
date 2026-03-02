variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "isolate_ec2_lambda_arn" {
  description = "ARN of the isolate EC2 Lambda function"
  type        = string
}

variable "snapshot_ebs_lambda_arn" {
  description = "ARN of the snapshot EBS Lambda function"
  type        = string
}

variable "log_event_lambda_arn" {
  description = "ARN of the log event Lambda function"
  type        = string
}