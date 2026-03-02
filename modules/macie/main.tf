# Macie - Automated PII and sensitive data discovery
resource "aws_macie2_account" "main" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

resource "aws_macie2_classification_job" "main" {
  name       = "${var.project_name}-${var.environment}-macie-scan"
  job_type   = "SCHEDULED"
  job_status = "RUNNING"

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [var.s3_bucket_id]
    }
  }

  schedule_frequency {
    daily_schedule = true
  }

  depends_on = [aws_macie2_account.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-macie-scan"
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_caller_identity" "current" {}