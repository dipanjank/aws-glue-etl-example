resource "aws_glue_catalog_database" "sales_db" {
  name = "sales"
}

resource "aws_s3_bucket" "sales_bucket" {
  bucket = "dk-etl-sales-bucket"

}

resource "aws_glue_catalog_table" "products" {
  name          = "products"
  database_name = aws_glue_catalog_database.sales_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL             = "TRUE"
    classification       = "delta"
    "delta.table.format" = "delta"
  }

  storage_descriptor {
    location      = "s3://dk-etl-sales-bucket/bronze/products/"
    input_format  = "io.delta.sql.DeltaStorageHandler"
    output_format = "io.delta.sql.DeltaStorageHandler"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
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
    EXTERNAL             = "TRUE"
    classification       = "delta"
    "delta.table.format" = "delta"
  }

  storage_descriptor {
    location      = "s3://dk-etl-sales-bucket/bronze/product_sales/"
    input_format  = "io.delta.sql.DeltaStorageHandler"
    output_format = "io.delta.sql.DeltaStorageHandler"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
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
      type = "long"
    }
    columns {
      name = "sale_date"
      type = "date"
    }
  }
}


resource "aws_glue_catalog_table" "daily_sales_by_catgeory" {
  name          = "daily_sales_by_catgeory"
  database_name = aws_glue_catalog_database.sales_db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL             = "TRUE"
    classification       = "delta"
    "delta.table.format" = "delta"
  }

  storage_descriptor {
    location      = "s3://dk-etl-sales-bucket/bronze/daily_sales_by_catgeory/"
    input_format  = "io.delta.sql.DeltaStorageHandler"
    output_format = "io.delta.sql.DeltaStorageHandler"
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
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
      type = "long"
    }
  }
}
