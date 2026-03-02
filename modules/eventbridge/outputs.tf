output "guardduty_event_rule_arn" {
  description = "GuardDuty EventBridge rule ARN"
  value       = aws_cloudwatch_event_rule.guardduty_findings.arn
}

output "guardduty_event_rule_name" {
  description = "GuardDuty EventBridge rule name"
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
}