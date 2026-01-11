# Step Functions State Machine
resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "${var.project_name}-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = templatefile("${path.module}/step_functions/etl_pipeline_state_machine.json", {
    source_crawler_name      = aws_glue_crawler.source_crawler.name
    glue_job_name            = aws_glue_job.etl_job.name
    destination_crawler_name = aws_glue_crawler.destination_crawler.name
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = {
    Name = "${var.project_name}-etl-pipeline"
  }
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/vendedlogs/states/${var.project_name}-etl-pipeline"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-step-functions-logs"
  }
}
