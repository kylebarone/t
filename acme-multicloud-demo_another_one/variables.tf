# Project Configuration
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "acme-widget"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Multi-Cloud Toggle
variable "enable_gcp" {
  description = "Enable GCP infrastructure deployment"
  type        = bool
  default     = true
}

variable "enable_aws" {
  description = "Enable AWS infrastructure deployment"
  type        = bool
  default     = true
}

# GCP Configuration
variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resource deployment"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_availability_zones" {
  description = "AWS availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Network Configuration
variable "gcp_network_cidr" {
  description = "CIDR block for GCP primary subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "gcp_pods_cidr" {
  description = "CIDR block for GKE pods"
  type        = string
  default     = "10.1.16.0/20"
}

variable "gcp_services_cidr" {
  description = "CIDR block for GKE services"
  type        = string
  default     = "10.1.32.0/20"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "aws_private_subnets" {
  description = "CIDR blocks for AWS private subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "aws_public_subnets" {
  description = "CIDR blocks for AWS public subnets"
  type        = list(string)
  default     = ["10.2.3.0/24", "10.2.4.0/24"]
}

# Kubernetes Configuration
variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "gke_min_nodes" {
  description = "Minimum number of GKE nodes"
  type        = number
  default     = 1
}

variable "gke_max_nodes" {
  description = "Maximum number of GKE nodes"
  type        = number
  default     = 3
}

variable "gke_initial_node_count" {
  description = "Initial number of GKE nodes"
  type        = number
  default     = 2
}

variable "eks_instance_type" {
  description = "Instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 2
}

variable "eks_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 1
}

variable "eks_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 3
}

# Database Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "widget"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "cloudsql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "cloudsql_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 10
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_days" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

# Tags and Labels
variable "common_tags" {
  description = "Common tags/labels applied to all resources"
  type        = map(string)
  default     = {}
}
