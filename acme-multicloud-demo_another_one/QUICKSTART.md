# Quick Start Guide

Get the ACME Multi-Cloud Infrastructure up and running in under 30 minutes.

## Prerequisites Checklist

- [ ] Terraform >= 1.0 installed
- [ ] gcloud CLI installed and configured
- [ ] AWS CLI installed and configured
- [ ] kubectl installed
- [ ] GCP project with billing enabled
- [ ] AWS account with appropriate permissions

## 5-Minute Setup

### 1. Clone and Navigate
```bash
cd acme-multicloud-demo
```

### 2. Configure Credentials

**GCP:**
```bash
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

**AWS:**
```bash
aws configure
# Enter your AWS credentials when prompted
```

### 3. Run Setup Script
```bash
./scripts/setup.sh
```

### 4. Edit Configuration
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # or use your preferred editor
```

**Update these required values:**
```hcl
gcp_project = "your-actual-gcp-project-id"
```

### 5. Deploy
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

⏱️ **Deployment time:** 15-20 minutes

### 6. Verify
```bash
./scripts/validate.sh
terraform output
```

## What Gets Deployed

### GCP (if enabled)
✅ VPC with custom networking  
✅ GKE private cluster (2 nodes)  
✅ Cloud SQL PostgreSQL (private IP)  
✅ Firewall rules and VPC peering  

### AWS (if enabled)
✅ VPC with public/private subnets  
✅ EKS cluster (2 nodes)  
✅ RDS PostgreSQL (private)  
✅ NAT Gateway and routing  

## Access Your Clusters

**GCP GKE:**
```bash
gcloud container clusters get-credentials $(terraform output -raw gcp_cluster_name) \
  --region us-central1 \
  --project YOUR_PROJECT_ID

kubectl get nodes
```

**AWS EKS:**
```bash
aws eks update-kubeconfig \
  --name $(terraform output -raw aws_cluster_name) \
  --region us-east-1

kubectl get nodes
```

## Get Database Credentials

**View passwords (sensitive):**
```bash
terraform output gcp_database_password
terraform output aws_database_password
```

**Connection info:**
```bash
terraform output gcp_database_private_ip
terraform output aws_database_endpoint
```

## Common First Steps

### Deploy a Test Application

**Create a simple nginx deployment:**
```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get services
```

### Check Resource Status

```bash
# GCP
gcloud container clusters list
gcloud sql instances list
gcloud compute networks list

# AWS
aws eks list-clusters
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'
aws ec2 describe-vpcs
```

## Troubleshooting

### Issue: Terraform init fails
```bash
# Clear cache and retry
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Issue: Cannot connect to cluster
```bash
# Refresh credentials
# For GCP:
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# For AWS:
aws eks update-kubeconfig --name CLUSTER_NAME --region REGION
```

### Issue: Permission denied
```bash
# Verify authentication
gcloud auth list
aws sts get-caller-identity
```

## Clean Up

**To destroy everything:**
```bash
terraform destroy
# Type 'yes' when prompted
```

⚠️ **Warning:** This permanently deletes all resources including databases.

## Next Steps

1. **Deploy your application** - Use the Kubernetes clusters
2. **Set up monitoring** - Configure CloudWatch/Cloud Monitoring
3. **Review security** - Audit IAM roles and network policies
4. **Read full docs** - See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for details

## Cost Estimate

**Development (both clouds):** ~$300-400/month
- 2 small K8s clusters
- 2 small databases
- Basic networking

**To reduce costs:**
- Set `enable_aws = false` or `enable_gcp = false`
- Use `terraform destroy` when not in use
- Adjust instance sizes in terraform.tfvars

## Getting Help

- 📖 Full documentation in [docs/](docs/) directory
- 🐛 Issues: Create a GitHub issue
- 💬 Questions: infrastructure-team@acme.example.com

## Pro Tips

1. **Always run `terraform plan` before `apply`** - Review changes first
2. **Keep terraform.tfvars out of Git** - It's already in .gitignore
3. **Use workspaces for multiple environments** - `terraform workspace new prod`
4. **Enable VPC Flow Logs in production** - Uncomment in network modules
5. **Use Terraform Cloud for team collaboration** - Shared state and locking

---

**Setup Time:** ~5 minutes  
**Deployment Time:** ~15-20 minutes  
**Total Time to Running Clusters:** ~25 minutes  

Happy deploying! 🚀
