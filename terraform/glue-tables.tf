resource "aws_s3_bucket" "sales_bucket" {
  bucket = "dk-etl-sales-bucket"
}

resource "aws_glue_catalog_database" "sales_db" {
  name = "sales"
  location_uri = "s3://${aws_s3_bucket.sales_bucket.bucket}/sales_db"
}

resource "aws_glue_catalog_table" "products" {
  name          = "products"
  database_name = aws_glue_catalog_database.sales_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "delta"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.sales_bucket.bucket}/bronze/products/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "delta-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "product_id"
      type = "string"
    }
    columns {
      name = "name"
      type = "string"
    }
    columns {
      name = "category"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "product_sales" {
  name          = "product_sales"
  database_name = aws_glue_catalog_database.sales_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "delta"
  }
  storage_descriptor {
    location      = "s3://${aws_s3_bucket.sales_bucket.bucket}/bronze/product_sales/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "delta-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "sales_id"
      type = "string"
    }
    columns {
      name = "product_id"
      type = "string"
    }
    columns {
      name = "quantity"
      type = "bigint"
    }
    columns {
      name = "sale_date"
      type = "date"
    }
  }
}

resource "aws_glue_catalog_table" "daily_sales_by_category" {
  name          = "daily_sales_by_category"
  database_name = aws_glue_catalog_database.sales_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "delta"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.sales_bucket.bucket}/silver/daily_sales_by_catgeory/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "delta-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "sale_date"
      type = "date"
    }
    columns {
      name = "category"
      type = "string"
    }
    columns {
      name = "total_quantity"
      type = "bigint"
    }
  }
}
