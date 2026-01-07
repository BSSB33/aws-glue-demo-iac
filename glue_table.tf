# Glue Catalog Table with correct OpenCSVSerde
resource "aws_glue_catalog_table" "source_table" {
  name          = "source"
  database_name = aws_glue_catalog_database.etl_database.name
  description   = "Netflix titles source data"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "csv"
    "columnsOrdered" = "true"
    "delimiter"      = ","
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.etl_bucket.id}/source/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
      
      parameters = {
        "separatorChar" = ","
        "quoteChar"     = "\""
        "escapeChar"    = "\\"
      }
    }

    columns {
      name = "show_id"
      type = "string"
    }

    columns {
      name = "type"
      type = "string"
    }

    columns {
      name = "title"
      type = "string"
    }

    columns {
      name = "director"
      type = "string"
    }

    columns {
      name = "cast"
      type = "string"
    }

    columns {
      name = "country"
      type = "string"
    }

    columns {
      name = "date_added"
      type = "string"
    }

    columns {
      name = "release_year"
      type = "bigint"
    }

    columns {
      name = "rating"
      type = "string"
    }

    columns {
      name = "duration"
      type = "string"
    }

    columns {
      name = "listed_in"
      type = "string"
    }

    columns {
      name = "description"
      type = "string"
    }
  }
}
