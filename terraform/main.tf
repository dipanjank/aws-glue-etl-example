resource "aws_glue_catalog_database" "sales_db" {
  name = "sales"
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
    location      = "s3://my-lakehouse/silver/employee/"
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
