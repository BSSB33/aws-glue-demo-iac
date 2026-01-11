# Package Lambda function code
data "archive_file" "lambda_trigger_crawler" {
  type        = "zip"
  source_file = "${path.module}/lambda/trigger_destination_crawler.py"
  output_path = "${path.module}/.terraform/lambda_trigger_crawler.zip"
}

# Lambda Function: Auto-trigger Destination Crawler
resource "aws_lambda_function" "trigger_destination_crawler" {
  filename         = data.archive_file.lambda_trigger_crawler.output_path
  function_name    = "${var.project_name}-trigger-destination-crawler"
  role             = aws_iam_role.lambda_trigger_crawler_role.arn
  handler          = "trigger_destination_crawler.lambda_handler"
  source_code_hash = data.archive_file.lambda_trigger_crawler.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60
  description      = "Auto-triggers destination crawler when Glue job completes"

  environment {
    variables = {
      DESTINATION_CRAWLER_NAME = aws_glue_crawler.destination_crawler.name
    }
  }

  tags = {
    Name = "${var.project_name}-trigger-destination-crawler"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_trigger_crawler_logs" {
  name              = "/aws/lambda/${aws_lambda_function.trigger_destination_crawler.function_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-lambda-logs"
  }
}
