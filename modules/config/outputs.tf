output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = aws_config_configuration_recorder.main.name
}

output "config_bucket_id" {
  description = "AWS Config S3 bucket ID"
  value       = aws_s3_bucket.config.id
}