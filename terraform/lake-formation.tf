# Make the current Terraform executing user a Lake Formation administrator
resource "aws_lakeformation_data_lake_settings" "lakeformation_admin" {
  admins = [data.aws_caller_identity.current.arn]
}

# Register the S3 bucket as a Lake Formation resource
resource "aws_lakeformation_resource" "sales_bucket_resource" {
  arn = aws_s3_bucket.sales_bucket.arn
}

# Lake Formation permissions for the ETL job
resource "aws_lakeformation_permissions" "lf_s3_access" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.sales_bucket_resource.arn
  }
}

resource "aws_lakeformation_permissions" "lf_sales_product_access" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DELETE"]

  table {
    name          = aws_glue_catalog_table.products.name
    database_name = aws_glue_catalog_database.sales_db.name
  }
}

resource "aws_lakeformation_permissions" "lf_sales_product_sales_access" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DELETE"]

  table {
    name          = aws_glue_catalog_table.product_sales.name
    database_name = aws_glue_catalog_database.sales_db.name
  }
}

resource "aws_lakeformation_permissions" "lf_sales_daily_sales_access" {
  principal   = aws_iam_role.glue_job_role.arn
  permissions = ["SELECT", "INSERT", "ALTER", "DELETE"]

  table {
    name          = aws_glue_catalog_table.daily_sales_by_category.name
    database_name = aws_glue_catalog_database.sales_db.name
  }
}