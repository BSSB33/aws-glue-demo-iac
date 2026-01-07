# Glue Data Catalog Database
resource "aws_glue_catalog_database" "etl_database" {
  name        = "${var.project_name}-db"
  description = "Database for ETL demo project"

  tags = {
    Name = "${var.project_name}-database"
  }
}

# Glue Crawler for Source Data
resource "aws_glue_crawler" "source_crawler" {
  name          = "${var.project_name}-source-crawler"
  database_name = aws_glue_catalog_database.etl_database.name
  role          = aws_iam_role.glue_role.arn
  description   = "Crawler for source data in S3"

  s3_target {
    path = "s3://${aws_s3_bucket.etl_bucket.id}/source/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  tags = {
    Name = "${var.project_name}-source-crawler"
  }
}

# Null resource to trigger crawler after infrastructure is created
resource "null_resource" "trigger_crawler" {
  depends_on = [
    aws_glue_crawler.source_crawler,
    aws_s3_object.source_data
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws glue start-crawler --name ${aws_glue_crawler.source_crawler.name} --region ${var.aws_region} --profile ${var.aws_profile} || true"
  }

  triggers = {
    crawler_name = aws_glue_crawler.source_crawler.name
    data_etag    = aws_s3_object.source_data.etag
  }
}
