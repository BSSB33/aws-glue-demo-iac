# Glue Data Catalog Database
resource "aws_glue_catalog_database" "etl_database" {
  name        = "${var.project_name}-db"
  description = "Database for ETL demo project"

  tags = {
    Name = "${var.project_name}-database"
  }
}

# Custom CSV Classifier for quoted fields
resource "aws_glue_classifier" "csv_classifier" {
  name = "${var.project_name}-csv-classifier"

  csv_classifier {
    allow_single_column    = false
    contains_header        = "PRESENT"
    delimiter              = ","
    disable_value_trimming = false
    quote_symbol           = "\""
  }
}

# Glue Crawler for Source Data
resource "aws_glue_crawler" "source_crawler" {
  name          = "${var.project_name}-source-crawler"
  database_name = aws_glue_catalog_database.etl_database.name
  role          = aws_iam_role.glue_role.arn
  description   = "Crawler for source data in S3"
  classifiers   = [aws_glue_classifier.csv_classifier.name]

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

# Auto-trigger crawler to sync schema changes
# Crawler will UPDATE the existing table (won't change SerDe)
resource "null_resource" "trigger_crawler" {
  depends_on = [
    aws_glue_crawler.source_crawler,
    aws_glue_catalog_table.source_table,
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
