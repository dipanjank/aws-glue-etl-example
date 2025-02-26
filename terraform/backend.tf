terraform {
  backend "s3" {
    bucket  = "dk-etl-example-terraform-state-bucket"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}