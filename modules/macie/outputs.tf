output "macie_account_id" {
  description = "Macie account ID"
  value       = aws_macie2_account.main.id
}

output "macie_job_id" {
  description = "Macie classification job ID"
  value       = aws_macie2_classification_job.main.id
}