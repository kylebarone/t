# ============================================================================
# OUTPUTS - ENHANCED VERSION
# ============================================================================
# Comprehensive outputs including networking details for demo and debugging
# ============================================================================

# ----------------------------------------------------------------------------
# GCP Outputs
# ----------------------------------------------------------------------------

output "gcp_vpc_name" {
  description = "GCP VPC network name"
  value       = var.enable_gcp ? google_compute_network.vpc[0].name : null
}

output "gcp_subnet_cidr" {
  description = "GCP subnet CIDR range"
  value       = var.enable_gcp ? google_compute_subnetwork.subnet[0].ip_cidr_range : null
}

output "gcp_cluster_name" {
  description = "GKE cluster name"
  value       = var.enable_gcp ? google_container_cluster.primary[0].name : null
}

output "gcp_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = var.enable_gcp ? google_container_cluster.primary[0].endpoint : null
  sensitive   = true
}

output "gcp_cluster_location" {
  description = "GKE cluster location"
  value       = var.enable_gcp ? google_container_cluster.primary[0].location : null
}

output "gcp_database_name" {
  description = "Cloud SQL instance name"
  value       = var.enable_gcp ? google_sql_database_instance.main[0].name : null
}

output "gcp_database_connection" {
  description = "Cloud SQL connection string"
  value       = var.enable_gcp ? google_sql_database_instance.main[0].connection_name : null
}

output "gcp_database_private_ip" {
  description = "Cloud SQL private IP address"
  value       = var.enable_gcp ? google_sql_database_instance.main[0].private_ip_address : null
}

output "gcp_database_password" {
  description = "GCP database password (sensitive)"
  value       = var.enable_gcp ? random_password.db_password.result : null
  sensitive   = true
}

# ----------------------------------------------------------------------------
# AWS Outputs
# ----------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = var.enable_aws ? aws_vpc.main[0].id : null
}

output "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  value       = var.enable_aws ? aws_vpc.main[0].cidr_block : null
}

output "aws_private_subnet_ids" {
  description = "AWS private subnet IDs"
  value = var.enable_aws ? [
    aws_subnet.private_1[0].id,
    aws_subnet.private_2[0].id
  ] : null
}

output "aws_public_subnet_ids" {
  description = "AWS public subnet IDs"
  value = var.enable_aws ? [
    aws_subnet.public_1[0].id,
    aws_subnet.public_2[0].id
  ] : null
}

output "aws_nat_gateway_ip" {
  description = "AWS NAT Gateway public IP"
  value       = var.enable_aws ? aws_eip.nat[0].public_ip : null
}

output "aws_cluster_name" {
  description = "EKS cluster name"
  value       = var.enable_aws ? aws_eks_cluster.main[0].name : null
}

output "aws_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = var.enable_aws ? aws_eks_cluster.main[0].endpoint : null
  sensitive   = true
}

output "aws_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = var.enable_aws ? aws_eks_cluster.main[0].version : null
}

output "aws_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = var.enable_aws ? aws_security_group.eks_cluster[0].id : null
}

output "aws_database_endpoint" {
  description = "RDS endpoint"
  value       = var.enable_aws ? aws_db_instance.main[0].endpoint : null
}

output "aws_database_address" {
  description = "RDS hostname"
  value       = var.enable_aws ? aws_db_instance.main[0].address : null
}

output "aws_database_port" {
  description = "RDS port"
  value       = var.enable_aws ? aws_db_instance.main[0].port : null
}

output "aws_database_name" {
  description = "RDS database name"
  value       = var.enable_aws ? aws_db_instance.main[0].db_name : null
}

output "aws_database_password" {
  description = "AWS database password (sensitive)"
  value       = var.enable_aws ? random_password.db_password_aws.result : null
  sensitive   = true
}

# ----------------------------------------------------------------------------
# Summary Outputs
# ----------------------------------------------------------------------------

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    gcp_deployed = var.enable_gcp
    aws_deployed = var.enable_aws
    environment  = var.environment
    project_name = var.project_name
  }
}

output "network_architecture" {
  description = "Network architecture details"
  value = {
    gcp = var.enable_gcp ? {
      vpc_cidr           = "10.1.0.0/24"
      pod_cidr           = "10.1.16.0/20"
      service_cidr       = "10.1.32.0/20"
      connectivity       = "Private Cloud SQL via VPC Peering"
      firewall_rules     = "Internal, Health Check, SSH (IAP)"
    } : null
    
    aws = var.enable_aws ? {
      vpc_cidr           = "10.2.0.0/16"
      private_subnets    = ["10.2.1.0/24", "10.2.2.0/24"]
      public_subnets     = ["10.2.3.0/24", "10.2.4.0/24"]
      connectivity       = "NAT Gateway for private subnet internet access"
      security_groups    = "EKS Cluster SG, RDS SG"
    } : null
  }
}

output "connection_commands" {
  description = "Commands to connect to deployed resources"
  value = {
    gcp_cluster = var.enable_gcp ? "gcloud container clusters get-credentials ${google_container_cluster.primary[0].name} --zone ${google_container_cluster.primary[0].location} --project ${var.gcp_project_id}" : null
    aws_cluster = var.enable_aws ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main[0].name}" : null
  }
}
