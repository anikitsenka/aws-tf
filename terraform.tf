terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "aws-tf-s3"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}

