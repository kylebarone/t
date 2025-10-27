provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "random" {}

# Kubernetes provider for GKE (configured after cluster creation)
provider "kubernetes" {
  alias = "gke"

  host                   = var.enable_gcp ? module.gcp_gke[0].cluster_endpoint : null
  cluster_ca_certificate = var.enable_gcp ? base64decode(module.gcp_gke[0].cluster_ca_certificate) : null
  token                  = var.enable_gcp ? module.gcp_gke[0].cluster_token : null
}

# Kubernetes provider for EKS (configured after cluster creation)
provider "kubernetes" {
  alias = "eks"

  host                   = var.enable_aws ? module.aws_eks[0].cluster_endpoint : null
  cluster_ca_certificate = var.enable_aws ? base64decode(module.aws_eks[0].cluster_ca_certificate) : null
  token                  = var.enable_aws ? module.aws_eks[0].cluster_token : null
}
