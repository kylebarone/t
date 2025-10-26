# Setup Instructions

## Prerequisites

1. **Install Tools:**
   - Terraform >= 1.0
   - gcloud CLI
   - aws CLI
   - kubectl (optional)

2. **Cloud Accounts:**
   - GCP project with billing enabled
   - AWS account with admin access

## Step 1: Configure GCP

```bash
# Login to GCP
gcloud auth login
gcloud auth application-default login

# Set project
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID

# Enable APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

## Step 2: Configure AWS

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

## Step 3: Configure Terraform Cloud (Optional)

```bash
# Login to Terraform Cloud
terraform login

# Update organization name in terraform.tf
# organization = "your-org-name"
```

OR use local backend by removing the `cloud` block in terraform.tf.

## Step 4: Deploy

```bash
# Update GCP project ID
export TF_VAR_gcp_project_id=$GCP_PROJECT_ID

# Initialize Terraform
terraform init

# Test with GCP only first
terraform plan -var="enable_aws=false"

# If good, deploy GCP
terraform apply -var="enable_aws=false"

# Then add AWS
terraform apply
```

## Step 5: Verify

```bash
# Show outputs
terraform output

# Connect to GKE
gcloud container clusters get-credentials $(terraform output -raw gcp_cluster_name) --zone=us-central1-a

# Connect to EKS
aws eks update-kubeconfig --name $(terraform output -raw aws_cluster_name) --region us-east-1
```

## Step 6: Cleanup

```bash
terraform destroy
```

## Estimated Time
- Setup: 10 minutes
- GCP deployment: 10-15 minutes
- AWS deployment: 10-15 minutes
- Total: ~30-40 minutes

## Estimated Cost
- ~$0.25/hour while running
- ~$6/day if left running 24/7
