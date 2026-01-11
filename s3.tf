# S3 Bucket for ETL Pipeline
resource "aws_s3_bucket" "etl_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.project_name
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "etl_bucket_public_access_block" {
  bucket = aws_s3_bucket.etl_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload source data file - Netflix titles dataset
resource "aws_s3_object" "source_data" {
  bucket = aws_s3_bucket.etl_bucket.id
  key    = "source/netflix_titles.csv"
  source = "${path.module}/data/netflix_titles.csv"
  etag   = filemd5("${path.module}/data/netflix_titles.csv")

  tags = {
    Name = "netflix-source-data"
  }
}

# Upload Glue job script
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.etl_bucket.id
  key    = "scripts/etl_job.py"
  source = "${path.module}/scripts/etl_job.py"
  etag   = filemd5("${path.module}/scripts/etl_job.py")

  tags = {
    Name = "glue-etl-script"
  }
}
