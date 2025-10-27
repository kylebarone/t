# GCP Network Module
# Creates VPC network with subnet, secondary IP ranges, and firewall rules

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc-${var.environment}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC network for ${var.project_name} ${var.environment} environment"
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${var.project_name}-subnet-${var.environment}"
  ip_cidr_range            = var.network_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  description              = "Primary subnet for ${var.project_name}"

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Firewall rule: Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal-${var.environment}"
  network = google_compute_network.vpc.name
  
  description = "Allow internal communication between VMs, pods, and services"

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
    var.network_cidr,
    var.pods_cidr,
    var.services_cidr
  ]
}

# Firewall rule: Allow Google Cloud health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_name}-allow-health-checks-${var.environment}"
  network = google_compute_network.vpc.name
  
  description = "Allow Google Cloud load balancer health checks"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]
}

# Firewall rule: Allow IAP for SSH
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.project_name}-allow-iap-ssh-${var.environment}"
  network = google_compute_network.vpc.name
  
  description = "Allow Identity-Aware Proxy for SSH connections"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Global address for private service connection (Cloud SQL)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.project_name}-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  description   = "Reserved IP range for private services"
}

# Private VPC connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Router for Cloud NAT (optional, for future use)
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router-${var.environment}"
  region  = var.region
  network = google_compute_network.vpc.id
  
  bgp {
    asn = 64514
  }
}
