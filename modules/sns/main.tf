# SNS Topic for security alerts
resource "aws_sns_topic" "security_alerts" {
  name              = "${var.project_name}-${var.environment}-security-alerts"
  kms_master_key_id = var.kms_key_arn

  tags = {
    Name        = "${var.project_name}-${var.environment}-security-alerts"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Email subscription for security alerts
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}