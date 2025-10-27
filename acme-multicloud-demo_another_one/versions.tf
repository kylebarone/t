terraform {
  required_version = ">= 1.0"

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

  # Backend configuration for Terraform Cloud (optional)
  # Uncomment and configure for production use
  # backend "remote" {
  #   organization = "acme-corp"
  #   workspaces {
  #     name = "acme-multicloud-demo"
  #   }
  # }
}
