# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:ModifyInstanceAttribute",
          "ec2:CreateSnapshot",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

# Zip Lambda function code
data "archive_file" "isolate_ec2" {
  type        = "zip"
  source_file = "${path.module}/functions/isolate_ec2.py"
  output_path = "${path.module}/functions/isolate_ec2.zip"
}

data "archive_file" "snapshot_ebs" {
  type        = "zip"
  source_file = "${path.module}/functions/snapshot_ebs.py"
  output_path = "${path.module}/functions/snapshot_ebs.zip"
}

data "archive_file" "log_event" {
  type        = "zip"
  source_file = "${path.module}/functions/log_event.py"
  output_path = "${path.module}/functions/log_event.zip"
}

# Lambda - Isolate compromised EC2
resource "aws_lambda_function" "isolate_ec2" {
  filename         = data.archive_file.isolate_ec2.output_path
  function_name    = "${var.project_name}-${var.environment}-isolate-ec2"
  role             = aws_iam_role.lambda_role.arn
  handler          = "isolate_ec2.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.isolate_ec2.output_base64sha256

  tags = {
    Name        = "${var.project_name}-${var.environment}-isolate-ec2"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda - Snapshot EBS for forensics
resource "aws_lambda_function" "snapshot_ebs" {
  filename         = data.archive_file.snapshot_ebs.output_path
  function_name    = "${var.project_name}-${var.environment}-snapshot-ebs"
  role             = aws_iam_role.lambda_role.arn
  handler          = "snapshot_ebs.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.snapshot_ebs.output_base64sha256

  tags = {
    Name        = "${var.project_name}-${var.environment}-snapshot-ebs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Lambda - Log event to DynamoDB
resource "aws_lambda_function" "log_event" {
  filename         = data.archive_file.log_event.output_path
  function_name    = "${var.project_name}-${var.environment}-log-event"
  role             = aws_iam_role.lambda_role.arn
  handler          = "log_event.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.log_event.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-log-event"
    Environment = var.environment
    Project     = var.project_name
  }
}