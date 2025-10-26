# Multi-Cloud Infrastructure Architecture

**Version:** 1.2 (Current State)  
**Last Updated:** October 26, 2025  
**Status:** Production-Ready Networking Configuration

## Overview

This document describes the current architecture of the ACME Multi-Cloud Demo, a Terraform-based infrastructure-as-code solution that demonstrates enterprise-grade multi-cloud deployment patterns. The infrastructure supports parallel deployment to AWS and GCP with complete networking, security, and database configurations.

## Architecture Principles

### Core Design Decisions

1. **Cloud Agnostic Toggle Pattern**: Enable/disable individual clouds via boolean flags
2. **Complete Network Isolation**: Separate VPC/Network per cloud provider with proper security boundaries
3. **Private-First Architecture**: Databases and compute nodes deployed in private networks
4. **Production-Ready Networking**: Full routing, NAT, firewall, and security group configurations
5. **Kubernetes-Centric**: Both clouds run managed Kubernetes (EKS/GKE) for workload orchestration
6. **Infrastructure as Code**: Single Terraform codebase manages both cloud environments

## Infrastructure Components

### AWS Infrastructure

#### Network Architecture
- **VPC**: `10.2.0.0/16` CIDR block
- **Private Subnets**: 
  - `10.2.1.0/24` (us-east-1a)
  - `10.2.2.0/24` (us-east-1b)
- **Public Subnets**:
  - `10.2.3.0/24` (us-east-1a)
  - `10.2.4.0/24` (us-east-1b)
- **Internet Gateway**: Direct internet access for public subnets
- **NAT Gateway**: Enables private subnet internet egress through Elastic IP
- **Route Tables**: Separate routing for public (via IGW) and private (via NAT) subnets

#### Compute Layer
- **EKS Cluster**: Kubernetes 1.28
  - Control Plane: Managed by AWS
  - Private/Public endpoint access enabled
  - Integrated with VPC subnets across both public and private
- **Node Group**: 
  - Instance Type: t3.medium
  - Scaling: 1-3 nodes (desired: 2)
  - Placement: Private subnets only
  - IAM roles with EKS policies (CNI, Worker Node, ECR)

#### Database Layer
- **RDS PostgreSQL 15.3**
  - Instance Class: db.t3.micro
  - Storage: 20GB GP2 encrypted
  - Placement: Private subnets via DB subnet group
  - Access: VPC-only via security group (port 5432)
  - Backup: 7-day retention with automated backup window

#### Security
- **EKS Cluster Security Group**: Controls control plane access (HTTPS 443)
- **RDS Security Group**: PostgreSQL access restricted to VPC CIDR
- **EKS Subnet Tags**: Enables automatic load balancer discovery
- **Default Tags**: Applied to all resources (Project, Environment, ManagedBy)

### GCP Infrastructure

#### Network Architecture
- **VPC**: Custom mode with regional routing
- **Primary Subnet**: `10.1.0.0/24` (us-central1)
- **Secondary IP Ranges**:
  - Pods: `10.1.16.0/20` (~4,096 IPs)
  - Services: `10.1.32.0/20` (~4,096 IPs)
- **Private Google Access**: Enabled for accessing GCP APIs without public IPs
- **VPC Flow Logs**: 5-second aggregation with full metadata

#### Firewall Rules
- **Internal Communication**: TCP/UDP/ICMP within VPC and secondary ranges
- **Health Checks**: Google Cloud load balancer health check ranges
- **SSH Access**: Identity-Aware Proxy (IAP) tunnel support

#### Compute Layer
- **GKE Cluster**: 
  - Type: Private cluster with private nodes
  - Control Plane CIDR: `172.16.0.0/28`
  - Public endpoint enabled for management
  - Workload Identity configured
  - Network Policy enabled (Calico)
- **Node Pool**:
  - Machine Type: e2-medium
  - Nodes: 1-3 autoscaling (desired: 2)
  - Disk: 20GB PD-Standard
  - Shielded VM features enabled
  - Auto-repair and auto-upgrade enabled

#### Database Layer
- **Cloud SQL PostgreSQL 15**
  - Tier: db-f1-micro
  - Availability: Zonal (regional for production)
  - Storage: 10GB PD-SSD
  - Network: Private IP only via VPC peering
  - No Public IP: Maximum security posture
  - Backup: Point-in-time recovery with 7-day retention

#### Security
- **Private Service Connection**: VPC peering for Cloud SQL access
- **Global Address Reservation**: Dedicated IP range for managed services
- **Workload Identity**: Secure pod-to-GCP service authentication
- **Master Authorized Networks**: Configurable control plane access

## Network Connectivity Patterns

### AWS - Three-Tier Network Model

```
Internet
    ↓
Internet Gateway (0.0.0.0/0)
    ↓
Public Subnets (10.2.3.0/24, 10.2.4.0/24)
    ↓
NAT Gateway + Elastic IP
    ↓
Private Subnets (10.2.1.0/24, 10.2.2.0/24)
    ↓
EKS Nodes + RDS Database
```

**Key Points:**
- EKS nodes pull container images through NAT Gateway
- RDS accessible only from within VPC
- LoadBalancer services can provision ALB/NLB via proper subnet tags
- Control plane to node communication secured via security groups

### GCP - Private GKE with Service Peering

```
Internet
    ↓
GKE Control Plane (Public Endpoint, 172.16.0.0/28)
    ↓
Private GKE Nodes (10.1.0.0/24)
    ├─ Pod Network (10.1.16.0/20)
    └─ Service Network (10.1.32.0/20)
    ↓
Cloud SQL (Private IP via VPC Peering)
```

**Key Points:**
- GKE nodes have no public IPs
- Private Google Access enables API calls without egress
- Cloud SQL accessed via private IP addresses only
- Health checks and internal communication secured via firewall rules

## High Availability Considerations

### Current Configuration (Demo-Optimized)
- **AWS**: Multi-AZ subnets (us-east-1a, us-east-1b)
- **GCP**: Zonal deployment (us-central1-a)
- **Databases**: Single instance with automated backups

### Production Upgrades (Recommended)
- **GCP**: Change to regional GKE cluster (`location = var.gcp_region`)
- **Cloud SQL**: Set `availability_type = "REGIONAL"` for HA
- **RDS**: Enable Multi-AZ deployment
- **Node Groups**: Increase minimum node counts

## Security Posture

### Defense in Depth Layers

1. **Network Layer**
   - Private subnets for workloads and databases
   - No public IPs on database instances
   - Controlled egress through NAT Gateway (AWS) or Private Google Access (GCP)

2. **Compute Layer**
   - IAM roles with least-privilege policies
   - Security groups/firewall rules with specific port access
   - Shielded VMs (GCP) for boot integrity
   - Managed node updates and security patches

3. **Data Layer**
   - Encrypted storage (RDS: enabled, Cloud SQL: PD-SSD)
   - Automated backups with point-in-time recovery
   - Database credentials via random password generation
   - No hardcoded secrets in code

4. **Application Layer**
   - Workload Identity (GCP) for pod authentication
   - EKS IAM roles for service accounts (configurable)
   - Network policies for pod-to-pod communication

## Resource Naming Convention

All resources follow consistent naming pattern:
```
{project_name}-{resource_type}-{environment}
```

Examples:
- `acme-widget-vpc-dev`
- `acme-widget-eks-prod`
- `acme-widget-db-dev`

This enables:
- Easy resource identification
- Cost allocation by project/environment
- Automated tagging and labeling

## State Management

- **Backend**: Terraform Cloud
- **Organization**: acme-corp
- **Workspace**: acme-multicloud-demo
- **State Locking**: Automatic via Terraform Cloud
- **Version Control**: Git-based workflow recommended

## Multi-Cloud Toggle Mechanism

The architecture supports selective cloud deployment via boolean flags:

```hcl
enable_gcp = true   # Deploy GCP infrastructure
enable_aws = true   # Deploy AWS infrastructure
```

**Use Cases:**
- Start with single cloud, expand later
- Cost optimization during development
- Disaster recovery testing
- Cloud migration scenarios
- Multi-region deployments

**Implementation:**
- All resources use `count = var.enable_gcp ? 1 : 0` pattern
- Outputs conditionally display based on enabled clouds
- No resource dependencies across cloud boundaries

## Deployment Outputs

The infrastructure exposes comprehensive outputs for both clouds:

### Network Information
- VPC/Network IDs and CIDR blocks
- Subnet IDs and IP ranges
- NAT Gateway public IP (AWS)

### Cluster Information
- Kubernetes cluster names and endpoints
- Cluster versions and locations
- kubectl connection commands

### Database Information
- Database instance names
- Connection endpoints and private IPs
- Sensitive values marked appropriately

### Summary Information
- Deployment status per cloud
- Network architecture details
- Quick reference commands

## Scaling Considerations

### Horizontal Scaling
- **GKE**: Autoscaling 1-3 nodes configured
- **EKS**: Autoscaling 1-3 nodes configured
- **Databases**: Vertical scaling via instance class changes

### Network Capacity
- **AWS**: VPC CIDR supports 65,536 IPs
- **GCP Primary**: 256 IPs for nodes
- **GCP Pods**: 4,096 IPs available
- **GCP Services**: 4,096 IPs available

### Cost Optimization
- Use instance type/machine type variables for environment-specific sizing
- Leverage spot instances for non-production EKS node groups
- Consider preemptible nodes for non-production GKE
- Database instance sizing based on workload requirements

## Operational Considerations

### Monitoring and Observability
- **VPC Flow Logs**: Enabled in GCP subnet
- **AWS Flow Logs**: Add for production
- **Kubernetes Metrics**: Built-in via EKS/GKE
- **Database Monitoring**: CloudWatch (AWS), Cloud Monitoring (GCP)

### Maintenance Windows
- **RDS**: Monday 04:00-05:00 UTC
- **Cloud SQL**: Monday 04:00 UTC
- **GKE Nodes**: Auto-upgrade enabled
- **EKS**: Manual cluster upgrades

### Backup Strategy
- **RDS**: 7-day retention, automated daily backups
- **Cloud SQL**: 7-day retention, PITR enabled
- **Terraform State**: Versioned in Terraform Cloud

## Future Enhancements

### Near-Term (v1.3+)
- Implement widget-api Kubernetes module
- Add CI/CD pipeline integration
- Implement AWS Secrets Manager for database passwords
- Add CloudWatch/Cloud Monitoring dashboards

### Long-Term (v2.0+)
- Service mesh integration (Istio)
- Cross-cloud VPN for hybrid workloads
- Multi-region deployments
- Disaster recovery automation
- Advanced monitoring and alerting

## References

- **Terraform Version**: >= 1.0
- **AWS Provider**: ~> 5.0
- **GCP Provider**: ~> 5.0
- **Kubernetes Provider**: ~> 2.23
- **Random Provider**: ~> 3.5

## Document Control

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Initial | Basic infrastructure without complete networking |
| 1.2 | Oct 2025 | Added NAT Gateway, route tables, private Cloud SQL, firewall rules, secondary IP ranges |
| Current | Oct 2025 | Comprehensive documentation of current production-ready state |
