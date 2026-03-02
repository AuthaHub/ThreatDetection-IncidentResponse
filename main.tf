# Project 03 - Automated Threat Detection & Incident Response Pipeline

module "kms" {
  source       = "./modules/kms"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.kms_key_arn
}

module "cloudtrail" {
  source       = "./modules/cloudtrail"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  kms_key_arn  = module.kms.kms_key_arn
  s3_bucket_id = module.s3.cloudtrail_bucket_id
}

module "guardduty" {
  source        = "./modules/guardduty"
  project_name  = var.project_name
  environment   = var.environment
  s3_bucket_arn = module.s3.cloudtrail_bucket_arn
  kms_key_arn   = module.kms.kms_key_arn
}

module "macie" {
  source        = "./modules/macie"
  project_name  = var.project_name
  environment   = var.environment
  s3_bucket_arn = module.s3.cloudtrail_bucket_arn
  s3_bucket_id  = module.s3.cloudtrail_bucket_id
}

module "security_hub" {
  source       = "./modules/security-hub"
  project_name = var.project_name
  environment  = var.environment
}

module "sns" {
  source       = "./modules/sns"
  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email
  kms_key_arn  = module.kms.kms_key_arn
}

module "cloudwatch" {
  source                    = "./modules/cloudwatch"
  project_name              = var.project_name
  environment               = var.environment
  sns_topic_arn             = module.sns.security_alerts_topic_arn
  cloudtrail_log_group_name = "/aws/cloudtrail/${var.project_name}-${var.environment}"
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source              = "./modules/lambda"
  project_name        = var.project_name
  environment         = var.environment
  sns_topic_arn       = module.sns.security_alerts_topic_arn
  dynamodb_table_name = module.dynamodb.security_events_table_name
  kms_key_arn         = module.kms.kms_key_arn
}

module "eventbridge" {
  source                  = "./modules/eventbridge"
  project_name            = var.project_name
  environment             = var.environment
  isolate_ec2_lambda_arn  = module.lambda.isolate_ec2_arn
  snapshot_ebs_lambda_arn = module.lambda.snapshot_ebs_arn
  log_event_lambda_arn    = module.lambda.log_event_arn
}

module "step_functions" {
  source                  = "./modules/step-functions"
  project_name            = var.project_name
  environment             = var.environment
  isolate_ec2_lambda_arn  = module.lambda.isolate_ec2_arn
  snapshot_ebs_lambda_arn = module.lambda.snapshot_ebs_arn
  log_event_lambda_arn    = module.lambda.log_event_arn
  sns_topic_arn           = module.sns.security_alerts_topic_arn
}

module "athena" {
  source               = "./modules/athena"
  project_name         = var.project_name
  environment          = var.environment
  cloudtrail_bucket_id = module.s3.cloudtrail_bucket_id
  kms_key_arn          = module.kms.kms_key_arn
}

module "config" {
  source        = "./modules/config"
  project_name  = var.project_name
  environment   = var.environment
  sns_topic_arn = module.sns.security_alerts_topic_arn
}