# Create S3 bucket to store Glue scripts
resource "aws_s3_bucket" "glue_scripts_bucket" {
  bucket = "etl-example-glue-scripts"
}

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
      }
    ]
  })
}

# Attach policies to IAM role for Glue job
resource "aws_iam_role_policy_attachment" "glue_job_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Attach the policy to the Glue Job IAM role
resource "aws_iam_role_policy_attachment" "attach_glue_job_s3_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = aws_iam_policy.glue_job_s3_policy.arn
}

# Create Glue Job to execute the script
resource "aws_glue_job" "write_to_products" {
  name         = "write-to-products-job"
  role_arn     = aws_iam_role.glue_job_role.arn
  glue_version = "4.0"

  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/etl_example/write_products.py"
    python_version  = "3"
  }

  default_arguments = {
    "--db_name"    = "salse"
    "--table-name" = "products"
  }

  max_capacity = 2
  timeout      = 60 # Timeout in minutes
}
