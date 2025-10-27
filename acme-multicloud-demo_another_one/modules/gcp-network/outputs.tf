output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "The CIDR block of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "pods_range_name" {
  description = "The name of the secondary IP range for pods"
  value       = "pods"
}

output "services_range_name" {
  description = "The name of the secondary IP range for services"
  value       = "services"
}

output "pods_cidr" {
  description = "The CIDR block for pods"
  value       = var.pods_cidr
}

output "services_cidr" {
  description = "The CIDR block for services"
  value       = var.services_cidr
}

output "private_vpc_connection_id" {
  description = "The private VPC connection for managed services"
  value       = google_service_networking_connection.private_vpc_connection.id
}
