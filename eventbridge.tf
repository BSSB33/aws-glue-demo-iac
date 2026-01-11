# EventBridge Rule: Detect Glue Job Completion
resource "aws_cloudwatch_event_rule" "glue_job_completion" {
  name        = "${var.project_name}-glue-job-completion"
  description = "Triggers when Glue ETL job completes (success or failure)"

  event_pattern = jsonencode({
    source      = ["aws.glue"]
    detail-type = ["Glue Job State Change"]
    detail = {
      jobName = [aws_glue_job.etl_job.name]
      state   = ["SUCCEEDED", "FAILED", "STOPPED"]
    }
  })

  tags = {
    Name = "${var.project_name}-glue-job-completion-rule"
  }
}

# EventBridge Target: Invoke Lambda
resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.glue_job_completion.name
  target_id = "TriggerDestinationCrawlerLambda"
  arn       = aws_lambda_function.trigger_destination_crawler.arn
}

# Permission: Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_destination_crawler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_job_completion.arn
}
