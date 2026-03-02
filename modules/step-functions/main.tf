# IAM role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-${var.environment}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-sfn-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-${var.environment}-sfn-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [
          var.isolate_ec2_lambda_arn,
          var.snapshot_ebs_lambda_arn,
          var.log_event_lambda_arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Step Functions state machine for incident response
resource "aws_sfn_state_machine" "incident_response" {
  name     = "${var.project_name}-${var.environment}-incident-response"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Automated incident response workflow"
    StartAt = "IsolateEC2"
    States = {
      IsolateEC2 = {
        Type     = "Task"
        Resource = var.isolate_ec2_lambda_arn
        Next     = "SnapshotEBS"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
        }]
      }
      SnapshotEBS = {
        Type     = "Task"
        Resource = var.snapshot_ebs_lambda_arn
        Next     = "LogEvent"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
        }]
      }
      LogEvent = {
        Type     = "Task"
        Resource = var.log_event_lambda_arn
        Next     = "NotifySuccess"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "NotifyFailure"
        }]
      }
      NotifySuccess = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message  = "Incident response completed successfully"
        }
        End = true
      }
      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message  = "Incident response workflow failed"
        }
        End = true
      }
    }
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-incident-response"
    Environment = var.environment
    Project     = var.project_name
  }
}

