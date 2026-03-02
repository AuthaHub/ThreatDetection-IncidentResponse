# EventBridge rule for GuardDuty findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "Capture GuardDuty findings for automated response"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7] }]
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-guardduty-findings"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Trigger isolate EC2 Lambda on high severity findings
resource "aws_cloudwatch_event_target" "isolate_ec2" {
  rule = aws_cloudwatch_event_rule.guardduty_findings.name
  arn  = var.isolate_ec2_lambda_arn
}

# Trigger snapshot EBS Lambda on high severity findings
resource "aws_cloudwatch_event_target" "snapshot_ebs" {
  rule = aws_cloudwatch_event_rule.guardduty_findings.name
  arn  = var.snapshot_ebs_lambda_arn
}

# Trigger log event Lambda on high severity findings
resource "aws_cloudwatch_event_target" "log_event" {
  rule = aws_cloudwatch_event_rule.guardduty_findings.name
  arn  = var.log_event_lambda_arn
}

# Lambda permissions for EventBridge
resource "aws_lambda_permission" "isolate_ec2" {
  statement_id  = "AllowEventBridgeIsolateEC2"
  action        = "lambda:InvokeFunction"
  function_name = var.isolate_ec2_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

resource "aws_lambda_permission" "snapshot_ebs" {
  statement_id  = "AllowEventBridgeSnapshotEBS"
  action        = "lambda:InvokeFunction"
  function_name = var.snapshot_ebs_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

resource "aws_lambda_permission" "log_event" {
  statement_id  = "AllowEventBridgeLogEvent"
  action        = "lambda:InvokeFunction"
  function_name = var.log_event_lambda_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}