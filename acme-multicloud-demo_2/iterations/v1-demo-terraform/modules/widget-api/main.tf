variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

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
  default     = "nginx:latest"
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

# Note: This would require kubernetes provider configured with cluster credentials
# Simplified for demonstration

output "deployment_info" {
  value = {
    cluster  = var.cluster_name
    provider = var.cloud_provider
    replicas = var.replicas
  }
}
