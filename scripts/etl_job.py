import sys
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import (
    col, when, regexp_extract, trim, coalesce, lit, year, current_date,
    to_date, length, split
)
from pyspark.sql.types import IntegerType, DateType

# Get job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'TABLE_NAME', 'OUTPUT_PATH'])

# Initialize contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Initialize Glue job
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

print(f"Starting ETL job for Netflix dataset")
print(f"Reading from database: {args['DATABASE_NAME']}, table: {args['TABLE_NAME']}")

# Read data from Glue Data Catalog
source_data = glueContext.create_dynamic_frame.from_catalog(
    database=args['DATABASE_NAME'],
    table_name=args['TABLE_NAME'],
    transformation_ctx="source_data"
)

# Convert to Spark DataFrame for advanced transformations
df = source_data.toDF()

print(f"Source records: {df.count()}")
print("Source schema:")
df.printSchema()

print("Applying column renaming...")
df = df.withColumnRenamed("show_id", "show_id") \
    .withColumnRenamed("type", "content_type") \
    .withColumnRenamed("title", "title") \
    .withColumnRenamed("director", "director") \
    .withColumnRenamed("cast", "cast_members") \
    .withColumnRenamed("country", "country") \
    .withColumnRenamed("date_added", "date_added_raw") \
    .withColumnRenamed("release_year", "release_year") \
    .withColumnRenamed("rating", "content_rating") \
    .withColumnRenamed("duration", "duration_raw") \
    .withColumnRenamed("listed_in", "genres") \
    .withColumnRenamed("description", "description")

print("Casting release_year to integer...")
df = df.withColumn("release_year", col("release_year").cast(IntegerType()))

print("Parsing date_added...")
# Netflix date format: "September 25, 2021"
df = df.withColumn(
    "date_added",
    to_date(trim(col("date_added_raw")), "yyyy. MMMM. d.")
)

print("Extracting duration values...")
# Extract numeric value from "90 min" or "1 Season"
df = df.withColumn(
    "duration_value",
    regexp_extract(col("duration_raw"), r'(\d+)', 1).cast(IntegerType())
)

# Extract unit (min, Season, Seasons)
df = df.withColumn(
    "duration_unit",
    when(col("duration_raw").contains("min"), "minutes")
    .when(col("duration_raw").contains("Season"), "seasons")
    .otherwise(None)
)

print("Creating calculated fields...")

# Is this a movie? (boolean flag)
df = df.withColumn(
    "is_movie",
    when(col("content_type") == "Movie", True).otherwise(False)
)

# Years since release (as of today)
current_year = datetime.now().year
df = df.withColumn(
    "years_since_release",
    lit(current_year) - col("release_year")
)

# Has director info (data quality flag)
df = df.withColumn(
    "has_director",
    when(
        (col("director").isNotNull()) & (length(trim(col("director"))) > 0),
        True
    ).otherwise(False)
)

# Number of genres (split by comma)
df = df.withColumn(
    "genre_count",
    when(col("genres").isNotNull(),
         length(col("genres")) - length(regexp_extract(col("genres"), ",", 0)) + 1)
    .otherwise(0)
)

print("Cleaning null values...")

# Replace empty strings with null for consistency
df = df.withColumn(
    "director",
    when((col("director").isNull()) | (trim(col("director")) == ""), None)
    .otherwise(col("director"))
)

df = df.withColumn(
    "cast_members",
    when((col("cast_members").isNull()) | (trim(col("cast_members")) == ""), None)
    .otherwise(col("cast_members"))
)

df = df.withColumn(
    "country",
    when((col("country").isNull()) | (trim(col("country")) == ""), "Unknown")
    .otherwise(col("country"))
)

print("Selecting and ordering final columns...")

# Drop columns not needed in final output
final_df = df.select(
    "show_id",
    "content_type",
    "title",
    "director",
    "cast_members",
    "country",
    "date_added",
    "release_year",
    "content_rating",
    "duration_value",
    "duration_unit",
    "genres",
    "is_movie",
    "years_since_release",
    "has_director",
    "genre_count"
    # Note: 'description' dropped to reduce output size
    # Note: 'date_added_raw' and 'duration_raw' dropped
)

print(f"Transformed records: {final_df.count()}")
print("Final schema:")
final_df.printSchema()

# Show sample of transformed data
print("Sample transformed records:")
final_df.show(5, truncate=False)
print(f"Writing transformed data to: {args['OUTPUT_PATH']}")

# Convert DataFrame back to DynamicFrame and write to S3
final_dynamic_frame = DynamicFrame.fromDF(final_df, glueContext, "final_dynamic_frame")

glueContext.write_dynamic_frame.from_options(
    frame=final_dynamic_frame,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": args['OUTPUT_PATH'],
        "partitionKeys": []
    },
    transformation_ctx="output_data"
)

# Commit the job
job.commit()
print("ETL job completed successfully!")
print(f"Output written to: {args['OUTPUT_PATH']}")
