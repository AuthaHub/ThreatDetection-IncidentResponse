output "kms_key_arn" {
  description = "KMS key ARN"
  value       = module.kms.kms_key_arn
}

output "cloudtrail_bucket_id" {
  description = "CloudTrail S3 bucket ID"
  value       = module.s3.cloudtrail_bucket_id
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = module.cloudtrail.cloudtrail_arn
}