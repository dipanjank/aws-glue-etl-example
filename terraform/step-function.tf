resource "aws_iam_role" "example_etl_step_functions_role" {
  name = "step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "step_functions_policy" {
  name = "step-functions-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_role_policy" {
  role       = aws_iam_role.example_etl_step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_policy.arn
}

resource "aws_sfn_state_machine" "glue_jobs_state_machine" {
  name       = "run-example-etl-jobs-sm"
  role_arn   = aws_iam_role.example_etl_step_functions_role.arn
  definition = <<EOF
{
  "Comment": "Run ETL Example Jobs",
  "StartAt": "WriteToProductsAndSalesJob",
  "States": {
    "WriteToProductsAndSalesJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${aws_glue_job.write_to_products_and_sales.name}"
      },
      "Next": "DailySalesByCategoryJob"
    },
    "DailySalesByCategoryJob": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "${aws_glue_job.daily_total_sales.name}"
      },
      "End": true
    }
  }
}
EOF
}