# AWS Glue ETL Demo Project - Netflix Content Analysis

A complete AWS Glue ETL pipeline implementation using Terraform that demonstrates best practices for data transformation from CSV to Parquet format.

## Overview

This project showcases an end-to-end ETL pipeline using AWS Glue, S3, and Infrastructure as Code (Terraform). It processes the Netflix Movies and TV Shows dataset, demonstrating comprehensive data transformations including type casting, date parsing, feature extraction, and data quality improvements. The pipeline outputs optimized Parquet files suitable for analytics (Documentation Created by Claude).

## Architecture

### Components

- **S3 Bucket**: Single bucket (`vitraiaws-etl-demo-project`) with organized folders:
  - `source/`: Input CSV files
  - `destination/`: Transformed Parquet output
  - `scripts/`: Glue job Python scripts
  - `logs/`: Spark execution logs
  - `temp/`: Temporary Glue job data

- **Glue Data Catalog**:
  - Database for schema metadata
  - Automated schema discovery via Crawler

- **Glue Crawler**: Scans source data and creates/updates table schemas

- **Glue ETL Job**: Advanced PySpark-based transformation job that:
  - Reads Netflix content data from Data Catalog
  - Performs 8 types of transformations (see below)
  - Extracts features and creates calculated fields
  - Handles data quality issues
  - Outputs to Parquet for better performance

- **IAM Role**: Least-privilege permissions for Glue service

### Data Flow

1. Source CSV file uploaded to `s3://bucket/source/`
2. Glue Crawler scans and catalogs schema
3. Glue ETL job reads from catalog, transforms data
4. Transformed data written to `s3://bucket/destination/` as Parquet

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- AWS account with permissions for S3, Glue, IAM, and CloudWatch
- Existing S3 backend bucket: `vitraiaws-terraform-states`
- Existing DynamoDB table: `terraform-state-locks`

## Project Structure

```
.
├── backend.tf              # Terraform S3 backend configuration
├── provider.tf             # AWS provider and version constraints
├── variables.tf            # Variable definitions
├── terraform.tfvars.example # Example variable values
├── s3.tf                   # S3 bucket and objects
├── iam.tf                  # IAM roles and policies (least privilege)
├── glue_catalog.tf         # Glue database and crawler
├── glue_job.tf             # Glue ETL job definition
├── outputs.tf              # Terraform outputs
├── data/
│   └── organizations.csv   # Sample source data
└── scripts/
    └── etl_job.py          # Glue ETL job script
```

## Setup Instructions

### 1. Clone and Configure

```bash
cd etl-demo-project

# Optional: Create terraform.tfvars if you need to override defaults
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars as needed
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Infrastructure Plan

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

The deployment will automatically:
- Create S3 bucket with appropriate configuration
- Upload source data and ETL script
- Create Glue database, crawler, and job
- Start the crawler to catalog the schema
- Wait for crawler completion and trigger the ETL job

### 5. Monitor Execution

Check the outputs for useful URLs:

```bash
terraform output
```

Monitor the job execution:
- AWS Console → Glue → ETL Jobs
- CloudWatch Logs → `/aws-glue/jobs/`

### 6. Verify Results

Check the destination folder for Parquet output:

```bash
aws s3 ls s3://vitraiaws-etl-demo-project/destination/ --recursive --profile vitraigabor
```

## Running the Pipeline Manually

### Trigger Crawler

```bash
aws glue start-crawler \
  --name etl-demo-project-source-crawler \
  --region eu-west-1 \
  --profile vitraigabor
```

### Trigger ETL Job

```bash
aws glue start-job-run \
  --job-name etl-demo-project-etl-job \
  --region eu-west-1 \
  --profile vitraigabor
```

## Dataset

**Source**: Netflix Movies and TV Shows (Kaggle)
- **Records**: ~8,800 titles (movies and TV shows)
- **Size**: 3.2 MB
- **Format**: CSV → Parquet
- **Content**: Netflix catalog data including titles, directors, cast, release dates, ratings, and genres

## Data Transformations

The ETL job demonstrates 8 comprehensive transformation types:

### 1. Column Renaming (snake_case)
| Source Column  | Target Column     | Description |
|----------------|-------------------|-------------|
| show_id        | show_id           | Unique identifier |
| type           | content_type      | Movie or TV Show |
| title          | title             | Title name |
| director       | director          | Director name(s) |
| cast           | cast_members      | Cast list |
| country        | country           | Country of origin |
| date_added     | date_added        | Date added to Netflix |
| release_year   | release_year      | Year of release |
| rating         | content_rating    | Content rating (PG, R, etc.) |
| duration       | duration_value    | Numeric duration |
| listed_in      | genres            | Genre categories |

### 2. Type Casting
- **release_year**: string → integer
- **date_added**: string ("September 25, 2021") → date type
- **duration_value**: string ("90 min") → integer (90)

### 3. Feature Extraction
- **duration_value**: Extracted numeric value from "90 min" or "1 Season"
- **duration_unit**: Extracted unit ("minutes" or "seasons")

### 4. Calculated Fields
- **is_movie**: Boolean flag (true for movies, false for TV shows)
- **years_since_release**: Current year - release_year
- **has_director**: Data quality flag (true if director info exists)
- **genre_count**: Number of genres (comma-separated count)

### 5. Data Cleaning
- Empty strings converted to null for consistency
- Country: Unknown values replaced with "Unknown"
- Director/Cast: Standardized null handling

### 6. Column Dropping
- **description**: Dropped to reduce output size (long text field)
- **date_added_raw**: Dropped after parsing to proper date
- **duration_raw**: Dropped after extracting structured values

### 7. Final Schema

| Column Name           | Type    | Description |
|-----------------------|---------|-------------|
| show_id               | string  | Unique ID |
| content_type          | string  | Movie/TV Show |
| title                 | string  | Title name |
| director              | string  | Director(s) |
| cast_members          | string  | Cast list |
| country               | string  | Country |
| date_added            | date    | Date added to Netflix |
| release_year          | int     | Release year |
| content_rating        | string  | Rating |
| duration_value        | int     | Duration number |
| duration_unit         | string  | minutes/seasons |
| genres                | string  | Genre list |
| is_movie              | boolean | Movie flag |
| years_since_release   | int     | Age of content |
| has_director          | boolean | Data quality flag |
| genre_count           | int     | Number of genres |

## Cost Considerations

- **S3**: Minimal storage costs for sample data
- **Glue Crawler**: Charged per DPU-hour (typically completes in < 1 minute)
- **Glue Job**: Charged per DPU-hour (2 DPUs × job duration)
- **CloudWatch Logs**: Minimal for demo purposes

Estimated cost per run: < $0.50 USD

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Note: The S3 bucket has `force_destroy = true`, so it will be deleted along with all contents.

## Best Practices Demonstrated

1. **Infrastructure as Code**: Complete infrastructure defined in Terraform
2. **Least Privilege IAM**: Scoped permissions instead of wildcard access
3. **Modern Terraform**: Uses AWS provider 5.x and modern resource types
4. **State Management**: Remote state with locking
5. **Resource Tagging**: Consistent tagging for cost allocation
6. **Security**: Private S3 bucket with public access blocked
7. **Monitoring**: CloudWatch logs and Spark UI enabled
8. **Parquet Format**: Optimized columnar storage for analytics

## Troubleshooting

### Crawler Fails to Create Table

Check that:
- Source data is uploaded to S3
- IAM role has necessary permissions
- S3 path is correct in crawler configuration

### Glue Job Fails

Check CloudWatch Logs at `/aws-glue/jobs/etl-demo-project-etl-job`:
- Verify table exists in Data Catalog
- Check S3 permissions
- Ensure script is uploaded to S3

### Terraform Apply Fails

- Ensure backend bucket and DynamoDB table exist
- Verify AWS credentials are configured
- Check that bucket name is globally unique

## License

This is a demo project for educational purposes.

## Author

Gabor Vitrai
