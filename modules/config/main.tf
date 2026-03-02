# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-config-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# AWS Config recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# AWS Config delivery channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-delivery"
  s3_bucket_name = aws_s3_bucket.config.id

  sns_topic_arn = var.sns_topic_arn

  depends_on = [aws_config_configuration_recorder.main]
}

# S3 bucket for Config snapshots
resource "aws_s3_bucket" "config" {
  bucket        = "${var.project_name}-${var.environment}-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-config"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket                  = aws_s3_bucket.config.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Enable Config recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# Config rule - Check for unrestricted SSH
resource "aws_config_config_rule" "restricted_ssh" {
  name = "${var.project_name}-${var.environment}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({
    blockedPort1 = "22"
  })

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-restricted-ssh"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Config rule - Check for unrestricted RDP
resource "aws_config_config_rule" "restricted_rdp" {
  name = "${var.project_name}-${var.environment}-restricted-rdp"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  input_parameters = jsonencode({
    blockedPort1 = "3389"
  })

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-restricted-rdp"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Config rule - Check S3 bucket public access
resource "aws_config_config_rule" "s3_public_access" {
  name = "${var.project_name}-${var.environment}-s3-public-access"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-s3-public-access"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Config rule - Check CloudTrail enabled
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "${var.project_name}-${var.environment}-cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudtrail-enabled"
    Environment = var.environment
    Project     = var.project_name
  }
}

data "aws_caller_identity" "current" {}