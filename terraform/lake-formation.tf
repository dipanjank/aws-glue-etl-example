# Make the current Terraform executing user a Lake Formation administrator
resource "aws_lakeformation_data_lake_settings" "lakeformation_admin" {
  admins = [data.aws_caller_identity.current.arn]
}

# Register the S3 bucket as a Lake Formation resource
resource "aws_lakeformation_resource" "lakeformation_bucket" {
  arn = aws_s3_bucket.sales_bucket.arn
}

# Lake Formation permissions for the ETL job
resource "aws_lakeformation_permissions" "glue_etl_permissions" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.sales_db.name
    table_name    = aws_glue_catalog_table.products.name
  }
}

# Lake Formation permissions for the ETL role
resource "aws_lakeformation_permissions" "lf_products_permission" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DELETE", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.sales_db.name
    table_name    = aws_glue_catalog_table.products.name
  }
}

resource "aws_lakeformation_permissions" "lf_product_sales_permission" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DELETE", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.sales_db.name
    table_name    = aws_glue_catalog_table.product_sales.name
  }
}

resource "aws_lakeformation_permissions" "lf_daily_sales_permission" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DELETE", "DESCRIBE"]

  table {
    database_name = aws_glue_catalog_database.sales_db.name
    table_name    = aws_glue_catalog_table.daily_sales_by_category.name
  }
}