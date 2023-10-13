terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.1"
    }
  }
}
