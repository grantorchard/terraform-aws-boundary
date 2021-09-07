terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.57"
    }
		hcp = {
			source = "hashicorp/hcp"
			version = "~> 0.15"
		}
		vault = {
      source = "hashicorp/vault"
      version = "2.23.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      owner              = "go"
      se-region          = "apj"
      purpose            = "boundary testing"
      ttl                = "-1"
      terraform          = true
      hc-internet-facing = true
    }
  }
}
