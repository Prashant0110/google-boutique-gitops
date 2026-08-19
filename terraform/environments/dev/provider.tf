terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform-user"
}

provider "vault" {
  address = var.vault_address
}