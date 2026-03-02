output "athena_workgroup_name" {
  description = "Athena workgroup name"
  value       = aws_athena_workgroup.main.name
}

output "athena_results_bucket" {
  description = "Athena results S3 bucket"
  value       = aws_s3_bucket.athena_results.bucket
}

output "glue_database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.cloudtrail.name
}