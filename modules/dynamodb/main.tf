# DynamoDB table for security event audit trail
resource "aws_dynamodb_table" "security_events" {
  name         = "${var.project_name}-${var.environment}-security-events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  range_key    = "timestamp"

  attribute {
    name = "event_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-security-events"
    Environment = var.environment
    Project     = var.project_name
  }
}