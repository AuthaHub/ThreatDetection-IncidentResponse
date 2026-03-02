output "security_events_table_name" {
  description = "DynamoDB security events table name"
  value       = aws_dynamodb_table.security_events.name
}

output "security_events_table_arn" {
  description = "DynamoDB security events table ARN"
  value       = aws_dynamodb_table.security_events.arn
}