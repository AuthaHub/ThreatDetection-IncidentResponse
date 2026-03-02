output "security_alerts_topic_arn" {
  description = "Security alerts SNS topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}

output "security_alerts_topic_name" {
  description = "Security alerts SNS topic name"
  value       = aws_sns_topic.security_alerts.name
}