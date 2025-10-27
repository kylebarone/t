# ACME Multi-Cloud Infrastructure Demo

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Provider-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![GCP](https://img.shields.io/badge/GCP-Provider-4285F4?logo=google-cloud)](https://cloud.google.com/)

## Overview

This repository demonstrates enterprise-grade multi-cloud infrastructure management using Terraform and HashiCorp products. It showcases a realistic scenario where ACME Corporation's IT team operates infrastructure across both Google Cloud Platform (GCP) and Amazon Web Services (AWS).

### Business Context

**Scenario:** ACME Corporation's engineering team primarily operates on GCP. Through a recent acquisition, they've inherited a Kubernetes-based service running on AWS. The IT team now needs to manage and operate infrastructure across both cloud providers using a unified Infrastructure-as-Code approach.

### Key Features

- ✅ **Multi-Cloud Toggle Pattern** - Enable/disable individual clouds via boolean flags
- ✅ **Production-Ready Networking** - Complete VPC, subnets, NAT, routing, and firewall configurations
- ✅ **Kubernetes-Centric** - Managed Kubernetes on both platforms (GKE/EKS)
- ✅ **Private-First Architecture** - Databases and nodes deployed in private networks
- ✅ **Modular Design** - Reusable Terraform modules for each component
- ✅ **Security Best Practices** - Defense-in-depth with proper IAM, security groups, and encryption
- ✅ **Infrastructure as Code** - Single codebase manages both cloud environments

## Architecture

### Cloud Resources

| Component | GCP | AWS |
|-----------|-----|-----|
| **Network** | Custom VPC with secondary ranges | VPC with public/private subnets |
| **Kubernetes** | GKE Private Cluster | EKS Cluster |
| **Database** | Cloud SQL PostgreSQL (Private IP) | RDS PostgreSQL (Private) |
| **Networking** | Private Google Access, VPC Peering | NAT Gateway, Internet Gateway |
| **Security** | Firewall Rules, Workload Identity | Security Groups, IAM Roles |

### Network Architecture

**GCP (Primary Platform):**
```
Primary Subnet: 10.1.0.0/24
Pod Range:      10.1.16.0/20 (4,096 IPs)
Service Range:  10.1.32.0/20 (4,096 IPs)
```

**AWS (Acquired Service):**
```
VPC:            10.2.0.0/16
Private:        10.2.1.0/24, 10.2.2.0/24
Public:         10.2.3.0/24, 10.2.4.0/24
```

## Quick Start

### Prerequisites

- **Terraform** >= 1.0
- **GCP Account** with billing enabled
- **AWS Account** with appropriate permissions
- **gcloud CLI** configured
- **aws CLI** configured
- **kubectl** installed

### Authentication Setup

**For GCP:**
```bash
gcloud auth application-default login
export GOOGLE_PROJECT="your-project-id"
```

**For AWS:**
```bash
aws configure
# Or use environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

### Deployment Steps

1. **Clone and Navigate**
   ```bash
   cd acme-multicloud-demo
   ```

2. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan Deployment**
   ```bash
   terraform plan -out=tfplan
   ```

5. **Apply Infrastructure**
   ```bash
   terraform apply tfplan
   ```

6. **Configure kubectl Access**
   ```bash
   # For GCP
   gcloud container clusters get-credentials $(terraform output -raw gcp_cluster_name) \
     --region us-central1

   # For AWS
   aws eks update-kubeconfig --name $(terraform output -raw aws_cluster_name) \
     --region us-east-1
   ```

## Configuration Options

### Multi-Cloud Toggle

Enable or disable specific cloud providers:

```hcl
# terraform.tfvars
enable_gcp = true   # Deploy GCP infrastructure
enable_aws = true   # Deploy AWS infrastructure
```

**Use Cases:**
- Start with single cloud, expand later
- Cost optimization during development
- Disaster recovery testing
- Gradual cloud migration

### Environment-Specific Configuration

The project includes separate configurations for different environments:

- `environments/dev/` - Development environment with cost-optimized settings
- `environments/prod/` - Production environment with HA and enhanced security

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project identifier for resource naming | `acme-widget` |
| `environment` | Environment name (dev/prod/staging) | `dev` |
| `gcp_project` | GCP Project ID | Required |
| `gcp_region` | GCP deployment region | `us-central1` |
| `aws_region` | AWS deployment region | `us-east-1` |
| `enable_gcp` | Deploy GCP resources | `true` |
| `enable_aws` | Deploy AWS resources | `true` |

## Module Structure

```
modules/
├── gcp-network/       # GCP VPC, subnets, firewall rules
├── gcp-gke/           # Google Kubernetes Engine cluster
├── gcp-database/      # Cloud SQL PostgreSQL
├── aws-network/       # AWS VPC, subnets, NAT Gateway
├── aws-eks/           # Elastic Kubernetes Service cluster
└── aws-database/      # RDS PostgreSQL
```

Each module is self-contained with:
- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `README.md` - Module documentation

## Security Considerations

### Network Security

- **Private Subnets**: All databases and Kubernetes nodes deployed in private networks
- **No Public IPs**: Database instances have no public IP addresses
- **Controlled Egress**: NAT Gateway (AWS) and Private Google Access (GCP)

### Access Control

- **IAM Roles**: Least-privilege policies for all service accounts
- **Security Groups**: Port-specific access rules
- **Workload Identity**: GKE pods authenticate to GCP services securely
- **EKS IAM Roles**: Service accounts with IRSA (IAM Roles for Service Accounts)

### Data Protection

- **Encryption at Rest**: Enabled for all databases
- **Automated Backups**: 7-day retention with point-in-time recovery
- **Secret Management**: Random password generation, no hardcoded secrets

## Outputs

After successful deployment, Terraform provides:

### Network Information
- VPC/Network IDs and CIDR blocks
- Subnet IDs and IP ranges
- NAT Gateway public IP (AWS)

### Cluster Information
- Kubernetes cluster endpoints
- kubectl connection commands
- Cluster versions and locations

### Database Information
- Connection endpoints
- Private IP addresses
- Instance identifiers

## Cost Estimation

**Development Environment (Minimal):**
- GCP: ~$150-200/month
- AWS: ~$150-200/month
- **Total**: ~$300-400/month

**Production Environment (HA):**
- GCP: ~$500-700/month
- AWS: ~$500-700/month
- **Total**: ~$1,000-1,400/month

**Cost Optimization Tips:**
- Use `terraform destroy` when not in use
- Leverage spot/preemptible instances for dev
- Adjust instance types based on workload
- Enable autoscaling with appropriate limits

## Operational Tasks

### Accessing Kubernetes Clusters

**GCP:**
```bash
gcloud container clusters get-credentials acme-widget-gke-dev \
  --region us-central1 \
  --project YOUR_PROJECT_ID

kubectl get nodes
```

**AWS:**
```bash
aws eks update-kubeconfig \
  --name acme-widget-eks-dev \
  --region us-east-1

kubectl get nodes
```

### Database Connections

**GCP Cloud SQL:**
```bash
# Using Cloud SQL Proxy
cloud_sql_proxy -instances=PROJECT:REGION:INSTANCE=tcp:5432

# Connection string
psql "host=127.0.0.1 port=5432 dbname=widget user=postgres"
```

**AWS RDS:**
```bash
# Connect from within VPC or via bastion host
psql -h your-rds-endpoint.rds.amazonaws.com -U postgres -d widget
```

### Scaling Operations

**Scale GKE Node Pool:**
```bash
gcloud container clusters resize acme-widget-gke-dev \
  --node-pool primary-pool \
  --num-nodes 3 \
  --region us-central1
```

**Scale EKS Node Group:**
```bash
aws eks update-nodegroup-config \
  --cluster-name acme-widget-eks-dev \
  --nodegroup-name acme-widget-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=3
```

## Troubleshooting

### Common Issues

**Issue: "Error creating Network"**
```bash
# Ensure GCP APIs are enabled
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

**Issue: "Error creating EKS Cluster"**
```bash
# Verify AWS credentials and permissions
aws sts get-caller-identity
aws iam list-attached-role-policies --role-name your-role
```

**Issue: "Cannot connect to database"**
```bash
# Verify network connectivity
# For GCP: Check VPC peering status
gcloud services vpc-peerings list --network=your-network

# For AWS: Verify security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

## Cleanup

To destroy all infrastructure:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Confirm by typing 'yes'
```

**Warning:** This will delete all resources including databases. Ensure backups are in place if needed.

## Project Structure

```
acme-multicloud-demo/
├── README.md                  # This file
├── main.tf                    # Root module configuration
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output definitions
├── providers.tf               # Provider configurations
├── terraform.tfvars.example   # Example variable values
├── versions.tf                # Terraform and provider versions
├── modules/                   # Reusable Terraform modules
│   ├── gcp-network/
│   ├── gcp-gke/
│   ├── gcp-database/
│   ├── aws-network/
│   ├── aws-eks/
│   └── aws-database/
├── environments/              # Environment-specific configs
│   ├── dev/
│   └── prod/
├── docs/                      # Additional documentation
│   └── ARCHITECTURE.md        # Detailed architecture guide
└── scripts/                   # Helper scripts
    ├── setup.sh               # Initial setup script
    └── validate.sh            # Validation script
```

## Contributing

This is a demonstration project for technical interviews. For production use:

1. Implement remote state backend (Terraform Cloud or S3/GCS)
2. Add CI/CD pipeline integration
3. Implement proper secret management (Vault, Secret Manager)
4. Add comprehensive monitoring and alerting
5. Implement disaster recovery procedures

## Support and Documentation

- **Architecture Details**: See `docs/ARCHITECTURE.md`
- **Module Documentation**: Check README in each module directory
- **Terraform Registry**: https://registry.terraform.io/
- **AWS Provider Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **GCP Provider Docs**: https://registry.terraform.io/providers/hashicorp/google/latest/docs

## License

This project is provided as-is for demonstration and educational purposes.

## Authors

ACME Corporation Infrastructure Team

---

**Version:** 1.2  
**Last Updated:** October 26, 2025  
**Status:** Production-Ready Demo
