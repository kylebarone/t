# ============================================================================
# GCP INFRASTRUCTURE - FIXED VERSION
# ============================================================================
# This file contains all GCP resources with complete networking configuration
# including private Cloud SQL, firewall rules, and proper GKE IP management.
# ============================================================================

# ----------------------------------------------------------------------------
# VPC Network
# ----------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  count                   = var.enable_gcp ? 1 : 0
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  
  description = "VPC for ${var.project_name} ${var.environment} environment"
}

# ----------------------------------------------------------------------------
# Subnet with Secondary IP Ranges for GKE
# ----------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  count         = var.enable_gcp ? 1 : 0
  name          = "${var.project_name}-subnet-${var.environment}"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc[0].id
  
  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "${var.project_name}-pods-${var.environment}"
    ip_cidr_range = "10.1.16.0/20"  # 4096 IPs for pods
  }
  
  secondary_ip_range {
    range_name    = "${var.project_name}-services-${var.environment}"
    ip_cidr_range = "10.1.32.0/20"  # 4096 IPs for services
  }
  
  # Enable VPC Flow Logs for observability
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  
  private_ip_google_access = true
}

# ----------------------------------------------------------------------------
# Firewall Rules
# ----------------------------------------------------------------------------

# Allow internal communication between nodes
resource "google_compute_firewall" "allow_internal" {
  count   = var.enable_gcp ? 1 : 0
  name    = "${var.project_name}-allow-internal-${var.environment}"
  network = google_compute_network.vpc[0].name
  
  description = "Allow internal communication between GKE nodes"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "10.1.0.0/24",     # Primary subnet range
    "10.1.16.0/20",    # Pod range
    "10.1.32.0/20"     # Service range
  ]
  
  target_tags = ["gke-node"]
}

# Allow health checks from Google Cloud Load Balancer
resource "google_compute_firewall" "allow_health_check" {
  count   = var.enable_gcp ? 1 : 0
  name    = "${var.project_name}-allow-health-check-${var.environment}"
  network = google_compute_network.vpc[0].name
  
  description = "Allow health checks from Google Cloud"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",     # Google Cloud health check ranges
    "130.211.0.0/22"
  ]
  
  target_tags = ["gke-node"]
}

# Allow SSH for maintenance (can be removed in production)
resource "google_compute_firewall" "allow_ssh" {
  count   = var.enable_gcp ? 1 : 0
  name    = "${var.project_name}-allow-ssh-${var.environment}"
  network = google_compute_network.vpc[0].name
  
  description = "Allow SSH from IAP (Identity-Aware Proxy)"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range for SSH
  source_ranges = ["35.235.240.0/20"]
  
  target_tags = ["gke-node"]
}

# ============================================================================
# PRIVATE SERVICE CONNECTION FOR CLOUD SQL
# ============================================================================

# ----------------------------------------------------------------------------
# Reserve IP Range for Private Services
# ----------------------------------------------------------------------------
resource "google_compute_global_address" "private_ip_address" {
  count         = var.enable_gcp ? 1 : 0
  name          = "${var.project_name}-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc[0].id
  
  description = "Reserved IP range for private services (Cloud SQL)"
}

# ----------------------------------------------------------------------------
# Create Private VPC Connection
# ----------------------------------------------------------------------------
resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.enable_gcp ? 1 : 0
  network                 = google_compute_network.vpc[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

# ============================================================================
# GKE CLUSTER RESOURCES
# ============================================================================

# ----------------------------------------------------------------------------
# GKE Cluster
# ----------------------------------------------------------------------------
resource "google_container_cluster" "primary" {
  count    = var.enable_gcp ? 1 : 0
  name     = "${var.project_name}-gke-${var.environment}"
  location = var.gcp_zone  # Use var.gcp_region for regional cluster
  
  # Remove default node pool immediately
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc[0].name
  subnetwork = google_compute_subnetwork.subnet[0].name
  
  # IP allocation policy for GKE
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.project_name}-pods-${var.environment}"
    services_secondary_range_name = "${var.project_name}-services-${var.environment}"
  }
  
  # Network policy
  network_policy {
    enabled  = true
    provider = "PROVIDER_UNSPECIFIED"  # Uses Calico
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  
  # Master authorized networks (open for demo - restrict in production)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks (for demo)"
    }
  }
  
  # Workload Identity (for secure pod authentication)
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
  
  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
  
  deletion_protection = false
  
  depends_on = [
    google_compute_subnetwork.subnet
  ]
}

# ----------------------------------------------------------------------------
# GKE Node Pool
# ----------------------------------------------------------------------------
resource "google_container_node_pool" "primary_nodes" {
  count      = var.enable_gcp ? 1 : 0
  name       = "${var.project_name}-node-pool-${var.environment}"
  location   = var.gcp_zone
  cluster    = google_container_cluster.primary[0].name
  node_count = 2

  # Autoscaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  
  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    
    # Scopes for GKE nodes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      managed_by  = "terraform"
      workload    = "general"
    }

    tags = ["gke-node", var.environment]
    
    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # Enable shielded nodes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}

# ============================================================================
# CLOUD SQL RESOURCES
# ============================================================================

# ----------------------------------------------------------------------------
# Random Password for Cloud SQL
# ----------------------------------------------------------------------------
resource "random_password" "db_password" {
  length  = 16
  special = true
  
  # Prevent password rotation on apply
  lifecycle {
    ignore_changes = [
      length,
      special
    ]
  }
}

# ----------------------------------------------------------------------------
# Cloud SQL Instance (Private IP)
# ----------------------------------------------------------------------------
resource "google_sql_database_instance" "main" {
  count            = var.enable_gcp ? 1 : 0
  name             = "${var.project_name}-db-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"  # Use "REGIONAL" for HA in production
    disk_type         = "PD_SSD"
    disk_size         = 10
    
    # IP Configuration - PRIVATE ONLY
    ip_configuration {
      ipv4_enabled    = false  # NO PUBLIC IP
      private_network = google_compute_network.vpc[0].id
      require_ssl     = false  # Set to true in production
    }

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
      }
    }
    
    # Maintenance window
    maintenance_window {
      day          = 1  # Monday
      hour         = 4  # 4 AM
      update_track = "stable"
    }
    
    # Database flags
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }

  deletion_protection = false  # Set to true in production
  
  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

# ----------------------------------------------------------------------------
# Cloud SQL Database
# ----------------------------------------------------------------------------
resource "google_sql_database" "database" {
  count    = var.enable_gcp ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.main[0].name
}

# ----------------------------------------------------------------------------
# Cloud SQL User
# ----------------------------------------------------------------------------
resource "google_sql_user" "user" {
  count    = var.enable_gcp ? 1 : 0
  name     = var.db_username
  instance = google_sql_database_instance.main[0].name
  password = random_password.db_password.result
}
