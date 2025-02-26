# Create S3 bucket to store Glue scripts
resource "aws_s3_bucket" "glue_scripts_bucket" {
  bucket = "etl-example-glue-scripts"
}

# Upload Glue script to S3 bucket
resource "aws_s3_object" "glue_script" {
  for_each = fileset("../python/etl_example/", "*.py")
  bucket   = aws_s3_bucket.glue_scripts_bucket.bucket
  key      = "etl_example/${each.value}"
  source   = "../python/etl_example/${each.value}"
  etag     = filemd5("../python/etl_example/${each.value}")
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

# Attach policies to IAM role for Glue job
resource "aws_iam_role_policy_attachment" "glue_job_policy" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Create Glue Job to execute the script
resource "aws_glue_job" "delta_write_job" {
  name     = "write-to-delta-job"
  role_arn = aws_iam_role.glue_job_role.arn

  command {
    name            = "pythonshell"
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.bucket}/python/etl_example/write_products.py"
    python_version  = "3"
  }

  max_capacity = 1  # Adjust according to the job's needs (number of DPU units)
  timeout      = 60 # Timeout in minutes (optional)
}
