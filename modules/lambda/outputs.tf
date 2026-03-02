output "isolate_ec2_arn" {
  description = "Isolate EC2 Lambda function ARN"
  value       = aws_lambda_function.isolate_ec2.arn
}

output "snapshot_ebs_arn" {
  description = "Snapshot EBS Lambda function ARN"
  value       = aws_lambda_function.snapshot_ebs.arn
}

output "log_event_arn" {
  description = "Log event Lambda function ARN"
  value       = aws_lambda_function.log_event.arn
}