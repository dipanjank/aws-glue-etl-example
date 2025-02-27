terraform {
  backend "s3" {
    bucket  = "dk-etl-example-terraform-state-bucket"
    key     = "terraform.tfstate"
    region  = local.aws_region
    encrypt = true
  }
}