# S3 Bucket Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for ETL pipeline"
  value       = aws_s3_bucket.etl_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.etl_bucket.arn
}

output "source_data_path" {
  description = "S3 path for source data"
  value       = "s3://${aws_s3_bucket.etl_bucket.id}/source/"
}

output "destination_data_path" {
  description = "S3 path for transformed data"
  value       = "s3://${aws_s3_bucket.etl_bucket.id}/destination/"
}

# Glue Database Outputs
output "glue_database_name" {
  description = "Name of the Glue Data Catalog database"
  value       = aws_glue_catalog_database.etl_database.name
}

# Glue Crawler Outputs
output "glue_source_crawler_name" {
  description = "Name of the source Glue crawler"
  value       = aws_glue_crawler.source_crawler.name
}

output "glue_destination_crawler_name" {
  description = "Name of the destination Glue crawler"
  value       = aws_glue_crawler.destination_crawler.name
}

# Glue Job Outputs
output "glue_job_name" {
  description = "Name of the Glue ETL job"
  value       = aws_glue_job.etl_job.name
}

# IAM Role Outputs
output "glue_role_arn" {
  description = "ARN of the Glue service IAM role"
  value       = aws_iam_role.glue_role.arn
}

# Console URLs
output "glue_console_url" {
  description = "AWS Console URL for Glue Jobs"
  value       = "https://${var.aws_region}.console.aws.amazon.com/glue/home?region=${var.aws_region}#/v2/etl-jobs"
}

output "s3_console_url" {
  description = "AWS Console URL for S3 bucket"
  value       = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.etl_bucket.id}"
}

# Lambda Function Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function that triggers destination crawler"
  value       = aws_lambda_function.trigger_destination_crawler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.trigger_destination_crawler.arn
}

# EventBridge Outputs
output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for Glue job completion"
  value       = aws_cloudwatch_event_rule.glue_job_completion.name
}

output "lambda_logs_url" {
  description = "CloudWatch Logs URL for Lambda function"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/$252Faws$252Flambda$252F${aws_lambda_function.trigger_destination_crawler.function_name}"
}

# Step Functions Outputs
output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.etl_pipeline.arn
}

output "step_functions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.etl_pipeline.name
}

