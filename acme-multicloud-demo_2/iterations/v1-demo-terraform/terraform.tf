terraform {
  required_version = ">= 1.0"
  
  cloud {
    organization = "acme-corp"
    workspaces {
      name = "acme-multicloud-demo"
    }
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "acme-widget-platform"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
