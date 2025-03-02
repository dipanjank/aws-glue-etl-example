# Make the current Terraform executing user a Lake Formation administrator
resource "aws_lakeformation_data_lake_settings" "lakeformation_admin" {
  admins = [data.aws_caller_identity.current.account_id]

  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = data.aws_caller_identity.current.arn
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = data.aws_caller_identity.current.arn
  }
}

# Register the S3 bucket as a Lake Formation resource
resource "aws_lakeformation_resource" "lakeformation_bucket" {
  arn = aws_s3_bucket.sales_bucket.arn
}