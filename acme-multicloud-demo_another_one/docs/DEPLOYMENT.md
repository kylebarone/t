# Deployment Guide

This guide provides detailed step-by-step instructions for deploying the ACME Multi-Cloud Infrastructure.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Verification](#verification)
- [Accessing Resources](#accessing-resources)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

Install the following tools before proceeding:

1. **Terraform** (>= 1.0)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **gcloud CLI**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk
   
   # Linux
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```

3. **AWS CLI**
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

4. **kubectl**
   ```bash
   # macOS
   brew install kubectl
   
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

### Cloud Provider Accounts

You'll need:
- **GCP**: A project with billing enabled
- **AWS**: An account with appropriate IAM permissions

## Initial Setup

### 1. Authenticate with Cloud Providers

**GCP Authentication:**
```bash
# Authenticate with gcloud
gcloud auth login

# Set up application default credentials
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Verify authentication
gcloud auth list
```

**AWS Authentication:**
```bash
# Configure AWS credentials
aws configure

# Enter your credentials when prompted:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)

# Verify authentication
aws sts get-caller-identity
```

### 2. Enable Required GCP APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### 3. Run Setup Script

```bash
cd acme-multicloud-demo
./scripts/setup.sh
```

This script will:
- Verify all required tools are installed
- Create `terraform.tfvars` from the example
- Check cloud provider authentication
- Initialize Terraform

## Configuration

### 1. Edit terraform.tfvars

Open `terraform.tfvars` and update the following required values:

```hcl
# REQUIRED: Your GCP project ID
gcp_project = "your-actual-project-id"

# Optional: Enable/disable specific clouds
enable_gcp = true
enable_aws = true

# Optional: Customize resource sizing for your needs
gke_machine_type = "e2-medium"
eks_instance_type = "t3.medium"
```

### 2. Choose Your Deployment Scenario

**Scenario 1: Both Clouds (Recommended for Demo)**
```hcl
enable_gcp = true
enable_aws = true
```

**Scenario 2: GCP Only**
```hcl
enable_gcp = true
enable_aws = false
```

**Scenario 3: AWS Only**
```hcl
enable_gcp = false
enable_aws = true
```

### 3. Review Network Configuration

The default network configuration provides:

**GCP:**
- Primary subnet: `10.1.0.0/24`
- Pod network: `10.1.16.0/20` (4,096 IPs)
- Service network: `10.1.32.0/20` (4,096 IPs)

**AWS:**
- VPC: `10.2.0.0/16`
- Private subnets: `10.2.1.0/24`, `10.2.2.0/24`
- Public subnets: `10.2.3.0/24`, `10.2.4.0/24`

Adjust these in `terraform.tfvars` if you have specific network requirements.

## Deployment

### 1. Initialize Terraform (if not done by setup script)

```bash
terraform init
```

### 2. Review the Deployment Plan

```bash
terraform plan -out=tfplan
```

This will show you all resources that will be created. Review carefully!

**Expected resources (both clouds enabled):**
- GCP: ~15-20 resources (VPC, GKE cluster, Cloud SQL, etc.)
- AWS: ~25-30 resources (VPC, EKS cluster, RDS, NAT Gateway, etc.)

### 3. Apply the Configuration

```bash
terraform apply tfplan
```

**Deployment Timeline:**
- GCP GKE cluster: 5-7 minutes
- GCP Cloud SQL: 3-5 minutes
- AWS EKS cluster: 10-12 minutes
- AWS RDS: 5-7 minutes
- **Total: Approximately 15-20 minutes**

The deployment will provide progress updates. Wait for the complete message.

### 4. Save Outputs

```bash
terraform output > deployment-outputs.txt
```

This saves all connection information for future reference.

## Verification

### 1. Run Validation Script

```bash
./scripts/validate.sh
```

This checks:
- Cluster status
- Node readiness
- Database connectivity

### 2. Manual Verification

**Verify GCP Resources:**
```bash
# List GKE clusters
gcloud container clusters list

# Check Cloud SQL instances
gcloud sql instances list

# View VPC networks
gcloud compute networks list
```

**Verify AWS Resources:**
```bash
# List EKS clusters
aws eks list-clusters

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'

# View VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value]'
```

## Accessing Resources

### Kubernetes Clusters

**GCP GKE:**
```bash
# Get credentials
gcloud container clusters get-credentials $(terraform output -raw gcp_cluster_name) \
  --region us-central1 \
  --project YOUR_PROJECT_ID

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

**AWS EKS:**
```bash
# Get credentials
aws eks update-kubeconfig \
  --name $(terraform output -raw aws_cluster_name) \
  --region us-east-1

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

### Databases

**GCP Cloud SQL:**
```bash
# Get connection name
CONNECTION_NAME=$(terraform output -raw gcp_database_connection_name)

# Connect using Cloud SQL Proxy
cloud_sql_proxy -instances=$CONNECTION_NAME=tcp:5432

# In another terminal, connect with psql
PGPASSWORD=$(terraform output -raw gcp_database_password) \
  psql -h 127.0.0.1 -U postgres -d widget
```

**AWS RDS:**
```bash
# Get endpoint
RDS_ENDPOINT=$(terraform output -raw aws_database_endpoint)

# Connect from bastion or within VPC
PGPASSWORD=$(terraform output -raw aws_database_password) \
  psql -h $RDS_ENDPOINT -U postgres -d widget
```

## Troubleshooting

### Common Issues

**Issue: "Error creating Network: googleapi: Error 403: ... has not been used"**

**Solution:** Enable the required GCP API:
```bash
gcloud services enable servicenetworking.googleapis.com
```

**Issue: "Error creating EKS Cluster: AccessDeniedException"**

**Solution:** Verify IAM permissions:
```bash
aws sts get-caller-identity
# Ensure your IAM user/role has EKS permissions
```

**Issue: "Error acquiring state lock"**

**Solution:** If using remote state and lock is stuck:
```bash
terraform force-unlock LOCK_ID
```

**Issue: "kubectl: command not found" after cluster creation**

**Solution:** Refresh credentials:
```bash
# For GCP
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# For AWS
aws eks update-kubeconfig --name CLUSTER_NAME --region REGION
```

**Issue: Cloud SQL connection timeout**

**Solution:** Check VPC peering:
```bash
gcloud services vpc-peerings list --network=YOUR_NETWORK_NAME
```

### Getting Help

1. Check Terraform state for resource status:
   ```bash
   terraform state list
   terraform state show RESOURCE_NAME
   ```

2. View detailed logs:
   ```bash
   TF_LOG=DEBUG terraform apply
   ```

3. Review cloud provider console:
   - GCP: https://console.cloud.google.com
   - AWS: https://console.aws.amazon.com

## Cleanup

To destroy all infrastructure:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Warning:** This will permanently delete:
- All Kubernetes clusters
- All databases (and their data)
- All networking resources

Ensure you have backups if needed!

## Next Steps

After successful deployment:

1. **Deploy Applications**: Use the Kubernetes clusters to deploy your workloads
2. **Configure Monitoring**: Set up CloudWatch (AWS) and Cloud Monitoring (GCP)
3. **Implement CI/CD**: Integrate with your pipeline tools
4. **Review Security**: Audit IAM roles, security groups, and network policies
5. **Plan Scaling**: Adjust autoscaling parameters based on load testing

## Additional Resources

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Detailed architecture documentation
- [Terraform Registry](https://registry.terraform.io/) - Provider documentation
- [GCP Documentation](https://cloud.google.com/docs)
- [AWS Documentation](https://docs.aws.amazon.com/)

---

**Last Updated:** October 26, 2025  
**Version:** 1.2
