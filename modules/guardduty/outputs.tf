output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "guardduty_account_id" {
  description = "GuardDuty account ID"
  value       = aws_guardduty_detector.main.account_id
}