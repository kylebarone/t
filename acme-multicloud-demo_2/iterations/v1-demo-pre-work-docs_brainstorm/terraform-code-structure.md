# Terraform Code Structure & Implementation Guide

## Project Structure

```
acme-multicloud-demo/
├── README.md
├── .gitignore
├── terraform.tf                 # Terraform & provider config
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── main.tf                      # Root module orchestration
├── gcp.tf                       # GCP-specific resources
├── aws.tf                       # AWS-specific resources
├── vault.tf                     # Vault integration (bonus)
│
├── modules/
│   ├── widget-api/              # Reusable application module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── database/                # Reusable database module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev.tfvars               # Dev environment variables
│   └── prod.tfvars              # Prod environment variables
│
└── scripts/
    ├── deploy.sh                # Helper deployment script
    └── setup-vault.sh           # Vault configuration script
```

---

## Core Files Implementation

### terraform.tf - Backend & Provider Configuration

```hcl
terraform {
  required_version = ">= 1.0"
  
  # Terraform Cloud backend
  cloud {
    organization = "acme-corp"
    
    workspaces {
      name = "acme-widget-platform-dev"
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
    
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# GCP Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# AWS Provider
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

# Vault Provider (bonus integration)
provider "vault" {
  address = var.vault_address
}
```

**Key Points for Demo:**
- Show Terraform Cloud backend configuration
- Explain why remote state is critical for teams
- Point out provider version constraints for reproducibility

---

### variables.tf - Input Variables

```hcl
# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "acme-widget-platform"
}

# GCP Configuration
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone for resources"
  type        = string
  default     = "us-central1-a"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Database Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "widget_orders"
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

# Vault Configuration (bonus)
variable "vault_address" {
  description = "Vault server address"
  type        = string
  default     = "https://vault.example.com:8200"
}

variable "enable_vault_integration" {
  description = "Enable Vault dynamic secrets"
  type        = bool
  default     = false
}

# Application Configuration
variable "widget_api_image" {
  description = "Container image for Widget API"
  type        = string
  default     = "nginx:latest"  # Replace with actual app image
}

variable "widget_api_replicas" {
  description = "Number of API replicas"
  type        = number
  default     = 2
}
```

**Key Points for Demo:**
- Show how variables enable reusability
- Explain sensitive = true for secrets
- Point out defaults for ease of use

---

### outputs.tf - Output Values

```hcl
# GCP Outputs
output "gcp_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gcp_database_connection" {
  description = "Cloud SQL connection string"
  value       = google_sql_database_instance.main.connection_name
}

output "gcp_load_balancer_ip" {
  description = "GCP Load Balancer IP address"
  value       = "Configured via Kubernetes Service"
}

# AWS Outputs
output "aws_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "aws_database_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "aws_load_balancer_dns" {
  description = "AWS ALB DNS name"
  value       = "Configured via Kubernetes Service"
}

# Application Outputs
output "api_endpoints" {
  description = "Widget API endpoints"
  value = {
    gcp = "https://widget-api-gcp.acme.com"
    aws = "https://widget-api-aws.acme.com"
  }
}

# Vault Outputs (if enabled)
output "vault_db_path" {
  description = "Vault database secrets path"
  value       = var.enable_vault_integration ? vault_database_secrets_mount.db[0].path : null
}
```

**Key Points for Demo:**
- Run `terraform output` after apply
- Show how outputs feed into other systems
- Explain sensitive output handling

---

### gcp.tf - GCP Resources

```hcl
# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_name}-gke-${var.environment}"
  location = var.gcp_zone
  
  # Start with single-zone for demo
  initial_node_count = 1
  
  # Remove default node pool immediately
  remove_default_node_pool = true
  
  # Network configuration
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name
  
  # Enable workload identity for Vault integration
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
}

# GKE Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.project_name}-node-pool"
  location   = var.gcp_zone
  cluster    = google_container_cluster.primary.name
  node_count = 2
  
  node_config {
    machine_type = "e2-medium"  # Cost-effective for demo
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
    
    tags = ["gke-node", var.environment]
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet-${var.environment}"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.gcp_region
  
  settings {
    tier = "db-f1-micro"  # Cost-effective for demo
    
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.id
    }
    
    backup_configuration {
      enabled = true
    }
  }
  
  deletion_protection = false  # Allow easy cleanup after demo
}

# Cloud SQL Database
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

# Cloud SQL User (will be replaced by Vault in bonus demo)
resource "google_sql_user" "users" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# Random password generation (temporary, Vault replaces this)
resource "random_password" "db_password" {
  length  = 16
  special = true
}
```

**Key Points for Demo:**
- Highlight resource naming conventions
- Show dependency management (implicit)
- Explain cost-optimized settings for demo
- Point out deletion_protection = false for easy cleanup

---

### aws.tf - AWS Resources

```hcl
# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks-${var.environment}"
  role_arn = aws_iam_role.eks_cluster.arn
  
  vpc_config {
    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  
  instance_types = ["t3.medium"]
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy
  ]
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

# Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "${var.aws_region}a"
  
  tags = {
    Name = "${var.project_name}-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "${var.aws_region}b"
  
  tags = {
    Name = "${var.project_name}-private-2"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-db-${var.environment}"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password_aws.result
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  skip_final_snapshot = true  # Allow easy cleanup
  
  tags = {
    Name = "${var.project_name}-rds"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL from EKS"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
}

# Random password for AWS RDS
resource "random_password" "db_password_aws" {
  length  = 16
  special = true
}

# IAM Roles (simplified for demo)
resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}
```

**Key Points for Demo:**
- Show parallel structure to GCP (cloud agnostic patterns)
- Explain IAM complexity (this is why Terraform helps)
- Point out similar naming conventions across clouds

---

### vault.tf - Vault Integration (Bonus)

```hcl
# Enable database secrets engine
resource "vault_database_secrets_mount" "db" {
  count = var.enable_vault_integration ? 1 : 0
  path  = "database"
  
  postgresql {
    name              = "gcp-postgres"
    username          = var.db_username
    password          = random_password.db_password.result
    connection_url    = "postgresql://{{username}}:{{password}}@${google_sql_database_instance.main.private_ip_address}:5432/${var.db_name}"
    verify_connection = true
    allowed_roles     = ["widget-api-role"]
  }
  
  postgresql {
    name              = "aws-postgres"
    username          = var.db_username
    password          = random_password.db_password_aws.result
    connection_url    = "postgresql://{{username}}:{{password}}@${aws_db_instance.main.endpoint}/${var.db_name}"
    verify_connection = true
    allowed_roles     = ["widget-api-role"]
  }
}

# Database role
resource "vault_database_secret_backend_role" "role" {
  count   = var.enable_vault_integration ? 1 : 0
  backend = vault_database_secrets_mount.db[0].path
  name    = "widget-api-role"
  db_name = "gcp-postgres"
  
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]
  
  default_ttl = 3600
  max_ttl     = 86400
}
```

**Key Points for Demo:**
- Explain this replaces static passwords
- Show dynamic credential generation
- Connect to security breach scenario (Vault 1)

---

## Module Structure

### modules/widget-api/main.tf

```hcl
variable "cloud_provider" {
  description = "Cloud provider (gcp or aws)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 2
}

variable "image" {
  description = "Container image"
  type        = string
}

# Kubernetes deployment
resource "kubernetes_deployment" "widget_api" {
  metadata {
    name      = "widget-api"
    namespace = var.namespace
    
    labels = {
      app   = "widget-api"
      cloud = var.cloud_provider
    }
  }
  
  spec {
    replicas = var.replicas
    
    selector {
      match_labels = {
        app = "widget-api"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "widget-api"
        }
      }
      
      spec {
        container {
          name  = "api"
          image = var.image
          
          port {
            container_port = 8080
          }
          
          env {
            name  = "CLOUD_PROVIDER"
            value = var.cloud_provider
          }
        }
      }
    }
  }
}

output "deployment_name" {
  value = kubernetes_deployment.widget_api.metadata[0].name
}
```

**Key Points for Demo:**
- Show module reusability
- Same module works for GCP and AWS
- Parameterized for flexibility

---

## Implementation Checklist

### Pre-Demo Setup
- [ ] Create Terraform Cloud account
- [ ] Create GCP project, enable APIs
- [ ] Create AWS account, configure credentials
- [ ] Push code to GitHub repo
- [ ] Test full deployment once

### During Demo Commands

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Show outputs
terraform output

# Workspace operations
terraform workspace list
terraform workspace new prod

# Cleanup (after demo)
terraform destroy -auto-approve
```

### Post-Demo Cleanup
- [ ] Run `terraform destroy`
- [ ] Verify all resources deleted in console
- [ ] Remove credentials from Terraform Cloud
- [ ] Archive GitHub repo

---

## Key Demo Talking Points

1. **Single Codebase**: "Notice we're provisioning GCP and AWS with the same tool"
2. **Version Control**: "All infrastructure changes go through Git pull requests"
3. **State Management**: "Remote state prevents conflicts, enables collaboration"
4. **Modularity**: "Reusable modules mean write once, deploy anywhere"
5. **Platform Integration**: "Vault integration shows HashiCorp ecosystem value"

---

## Estimated Resource Costs

**GCP (per hour):**
- GKE cluster: ~$0.10/hour
- Cloud SQL: ~$0.015/hour
- **Total: ~$0.12/hour**

**AWS (per hour):**
- EKS cluster: ~$0.10/hour
- RDS t3.micro: ~$0.017/hour
- **Total: ~$0.12/hour**

**Combined: ~$0.25/hour or ~$6/day**

Recommendation: Deploy 1 hour before demo, destroy immediately after.
