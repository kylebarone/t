variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_cidr" {
  description = "CIDR block for the primary subnet"
  type        = string
}

variable "pods_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
}

variable "services_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
