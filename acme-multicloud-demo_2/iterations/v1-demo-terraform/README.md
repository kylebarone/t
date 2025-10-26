# ACME Multi-Cloud Widget Platform

Terraform code for deploying widget platform to GCP and AWS.

## Quick Start

```bash
# Set GCP project ID
export TF_VAR_gcp_project_id="your-gcp-project-id"

# Initialize
terraform init

# Plan (GCP only for testing)
terraform plan -var="enable_aws=false"

# Apply
terraform apply
```

## Configuration

Edit `environments/dev.tfvars` or `environments/prod.tfvars` for environment-specific settings.

## What Gets Deployed

**GCP:**
- GKE cluster (2 nodes, e2-medium)
- Cloud SQL PostgreSQL (db-f1-micro)
- VPC network and subnet

**AWS:**
- EKS cluster (2 nodes, t3.medium)
- RDS PostgreSQL (db.t3.micro)
- VPC with public/private subnets
- Security groups and IAM roles

## Estimated Costs

- GCP: ~$0.12/hour (~$86/month)
- AWS: ~$0.12/hour (~$86/month)
- Total: ~$172/month if running 24/7

**Recommendation:** Deploy only when needed, destroy after use.

## Cleanup

```bash
terraform destroy
```
