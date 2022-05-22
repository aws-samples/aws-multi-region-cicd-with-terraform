terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.74"
    }
  }
  required_version = "> 0.14"
}

terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn     = "arn:aws:iam::${var.account}:role/InfraBuildRole"
    session_name = "INFRA_BUILD"
  }
}