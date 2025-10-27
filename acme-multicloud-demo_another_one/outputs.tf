#------------------------------------------------------------------------------
# Summary Outputs
#------------------------------------------------------------------------------

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    gcp_enabled = var.enable_gcp
    aws_enabled = var.enable_aws
    project     = var.project_name
    environment = var.environment
  }
}

#------------------------------------------------------------------------------
# GCP Outputs
#------------------------------------------------------------------------------

output "gcp_network_id" {
  description = "GCP VPC network ID"
  value       = var.enable_gcp ? module.gcp_network[0].network_id : null
}

output "gcp_network_name" {
  description = "GCP VPC network name"
  value       = var.enable_gcp ? module.gcp_network[0].network_name : null
}

output "gcp_subnet_cidr" {
  description = "GCP subnet CIDR block"
  value       = var.enable_gcp ? module.gcp_network[0].subnet_cidr : null
}

output "gcp_cluster_name" {
  description = "GKE cluster name"
  value       = var.enable_gcp ? module.gcp_gke[0].cluster_name : null
}

output "gcp_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.enable_gcp ? module.gcp_gke[0].cluster_endpoint : null
  sensitive   = true
}

output "gcp_cluster_location" {
  description = "GKE cluster location"
  value       = var.enable_gcp ? module.gcp_gke[0].cluster_location : null
}

output "gcp_kubectl_command" {
  description = "Command to configure kubectl for GKE"
  value = var.enable_gcp ? format(
    "gcloud container clusters get-credentials %s --region %s --project %s",
    module.gcp_gke[0].cluster_name,
    var.gcp_region,
    var.gcp_project
  ) : null
}

output "gcp_database_instance_name" {
  description = "Cloud SQL instance name"
  value       = var.enable_gcp ? module.gcp_database[0].instance_name : null
}

output "gcp_database_connection_name" {
  description = "Cloud SQL connection name"
  value       = var.enable_gcp ? module.gcp_database[0].connection_name : null
}

output "gcp_database_private_ip" {
  description = "Cloud SQL private IP address"
  value       = var.enable_gcp ? module.gcp_database[0].private_ip_address : null
}

output "gcp_database_password" {
  description = "Cloud SQL database password"
  value       = var.enable_gcp ? random_password.gcp_db_password[0].result : null
  sensitive   = true
}

#------------------------------------------------------------------------------
# AWS Outputs
#------------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = var.enable_aws ? module.aws_network[0].vpc_id : null
}

output "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  value       = var.enable_aws ? module.aws_network[0].vpc_cidr : null
}

output "aws_private_subnet_ids" {
  description = "AWS private subnet IDs"
  value       = var.enable_aws ? module.aws_network[0].private_subnet_ids : null
}

output "aws_public_subnet_ids" {
  description = "AWS public subnet IDs"
  value       = var.enable_aws ? module.aws_network[0].public_subnet_ids : null
}

output "aws_nat_gateway_ip" {
  description = "AWS NAT Gateway public IP"
  value       = var.enable_aws ? module.aws_network[0].nat_gateway_ip : null
}

output "aws_cluster_name" {
  description = "EKS cluster name"
  value       = var.enable_aws ? module.aws_eks[0].cluster_name : null
}

output "aws_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_aws ? module.aws_eks[0].cluster_endpoint : null
  sensitive   = true
}

output "aws_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = var.enable_aws ? module.aws_eks[0].cluster_version : null
}

output "aws_kubectl_command" {
  description = "Command to configure kubectl for EKS"
  value = var.enable_aws ? format(
    "aws eks update-kubeconfig --name %s --region %s",
    module.aws_eks[0].cluster_name,
    var.aws_region
  ) : null
}

output "aws_database_endpoint" {
  description = "RDS database endpoint"
  value       = var.enable_aws ? module.aws_database[0].db_endpoint : null
}

output "aws_database_address" {
  description = "RDS database address"
  value       = var.enable_aws ? module.aws_database[0].db_address : null
}

output "aws_database_port" {
  description = "RDS database port"
  value       = var.enable_aws ? module.aws_database[0].db_port : null
}

output "aws_database_password" {
  description = "RDS database password"
  value       = var.enable_aws ? random_password.aws_db_password[0].result : null
  sensitive   = true
}

#------------------------------------------------------------------------------
# Quick Reference
#------------------------------------------------------------------------------

output "quick_reference" {
  description = "Quick reference guide for accessing deployed resources"
  value = {
    gcp = var.enable_gcp ? {
      network_architecture = "Custom VPC with secondary IP ranges for pods and services"
      kubernetes_access    = "Use: ${format("gcloud container clusters get-credentials %s --region %s --project %s", module.gcp_gke[0].cluster_name, var.gcp_region, var.gcp_project)}"
      database_access      = "Private IP only: ${module.gcp_database[0].private_ip_address} (use Cloud SQL Proxy or VPC connectivity)"
    } : "GCP infrastructure not deployed"
    
    aws = var.enable_aws ? {
      network_architecture = "VPC with public/private subnets, NAT Gateway for private egress"
      kubernetes_access    = "Use: ${format("aws eks update-kubeconfig --name %s --region %s", module.aws_eks[0].cluster_name, var.aws_region)}"
      database_access      = "Private endpoint: ${module.aws_database[0].db_endpoint} (accessible within VPC)"
    } : "AWS infrastructure not deployed"
  }
}
