variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "vitraigabor"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "etl-demo-project"
}

variable "bucket_name" {
  description = "S3 bucket name for ETL pipeline"
  type        = string
  default     = "vitraiaws-etl-demo-project"
}

variable "glue_version" {
  description = "AWS Glue version"
  type        = string
  default     = "4.0"
}

variable "worker_type" {
  description = "Glue worker type (G.1X, G.2X, etc.)"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}
