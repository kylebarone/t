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

variable "network_id" {
  description = "VPC network ID for private IP"
  type        = string
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "database_user" {
  description = "Database user name"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Database user password"
  type        = string
  sensitive   = true
}

variable "tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 10
}

variable "backup_retention" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
