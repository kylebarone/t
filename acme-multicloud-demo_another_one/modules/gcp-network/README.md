# GCP Network Module

This module creates a Google Cloud Platform VPC network with subnets, firewall rules, and private service networking for Cloud SQL.

## Features

- Custom VPC network with regional routing
- Primary subnet for GKE nodes
- Secondary IP ranges for Kubernetes pods and services
- Firewall rules for internal communication, health checks, and IAP SSH
- Private service connection for Cloud SQL
- VPC Flow Logs for security monitoring
- Cloud Router for future NAT configuration

## Usage

```hcl
module "gcp_network" {
  source = "./modules/gcp-network"

  project_name  = "acme-widget"
  environment   = "dev"
  region        = "us-central1"
  network_cidr  = "10.1.0.0/24"
  pods_cidr     = "10.1.16.0/20"
  services_cidr = "10.1.32.0/20"
  
  labels = {
    project     = "acme-widget"
    environment = "dev"
    managed_by  = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | - | yes |
| environment | Environment name | string | - | yes |
| region | GCP region | string | - | yes |
| network_cidr | CIDR block for the primary subnet | string | - | yes |
| pods_cidr | CIDR block for Kubernetes pods | string | - | yes |
| services_cidr | CIDR block for Kubernetes services | string | - | yes |
| labels | Labels to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | The ID of the VPC network |
| network_name | The name of the VPC network |
| subnet_name | The name of the subnet |
| subnet_cidr | The CIDR block of the subnet |
| pods_range_name | The name of the secondary IP range for pods |
| services_range_name | The name of the secondary IP range for services |

## Resources Created

- `google_compute_network` - VPC network
- `google_compute_subnetwork` - Subnet with secondary IP ranges
- `google_compute_firewall` (3x) - Firewall rules for internal, health checks, and IAP
- `google_compute_global_address` - Reserved IP range for private services
- `google_service_networking_connection` - VPC peering for Cloud SQL
- `google_compute_router` - Router for NAT configuration

## Network Architecture

```
VPC Network
├── Primary Subnet (nodes)
│   └── CIDR: 10.1.0.0/24
├── Secondary Range (pods)
│   └── CIDR: 10.1.16.0/20 (4,096 IPs)
└── Secondary Range (services)
    └── CIDR: 10.1.32.0/20 (4,096 IPs)

Firewall Rules:
├── Internal communication (all protocols within VPC)
├── Health checks (Google Cloud LB ranges)
└── IAP SSH (Identity-Aware Proxy)

Private Services:
└── VPC Peering for Cloud SQL
```

## Security Considerations

- Private IP ranges only, no public IPs on nodes
- Firewall rules follow least-privilege principle
- VPC Flow Logs enabled for security monitoring
- Private Google Access enabled for GCP API calls
- IAP for secure SSH access (no need for public IPs)

## Notes

- Secondary IP ranges are required for GKE clusters
- VPC peering is required for Cloud SQL private IP
- Private Google Access allows nodes to access GCP APIs without public IPs
- Flow logs may incur additional costs in high-traffic environments
