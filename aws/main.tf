terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.49.2"
    }
  }
}

provider "aws" {
  region     = "us-west-2"
  profile = "default"
}