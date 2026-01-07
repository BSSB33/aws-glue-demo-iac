# AWS Glue ETL Job
resource "aws_glue_job" "etl_job" {
  name              = "${var.project_name}-etl-job"
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = var.glue_version
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers
  timeout           = 10
  description       = "ETL job to transform organization data from CSV to Parquet"

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.etl_bucket.id}/scripts/etl_job.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${aws_s3_bucket.etl_bucket.id}/logs/spark-logs/"
    "--TempDir"                          = "s3://${aws_s3_bucket.etl_bucket.id}/temp/"
    "--DATABASE_NAME"                    = aws_glue_catalog_database.etl_database.name
    "--TABLE_NAME"                       = "source"
    "--OUTPUT_PATH"                      = "s3://${aws_s3_bucket.etl_bucket.id}/destination/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Name = "${var.project_name}-etl-job"
  }

  depends_on = [
    aws_s3_object.glue_script,
    aws_iam_role_policy.glue_s3_policy,
    aws_iam_role_policy.glue_catalog_policy,
    aws_iam_role_policy.glue_cloudwatch_policy
  ]
}

# Null resource to trigger Glue job after crawler completes
# Note: This will wait for the crawler to finish before starting the job
resource "null_resource" "trigger_glue_job" {
  depends_on = [
    aws_glue_job.etl_job,
    null_resource.trigger_crawler
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/trigger_job.sh ${aws_glue_crawler.source_crawler.name} ${aws_glue_job.etl_job.name} ${var.aws_region} ${var.aws_profile}"
  }

  triggers = {
    job_name     = aws_glue_job.etl_job.name
    crawler_name = aws_glue_crawler.source_crawler.name
    script_etag  = aws_s3_object.glue_script.etag
  }
}
