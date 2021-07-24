terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "twdps"
    workspaces {
      prefix = "lab-platform-servicemesh-"
    }
  }
}

provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/${var.assume_role}"
    session_name = "lab-platform-servicemesh"
  }
}

data "terraform_remote_state" "eks" {
  backend = "remote" 

  config = {
    hostname     = "app.terraform.io"
    organization = "twdps"
    workspaces   = {
      name = "lab-platform-eks-${var.cluster_name}"
    }
  }
}
