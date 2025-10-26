# ACME Multi-Cloud Infrastructure Demo

Enterprise-grade Terraform infrastructure demonstrating production-ready multi-cloud deployment patterns across AWS and GCP.

## Quick Start

```bash
# 1. Configure Terraform Cloud
terraform login

# 2. Initialize Terraform
terraform init

# 3. Select environment and deploy
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# 4. Connect to deployed clusters
# AWS
aws eks update-kubeconfig --region us-east-1 --name acme-widget-eks-dev

# GCP
gcloud container clusters get-credentials acme-widget-gke-dev \
  --zone us-central1-a --project your-gcp-project-id
```

## What This Demo Provides

### Multi-Cloud Infrastructure
- **AWS**: VPC, EKS, RDS PostgreSQL with complete networking (NAT Gateway, route tables, security groups)
- **GCP**: VPC, GKE, Cloud SQL PostgreSQL with private networking (VPC peering, firewall rules)
- **Toggle Pattern**: Deploy to one cloud, both clouds, or scale down as needed

### Production-Ready Networking
- ✅ Private subnets for compute and databases
- ✅ NAT Gateway for private subnet internet access (AWS)
- ✅ Private Google Access for API calls (GCP)
- ✅ Proper route tables and firewall rules
- ✅ Security groups with least-privilege access
- ✅ Load balancer subnet tagging for Kubernetes

### Kubernetes Platforms
- **EKS**: Managed Kubernetes 1.28 with 2 t3.medium nodes
- **GKE**: Private GKE with 2 e2-medium nodes and workload identity
- Both configured with autoscaling, managed node groups, and proper IAM/RBAC

### Database Infrastructure
- **RDS PostgreSQL 15.3**: Private, encrypted, with automated backups
- **Cloud SQL PostgreSQL 15**: Private IP only, PITR enabled
- Secure password management via Terraform random provider

## Project Structure

```
v1-demo-terraform/
├── terraform.tf           # Terraform Cloud backend + provider versions
├── variables.tf           # Input variable definitions
├── aws.tf                 # AWS infrastructure (VPC, EKS, RDS)
├── gcp.tf                 # GCP infrastructure (VPC, GKE, Cloud SQL)
├── outputs.tf             # Exported values for both clouds
├── environments/
│   ├── dev.tfvars        # Development environment configuration
│   └── prod.tfvars       # Production environment configuration
└── modules/
    └── widget-api/       # Placeholder for application deployment module
        └── main.tf       # Kubernetes deployment configuration (future)
```

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) configured
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for cluster management
- Git for version control

### Cloud Provider Setup

#### AWS
1. Create AWS account or use existing
2. Configure AWS CLI:
   ```bash
   aws configure
   ```
3. Ensure IAM permissions for:
   - VPC and subnet management
   - EKS cluster creation
   - RDS instance creation
   - IAM role and policy management

#### GCP
1. Create GCP project or use existing
2. Enable required APIs:
   ```bash
   gcloud services enable \
     compute.googleapis.com \
     container.googleapis.com \
     sqladmin.googleapis.com \
     servicenetworking.googleapis.com
   ```
3. Configure application default credentials:
   ```bash
   gcloud auth application-default login
   ```

### Terraform Cloud Setup
1. Create account at [app.terraform.io](https://app.terraform.io)
2. Create organization named `acme-corp`
3. Create workspace named `acme-multicloud-demo`
4. Set workspace execution mode to "Local" or configure remote execution
5. Login via CLI:
   ```bash
   terraform login
   ```

## Configuration

### Environment Files

Edit `environments/dev.tfvars`:

```hcl
environment    = "dev"
project_name   = "acme-widget"
gcp_project_id = "your-actual-gcp-project-id"  # CHANGE THIS
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"
aws_region     = "us-east-1"

# Toggle cloud providers
enable_gcp = true
enable_aws = true

# Database configuration
db_name     = "widget_orders_dev"
db_username = "dbadmin"
```

**Critical**: Update `gcp_project_id` with your actual GCP project ID.

### Multi-Cloud Toggle Patterns

Deploy to both clouds:
```hcl
enable_gcp = true
enable_aws = true
```

AWS only:
```hcl
enable_gcp = false
enable_aws = true
```

GCP only:
```hcl
enable_gcp = true
enable_aws = false
```

## Deployment Instructions

### Standard Deployment

```bash
# 1. Review planned changes
terraform plan -var-file="environments/dev.tfvars"

# 2. Apply infrastructure
terraform apply -var-file="environments/dev.tfvars"

# 3. View outputs
terraform output
```

### Selective Cloud Deployment

Deploy AWS only first:
```bash
# Edit environments/dev.tfvars: enable_gcp=false, enable_aws=true
terraform apply -var-file="environments/dev.tfvars"
```

Then add GCP:
```bash
# Edit environments/dev.tfvars: enable_gcp=true
terraform apply -var-file="environments/dev.tfvars"
```

### Accessing Deployed Resources

#### Kubernetes Clusters

**AWS EKS:**
```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name acme-widget-eks-dev

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

**GCP GKE:**
```bash
# Update kubeconfig
gcloud container clusters get-credentials acme-widget-gke-dev \
  --zone us-central1-a \
  --project your-gcp-project-id

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

#### Databases

Database connection details are available via outputs:
```bash
# AWS RDS
terraform output aws_database_endpoint
terraform output aws_database_password

# GCP Cloud SQL
terraform output gcp_database_connection
terraform output gcp_database_password
```

**Note:** Passwords are marked sensitive; use `-json` flag to retrieve:
```bash
terraform output -json aws_database_password | jq -r
```

## Network Architecture

### AWS (10.2.0.0/16)
```
Internet Gateway
      ↓
Public Subnets (10.2.3.0/24, 10.2.4.0/24)
      ↓
NAT Gateway
      ↓
Private Subnets (10.2.1.0/24, 10.2.2.0/24)
      ↓
EKS Nodes + RDS
```

### GCP (10.1.0.0/24)
```
Private GKE Nodes (10.1.0.0/24)
├── Pod Network (10.1.16.0/20)
└── Service Network (10.1.32.0/20)
      ↓
Cloud SQL (Private IP via VPC Peering)
```

## Cost Estimates

### Development Environment (Approximate Monthly)

**AWS:**
- EKS Control Plane: $73
- EC2 t3.medium × 2: ~$60
- RDS db.t3.micro: ~$15
- NAT Gateway: ~$45
- **Total AWS: ~$193/month**

**GCP:**
- GKE Control Plane: $73
- e2-medium × 2: ~$50
- Cloud SQL db-f1-micro: ~$10
- **Total GCP: ~$133/month**

**Combined: ~$326/month**

### Cost Optimization Tips
- Use spot instances (AWS) / preemptible nodes (GCP) for dev
- Scale down node counts outside business hours
- Use smaller database instances for development
- Leverage free tier where applicable
- Set up billing alerts

## Troubleshooting

### Common Issues

#### Terraform Cloud Authentication
```bash
# If you see authentication errors
terraform logout
terraform login
```

#### AWS EKS Cluster Not Accessible
```bash
# Ensure your AWS credentials are configured
aws sts get-caller-identity

# Update kubeconfig with correct region and cluster name
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
```

#### GCP Cloud SQL Connection Timeout
- Verify private service connection is established
- Check firewall rules allow traffic from GKE node ranges
- Ensure Cloud SQL is using private IP only

#### Terraform State Locked
```bash
# If state is locked in Terraform Cloud
# Go to app.terraform.io → workspace → Settings → Force Unlock
```

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Format Terraform files
terraform fmt -recursive

# Check Terraform state
terraform show

# List all resources
terraform state list
```

## Monitoring and Operations

### Access Cloud Consoles

**AWS:**
- [EKS Console](https://console.aws.amazon.com/eks/)
- [RDS Console](https://console.aws.amazon.com/rds/)
- [VPC Console](https://console.aws.amazon.com/vpc/)

**GCP:**
- [GKE Console](https://console.cloud.google.com/kubernetes/)
- [Cloud SQL Console](https://console.cloud.google.com/sql/)
- [VPC Console](https://console.cloud.google.com/networking/)

### View Infrastructure Metrics

**AWS CloudWatch:**
```bash
# View EKS cluster metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EKS \
  --metric-name cluster_failed_node_count \
  --dimensions Name=ClusterName,Value=acme-widget-eks-dev
```

**GCP Monitoring:**
```bash
# View GKE cluster status
gcloud container clusters describe acme-widget-gke-dev \
  --zone us-central1-a
```

## Cleanup

### Destroy Infrastructure

```bash
# Destroy everything
terraform destroy -var-file="environments/dev.tfvars"

# Destroy single cloud (edit tfvars first to disable)
# Set enable_aws=false or enable_gcp=false
terraform destroy -var-file="environments/dev.tfvars"
```

### Manual Cleanup Checks

After Terraform destroy, verify:

**AWS:**
- EKS cluster deleted
- RDS instance removed
- NAT Gateway and Elastic IP released
- VPC and subnets deleted

**GCP:**
- GKE cluster deleted
- Cloud SQL instance removed
- VPC peering connections removed
- Compute addresses released

## Security Considerations

### Secrets Management
- Database passwords generated via `random_password` resource
- Passwords stored in Terraform state (ensure state backend is encrypted)
- Consider migrating to AWS Secrets Manager / GCP Secret Manager for production

### Network Security
- All databases in private subnets/networks with no public IPs
- Security groups and firewall rules follow least-privilege principle
- NAT Gateway provides controlled egress for private resources

### Access Control
- Use IAM roles and policies for AWS resource access
- Implement Workload Identity for GKE pod authentication
- Leverage EKS IAM roles for service accounts (IRSA)

### Compliance
- Enable encryption at rest for databases
- Enable VPC Flow Logs for audit trails
- Implement tagging strategy for resource tracking

## Support and Contribution

### Getting Help
- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed infrastructure documentation
- Check [SETUP.md](./SETUP.md) for detailed setup instructions
- Review Terraform documentation for provider-specific issues

### Reporting Issues
Create detailed issue reports including:
- Terraform version
- Provider versions
- Error messages
- Steps to reproduce

### Demo Purpose
This infrastructure is designed for demonstration and technical interviews. For production deployment:
- Enable Multi-AZ / Regional HA configurations
- Implement comprehensive monitoring and alerting
- Add disaster recovery procedures
- Implement CI/CD pipelines
- Add comprehensive security scanning
- Implement cost monitoring and optimization

## License

This is demonstration code for technical assessment purposes.

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0 | Oct 2025 | Initial release with basic infrastructure |
| 1.2 | Oct 2025 | Production-ready networking with NAT, routing, private Cloud SQL |
| Current | Oct 2025 | Comprehensive documentation and deployment guides |

---

**Maintained by**: Kyle Barone  
**Last Updated**: October 26, 2025  
**Status**: Production-Ready Demo
