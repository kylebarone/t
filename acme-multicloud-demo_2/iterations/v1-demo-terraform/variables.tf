variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "acme-widget"
}

# GCP Variables
variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

# AWS Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Database Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "widget_orders"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

# Application Variables
variable "enable_gcp" {
  description = "Deploy GCP resources"
  type        = bool
  default     = true
}

variable "enable_aws" {
  description = "Deploy AWS resources"
  type        = bool
  default     = true
}
