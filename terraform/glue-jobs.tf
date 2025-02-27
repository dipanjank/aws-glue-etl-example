# Create S3 bucket to store Glue scripts
resource "aws_s3_bucket" "glue_scripts_bucket" {
  bucket = "etl-example-glue-scripts"
}

data "aws_caller_identity" "current" {}

# Upload Glue script to S3 bucket
resource "aws_s3_object" "glue_script" {
  for_each = fileset("${path.root}/../python/src/etl_example/", "*.py")
  bucket   = aws_s3_bucket.glue_scripts_bucket.bucket
  key      = "etl_example/${each.value}"
  source   = "${path.root}/../python/src/etl_example/${each.value}"
  etag     = filemd5("${path.root}/../python/src/etl_example/${each.value}")
}

# Create IAM Role for Glue job
resource "aws_iam_role" "glue_job_role" {
  name = "etl-example-glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

# IAM Policy for S3
# 1. Read only for the scripts bucket
# 2. Read / Write for the data bucket
resource "aws_iam_policy" "glue_job_s3_policy" {
  name        = "GlueJobS3Policy"
  description = "Policy for Glue job to access S3 script"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.glue_scripts_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.glue_scripts_bucket.bucket}/*"
        ]
      },
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.sales_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.sales_bucket.bucket}/*"
        ]
      }
    ]
  })
}

# IAM Policy for the Glue Catalog / Database
resource "aws_iam_policy" "glue_catalog_policy" {
  name        = "GlueDeltaWritePolicy"
  description = "Allows Glue ETL jobs to write to a Delta table in Glue Data Catalog and S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:*"
        ]
        Resource = [
          "arn:aws:glue:us-east-1:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:us-east-1:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.sales_db.name}",
          "arn:aws:glue:us-east-1:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.sales_db.name}/*",
        ]
      }
    ]
  })
}

# Attach policies to IAM role for Glue job
resource "aws_iam_role_policy_attachment" "glue_job_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "attach_glue_job_s3_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = aws_iam_policy.glue_job_s3_policy.arn
}


resource "aws_iam_role_policy_attachment" "attach_glue_job_catalog_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = aws_iam_policy.glue_catalog_policy.arn
}

# Create Glue Job to execute the script
resource "aws_glue_job" "write_to_products_and_sales" {
  name         = "write-to-products-and-sales-job"
  role_arn     = aws_iam_role.glue_job_role.arn
  glue_version = "5.0"

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/etl_example/write_products.py"
    python_version  = "3"
  }

  default_arguments = {
    "--db_name"                          = "sales"
    "--product_table_name"               = "products"
    "--sales_table_name"                 = "product_sales"
    "--datalake-formats"                 = "delta"
    "--enable-continuous-cloudwatch-log" = "true"
  }

  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 60 # Timeout in minutes
}

resource "aws_glue_job" "daily_total_sales" {
  name         = "daily-sales-by-category-job"
  role_arn     = aws_iam_role.glue_job_role.arn
  glue_version = "5.0"

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/etl_example/daily_sales.py"
    python_version  = "3"
  }

  default_arguments = {
    "--db_name"                  = "sales"
    "--product_table_name"       = "products"
    "--sales_table_name"         = "product_sales"
    "--daily_summary_table_name" = "daily_sales_by_catgeory"
    "--datalake-formats"         = "delta"
  }

  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 60 # Timeout in minutes
}
