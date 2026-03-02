output "cloudtrail_log_group_name" {
  description = "CloudWatch log group name for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudtrail_log_group_arn" {
  description = "CloudWatch log group ARN for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}