# Technical Reference Documentation

**Version**: 1.2 Production-Ready  
**Last Updated**: October 26, 2025  
**Audience**: Engineering teams, DevOps, SRE, and Technical Architects

---

## Table of Contents
- [Networking Deep Dive](#networking-deep-dive)
- [Security Configuration](#security-configuration)
- [Compute Resources](#compute-resources)
- [Database Configuration](#database-configuration)
- [IAM and Access Control](#iam-and-access-control)
- [Terraform Implementation](#terraform-implementation)
- [Operational Procedures](#operational-procedures)
- [Troubleshooting Guide](#troubleshooting-guide)

---

## Networking Deep Dive

### AWS Network Architecture

#### VPC Configuration
```hcl
CIDR Block: 10.2.0.0/16 (65,536 IP addresses)
DNS Support: Enabled
DNS Hostnames: Enabled
```

**Rationale**: 
- /16 CIDR provides ample room for growth
- DNS support enables service discovery within VPC
- Tagged for EKS cluster discovery

#### Subnet Design

| Subnet | CIDR | AZ | Type | Purpose |
|--------|------|----|----|---------|
| private_1 | 10.2.1.0/24 | us-east-1a | Private | EKS nodes, RDS primary |
| private_2 | 10.2.2.0/24 | us-east-1b | Private | EKS nodes, RDS standby |
| public_1 | 10.2.3.0/24 | us-east-1a | Public | NAT Gateway, load balancers |
| public_2 | 10.2.4.0/24 | us-east-1b | Public | Load balancers |

**Private Subnet Tags**:
```hcl
"kubernetes.io/cluster/${cluster_name}" = "shared"
"kubernetes.io/role/internal-elb" = "1"
Type = "private"
```

**Public Subnet Tags**:
```hcl
"kubernetes.io/cluster/${cluster_name}" = "shared"
"kubernetes.io/role/elb" = "1"
Type = "public"
```

**Critical**: These tags enable EKS to automatically discover subnets for LoadBalancer service provisioning.

#### Internet Gateway
- **Purpose**: Provides internet access for public subnets
- **Routing**: Default route (0.0.0.0/0) in public route table points to IGW
- **Dependencies**: Must exist before NAT Gateway can be created

#### NAT Gateway Architecture
```
Component: NAT Gateway
Location: Public Subnet (10.2.3.0/24, AZ-a)
Elastic IP: Dedicated static public IP
Purpose: Enable private subnet internet egress
```

**Traffic Flow**:
1. EKS node in private subnet initiates outbound connection
2. Traffic routed to NAT Gateway via private route table
3. NAT Gateway performs source NAT translation
4. Traffic exits via Internet Gateway with Elastic IP as source
5. Return traffic follows reverse path

**Cost Consideration**: ~$45/month + data processing charges

#### Route Tables

**Public Route Table**:
```hcl
Destination: 0.0.0.0/0
Target: Internet Gateway
Local Route: 10.2.0.0/16 (implicit)
```

**Private Route Table**:
```hcl
Destination: 0.0.0.0/0
Target: NAT Gateway
Local Route: 10.2.0.0/16 (implicit)
```

**Why This Matters**: 
- EKS nodes can pull container images from DockerHub/ECR
- Worker nodes can communicate with EKS control plane
- Pods can access external APIs
- RDS can download patches (through private subnet routing)

### GCP Network Architecture

#### VPC Configuration
```hcl
Mode: Custom (not auto)
Routing: Regional
Auto-create subnets: Disabled
```

**Rationale**: Custom mode provides full control over IP ranges

#### Primary Subnet
```
CIDR: 10.1.0.0/24 (256 IPs)
Region: us-central1
Purpose: GKE node primary IPs
Private Google Access: Enabled
```

#### Secondary IP Ranges

**Pods Range**:
```
Name: acme-widget-pods-dev
CIDR: 10.1.16.0/20 (4,096 IPs)
Purpose: Kubernetes pod IPs
```

**Services Range**:
```
Name: acme-widget-services-dev
CIDR: 10.1.32.0/20 (4,096 IPs)
Purpose: Kubernetes service IPs (ClusterIP)
```

**Why Secondary Ranges**:
- GKE uses IP alias mode for better performance
- Enables direct pod-to-pod communication without overlay
- Google Cloud routes know about pod IPs natively
- Better integration with GCP services

#### Private Service Connection

**Global Address Reservation**:
```hcl
Name: acme-widget-private-ip-dev
Purpose: VPC_PEERING
Address Type: INTERNAL
Prefix Length: /16
Network: VPC reference
```

**VPC Peering Configuration**:
```hcl
Service: servicenetworking.googleapis.com
Network: VPC reference
Reserved Ranges: Global address name
```

**How It Works**:
1. Google reserves a /16 address block
2. VPC peering established with Google's managed services network
3. Cloud SQL receives private IP from reserved range
4. GKE nodes can reach Cloud SQL via private routing
5. No public IP needed on Cloud SQL instance

#### Firewall Rules

**Rule 1: Internal Communication**
```hcl
Name: allow-internal
Protocols: TCP (all), UDP (all), ICMP
Source Ranges: 10.1.0.0/24, 10.1.16.0/20, 10.1.32.0/20
Target Tags: gke-node
Direction: Ingress
Priority: 1000 (default)
```

**Rule 2: Health Checks**
```hcl
Name: allow-health-check
Protocol: TCP (all ports)
Source Ranges: 35.191.0.0/16, 130.211.0.0/22
Target Tags: gke-node
Direction: Ingress
```

**Rule 3: SSH via IAP**
```hcl
Name: allow-ssh
Protocol: TCP
Port: 22
Source Range: 35.235.240.0/20 (Identity-Aware Proxy)
Target Tags: gke-node
Direction: Ingress
```

**Default Deny**: GCP implicitly denies all traffic not explicitly allowed

#### Private Google Access

**Configuration**:
```hcl
Subnet Setting: private_ip_google_access = true
```

**Enables**:
- GKE nodes access GCP APIs without public IPs
- Pull images from Google Container Registry (GCR)
- Access Google Cloud Storage
- Use Cloud Logging and Monitoring
- All via Google's private network

**Traffic Path**:
```
GKE Node (10.1.0.x) 
  → Google APIs (internal routing)
  → No internet egress needed
```

---

## Security Configuration

### AWS Security

#### EKS Cluster Security Group
```hcl
Name: acme-widget-eks-cluster-sg-dev
Purpose: Control plane communication
```

**Ingress Rules**:
- Port 443: HTTPS from 0.0.0.0/0 (control plane API access)

**Egress Rules**:
- All traffic to 0.0.0.0/0 (control plane to nodes communication)

**Why Open Ingress**:
- For demo purposes, allows kubectl access from anywhere
- Production: Restrict to specific CIDR blocks or VPN

#### RDS Security Group
```hcl
Name: acme-widget-rds-sg-dev
Purpose: Database access control
```

**Ingress Rules**:
- Port 5432: PostgreSQL from VPC CIDR (10.2.0.0/16)
- Description: "PostgreSQL from VPC"

**Egress Rules**:
- All traffic to 0.0.0.0/0

**Best Practice**: Only allows database access from within VPC

### GCP Security

#### Network Policy
```hcl
Enabled: true
Provider: Calico (PROVIDER_UNSPECIFIED)
```

**Purpose**: Pod-to-pod network segmentation capability

#### Private Cluster Configuration
```hcl
Enable Private Nodes: true
Enable Private Endpoint: false (for demo convenience)
Master CIDR: 172.16.0.0/28 (16 IPs for control plane)
```

**Implications**:
- Nodes have no public IPs
- Control plane has public endpoint for kubectl access
- Production: Enable private endpoint and use bastion or VPN

#### Master Authorized Networks
```hcl
Current: 0.0.0.0/0 (open for demo)
Production Recommendation: Specific CIDR blocks or Cloud NAT
```

#### Workload Identity
```hcl
Workload Pool: ${project_id}.svc.id.goog
```

**Purpose**: Secure pod-to-GCP service authentication without service account keys

**How It Works**:
1. Pod configured with Kubernetes service account
2. Workload Identity binds KSA to GCP service account
3. Pod can assume GCP SA permissions
4. No credential files needed in container

---

## Compute Resources

### AWS EKS

#### Cluster Configuration
```hcl
Name: acme-widget-eks-dev
Version: 1.28
Endpoint Access: Public + Private
Subnets: All 4 (2 public, 2 private)
Security Groups: eks-cluster-sg
```

**Control Plane**:
- Fully managed by AWS
- Multi-AZ by default
- Auto-scaled by AWS
- API endpoint available at cluster endpoint

#### Node Group Configuration
```hcl
Name: acme-widget-node-group-dev
Instance Type: t3.medium (2 vCPU, 4GB RAM)
Scaling: Min 1, Desired 2, Max 3
Subnets: Private subnets only
Disk: 20GB (default EBS gp2)
```

**Node IAM Policies**:
1. AmazonEKSWorkerNodePolicy
2. AmazonEKS_CNI_Policy (VPC CNI)
3. AmazonEC2ContainerRegistryReadOnly

**Why t3.medium**:
- Burstable performance suitable for demos
- Cost-effective ($0.0416/hour = ~$30/month per node)
- Sufficient for moderate workloads

### GCP GKE

#### Cluster Configuration
```hcl
Name: acme-widget-gke-dev
Location: us-central1-a (zonal)
Network: acme-widget-vpc-dev
Subnetwork: acme-widget-subnet-dev
Remove Default Node Pool: true
```

**IP Allocation Policy**:
```hcl
Cluster Secondary Range: acme-widget-pods-dev (10.1.16.0/20)
Services Secondary Range: acme-widget-services-dev (10.1.32.0/20)
```

**Control Plane**:
- Fully managed by Google
- Multi-zonal (for regional) or single-zone (for zonal)
- Auto-patched by Google

#### Node Pool Configuration
```hcl
Name: acme-widget-node-pool-dev
Machine Type: e2-medium (2 vCPU, 4GB RAM)
Node Count: 2 (initial)
Autoscaling: Min 1, Max 3
Disk: 20GB PD-Standard
```

**Node Features**:
- Auto-repair: Enabled
- Auto-upgrade: Enabled
- Shielded VM: Secure boot + integrity monitoring
- Workload Identity: GKE_METADATA mode

**Why e2-medium**:
- Shared-core suitable for demos
- Cost-effective (~$25/month per node with sustained use discount)
- General-purpose balanced performance

---

## Database Configuration

### AWS RDS PostgreSQL

#### Instance Configuration
```hcl
Identifier: acme-widget-db-dev
Engine: postgres
Engine Version: 15.3
Instance Class: db.t3.micro (1 vCPU, 1GB RAM)
```

#### Storage Configuration
```hcl
Allocated Storage: 20GB
Storage Type: GP2 (General Purpose SSD)
Storage Encrypted: true
Max Allocated Storage: N/A (auto-scaling disabled for demo)
```

#### Network Configuration
```hcl
VPC Security Groups: rds-sg
DB Subnet Group: private_1 + private_2
Publicly Accessible: false
Availability: Single-AZ (dev), Multi-AZ (prod)
```

#### Backup Configuration
```hcl
Backup Retention: 7 days
Backup Window: 03:00-04:00 UTC
Maintenance Window: Monday 04:00-05:00 UTC
Skip Final Snapshot: true (dev only)
Deletion Protection: false (dev only)
```

#### Database Configuration
```hcl
Database Name: widget_orders_dev
Master Username: dbadmin
Master Password: Random 16-char (sensitive)
Port: 5432 (default PostgreSQL)
```

**Connection String Format**:
```
postgresql://dbadmin:[PASSWORD]@[ENDPOINT]:5432/widget_orders_dev
```

### GCP Cloud SQL PostgreSQL

#### Instance Configuration
```hcl
Name: acme-widget-db-dev
Database Version: POSTGRES_15
Region: us-central1
Tier: db-f1-micro (0.6GB RAM, shared CPU)
```

#### Storage Configuration
```hcl
Disk Type: PD-SSD (Performance optimized)
Disk Size: 10GB
Disk Autoresize: Enabled (default)
```

#### Network Configuration
```hcl
IPv4 Enabled: false (NO PUBLIC IP)
Private Network: VPC ID
Require SSL: false (dev), true (prod recommended)
```

**How Connection Works**:
1. Cloud SQL receives private IP from VPC peering range
2. GKE nodes resolve Cloud SQL to private IP
3. Traffic stays within Google's network
4. No Cloud SQL Proxy needed

#### Backup Configuration
```hcl
Automated Backups: Enabled
Start Time: 03:00 UTC
Point-in-Time Recovery: Enabled
Transaction Log Retention: 7 days
Backup Retention: 7 backups
```

#### Maintenance Configuration
```hcl
Maintenance Window: Monday, 04:00 UTC
Update Track: stable
```

#### Database Configuration
```hcl
Database Name: widget_orders_dev
User: dbadmin
Password: Random 16-char (sensitive)
```

**Connection String Format**:
```
postgresql://dbadmin:[PASSWORD]@[PRIVATE_IP]:5432/widget_orders_dev
```

---

## IAM and Access Control

### AWS IAM Roles

#### EKS Cluster Role
```hcl
Name: acme-widget-eks-cluster-role-dev
Trust Policy: eks.amazonaws.com service principal
Attached Policies:
  - AmazonEKSClusterPolicy
  - AmazonEKSVPCResourceController
```

**Purpose**: 
- Allows EKS to manage AWS resources on your behalf
- Create/manage ENIs for pods
- Manage security groups
- Write to CloudWatch Logs

#### EKS Node Role
```hcl
Name: acme-widget-eks-node-role-dev
Trust Policy: ec2.amazonaws.com service principal
Attached Policies:
  - AmazonEKSWorkerNodePolicy (EC2 management)
  - AmazonEKS_CNI_Policy (VPC networking)
  - AmazonEC2ContainerRegistryReadOnly (pull images)
```

**Purpose**:
- Nodes can join EKS cluster
- VPC CNI can manage pod networking
- Pull container images from ECR

### GCP IAM

#### Default GKE Node Service Account
```
Default: PROJECT_NUMBER-compute@developer.gserviceaccount.com
Scopes: cloud-platform (full API access)
```

**Why Full Scope**:
- Nodes need access to multiple GCP services
- Actual permissions controlled by IAM policies, not scopes
- Follows GCP best practice for GKE

#### Workload Identity Configuration
```hcl
Workload Pool: PROJECT_ID.svc.id.goog
Node Metadata: GKE_METADATA
```

**Setup for Pod-level IAM**:
1. Create GCP Service Account
2. Create Kubernetes Service Account
3. Bind KSA to GSA via annotation
4. Pod uses KSA, gets GSA permissions

---

## Terraform Implementation

### Provider Configuration

#### AWS Provider
```hcl
Version: ~> 5.0
Region: Variable-driven
Default Tags: Automatic tagging of all resources
```

**Configuration**:
```hcl
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "acme-widget-platform"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
```

#### GCP Provider
```hcl
Version: ~> 5.0
Project: Variable-driven
Region: Variable-driven
```

**Configuration**:
```hcl
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
```

### Resource Conditional Creation Pattern

**Implementation**:
```hcl
resource "type" "name" {
  count = var.enable_cloud ? 1 : 0
  # ... resource configuration
}
```

**Why This Works**:
- count = 0 means resource isn't created
- count = 1 means single resource created
- Access via resource_type.name[0]
- Outputs conditionally return null

**Example**:
```hcl
output "cluster_name" {
  value = var.enable_gcp ? google_container_cluster.primary[0].name : null
}
```

### State Management

#### Backend Configuration
```hcl
terraform {
  cloud {
    organization = "acme-corp"
    workspaces {
      name = "acme-multicloud-demo"
    }
  }
}
```

**Features**:
- Remote state storage
- State locking (automatic)
- State encryption at rest
- Version history
- Collaboration features

### Variable Management

#### Variable Precedence (highest to lowest)
1. Command-line flags: `-var="enable_gcp=false"`
2. `*.tfvars` files: `-var-file="environments/dev.tfvars"`
3. Environment variables: `TF_VAR_enable_gcp=false`
4. Default values in `variables.tf`

**Best Practice**: Use environment-specific tfvars files

---

## Operational Procedures

### Deployment Workflow

#### Initial Deployment
```bash
# 1. Authenticate to cloud providers
aws configure
gcloud auth application-default login

# 2. Login to Terraform Cloud
terraform login

# 3. Initialize Terraform
terraform init

# 4. Validate configuration
terraform validate

# 5. Plan deployment
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# 6. Review plan output carefully

# 7. Apply deployment
terraform apply tfplan

# 8. Verify outputs
terraform output
```

#### Adding a Cloud

**Scenario**: Start with AWS, add GCP later

```bash
# Initial: Only AWS
# In dev.tfvars: enable_aws=true, enable_gcp=false
terraform apply -var-file="environments/dev.tfvars"

# Later: Add GCP
# Edit dev.tfvars: enable_gcp=true
terraform plan -var-file="environments/dev.tfvars"
# Review: Should show only GCP resources being added

terraform apply -var-file="environments/dev.tfvars"
```

#### Removing a Cloud

```bash
# Edit dev.tfvars: enable_aws=false
terraform plan -var-file="environments/dev.tfvars"
# Review: Should show only AWS resources being destroyed

terraform apply -var-file="environments/dev.tfvars"
```

### Accessing Kubernetes Clusters

#### AWS EKS
```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name acme-widget-eks-dev \
  --alias eks-dev

# Verify access
kubectl get nodes
kubectl get pods -A

# View EKS-specific resources
kubectl get pods -n kube-system
```

#### GCP GKE
```bash
# Update kubeconfig
gcloud container clusters get-credentials acme-widget-gke-dev \
  --zone us-central1-a \
  --project your-gcp-project-id

# Verify access
kubectl get nodes
kubectl get pods -A

# View GKE-specific resources
kubectl get pods -n kube-system
```

### Database Access

#### AWS RDS
```bash
# Get connection details
ENDPOINT=$(terraform output -raw aws_database_endpoint)
PASSWORD=$(terraform output -raw aws_database_password)

# Connect via psql (from within VPC)
psql -h $ENDPOINT -U dbadmin -d widget_orders_dev

# Connection via bastion/VPN required for external access
```

#### GCP Cloud SQL
```bash
# Get connection details
PRIVATE_IP=$(terraform output -raw gcp_database_private_ip)
PASSWORD=$(terraform output -raw gcp_database_password)

# Connect via psql (from GKE pod or with Cloud SQL Proxy)
psql -h $PRIVATE_IP -U dbadmin -d widget_orders_dev
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Terraform State Locked
**Symptoms**: "Error acquiring the state lock"

**Solution**:
```bash
# Check Terraform Cloud workspace
# Navigate to: Settings → General → Force Unlock

# Or wait for lock to auto-release (usually 15 minutes)
```

#### Issue: EKS Nodes Not Joining Cluster
**Symptoms**: Nodes created but not visible in `kubectl get nodes`

**Potential Causes**:
1. No NAT Gateway - nodes can't reach EKS API
2. Wrong IAM role permissions
3. Security group blocking communication

**Diagnosis**:
```bash
# Check node status in AWS Console
# Look for errors in CloudWatch Logs: /aws/eks/cluster-name/cluster

# Verify NAT Gateway exists and has route
aws ec2 describe-nat-gateways
aws ec2 describe-route-tables
```

#### Issue: GKE Nodes Can't Pull Images
**Symptoms**: Pods stuck in `ImagePullBackOff`

**Potential Causes**:
1. Private Google Access not enabled
2. Node service account lacks permissions
3. Firewall rules blocking egress

**Diagnosis**:
```bash
# Check node logs
kubectl logs -n kube-system -l k8s-app=kubelet

# Verify private Google access
gcloud compute networks subnets describe acme-widget-subnet-dev \
  --region us-central1 --format="value(privateIpGoogleAccess)"

# Should return "True"
```

#### Issue: Cannot Connect to Database
**Symptoms**: Connection timeout from application pods

**AWS RDS Debug**:
```bash
# Verify security group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*rds-sg*"

# Check inbound rules allow 5432 from VPC CIDR

# Verify RDS is in private subnet
aws rds describe-db-instances \
  --db-instance-identifier acme-widget-db-dev \
  --query 'DBInstances[0].PubliclyAccessible'

# Should return "false"
```

**GCP Cloud SQL Debug**:
```bash
# Verify private IP
gcloud sql instances describe acme-widget-db-dev \
  --format="value(ipAddresses)"

# Verify VPC peering
gcloud services vpc-peerings list \
  --service=servicenetworking.googleapis.com \
  --network=acme-widget-vpc-dev
```

#### Issue: Terraform Plan Shows Unexpected Changes
**Symptoms**: Resources want to be recreated/modified on every plan

**Common Causes**:
1. Random password regeneration
2. Computed values changing
3. API defaults different from Terraform

**Solution**:
```hcl
# Add lifecycle blocks to sensitive resources
resource "random_password" "db_password" {
  length  = 16
  special = true
  
  lifecycle {
    ignore_changes = [
      length,
      special
    ]
  }
}
```

### Validation Commands

#### Verify AWS Resources
```bash
# VPC and networking
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*acme-widget*"
aws ec2 describe-subnets --filters "Name=tag:Name,Values=*acme-widget*"
aws ec2 describe-nat-gateways
aws ec2 describe-route-tables

# EKS
aws eks describe-cluster --name acme-widget-eks-dev
aws eks list-nodegroups --cluster-name acme-widget-eks-dev

# RDS
aws rds describe-db-instances --db-instance-identifier acme-widget-db-dev
```

#### Verify GCP Resources
```bash
# VPC and networking
gcloud compute networks describe acme-widget-vpc-dev
gcloud compute networks subnets describe acme-widget-subnet-dev \
  --region us-central1

# Firewall
gcloud compute firewall-rules list --filter="network:acme-widget-vpc-dev"

# GKE
gcloud container clusters describe acme-widget-gke-dev \
  --zone us-central1-a

# Cloud SQL
gcloud sql instances describe acme-widget-db-dev
```

---

## Performance Tuning

### EKS Optimization
- Enable cluster autoscaler for dynamic scaling
- Use gp3 EBS volumes for better IOPS/cost
- Implement pod disruption budgets
- Configure horizontal pod autoscaling

### GKE Optimization
- Use regional clusters for higher availability
- Enable vertical pod autoscaling
- Use node auto-provisioning for cost optimization
- Implement workload separation via node pools

### Database Optimization
- Right-size instances based on workload metrics
- Enable connection pooling in applications
- Implement read replicas for read-heavy workloads
- Monitor slow query logs

---

## Cost Optimization Strategies

### Development Environment
- Use smaller instance types
- Enable autoscaling with low minimums
- Use spot/preemptible instances for non-critical workloads
- Implement scheduled scaling (scale down nights/weekends)
- Use lower-tier database instances

### Production Considerations
- Reserved instances for predictable workloads
- Committed use discounts (GCP)
- Implement tagging strategy for cost allocation
- Regular right-sizing reviews
- Implement cost monitoring and alerts

---

**Document Version**: 1.2  
**Last Updated**: October 26, 2025  
**Maintained by**: DevOps Engineering Team
