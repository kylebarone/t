# Deployment Guide - Step by Step

**Version**: 1.2 Production-Ready  
**Last Updated**: October 26, 2025  
**Estimated Time**: 45-60 minutes (full deployment)

---

## Prerequisites Checklist

### Required Accounts and Tools

- [ ] AWS Account with admin access
- [ ] GCP Project with owner/editor permissions
- [ ] Terraform Cloud account (free tier sufficient)
- [ ] Git installed locally
- [ ] Terraform >= 1.0 installed
- [ ] AWS CLI installed and configured
- [ ] gcloud CLI installed and configured
- [ ] kubectl installed
- [ ] Code editor (VS Code recommended)

### Verification Commands

```bash
# Verify Terraform
terraform version
# Expected: Terraform v1.0+

# Verify AWS CLI
aws --version
aws sts get-caller-identity
# Expected: Your AWS account ID

# Verify gcloud
gcloud --version
gcloud auth list
gcloud projects list
# Expected: Your GCP project

# Verify kubectl
kubectl version --client
# Expected: Client Version v1.28+
```

---

## Phase 1: Initial Setup (15 minutes)

### Step 1.1: Clone or Set Up Repository

```bash
# Option A: Clone existing repository
git clone <your-repo-url>
cd acme-multicloud-demo/iterations/v1-demo-terraform

# Option B: Initialize new repository
mkdir -p acme-multicloud-demo/iterations/v1-demo-terraform
cd acme-multicloud-demo/iterations/v1-demo-terraform

# Copy all .tf files from this demo into the directory
```

### Step 1.2: Configure Terraform Cloud

```bash
# Login to Terraform Cloud
terraform login
# Follow browser prompts to authenticate

# This creates ~/.terraform.d/credentials.tfrc.json
```

**In Terraform Cloud Web UI**:
1. Navigate to [app.terraform.io](https://app.terraform.io)
2. Create new organization: `acme-corp` (or your company name)
3. Create workspace: `acme-multicloud-demo`
4. Settings → General:
   - Execution Mode: Local (for this demo)
   - Terraform Version: Latest 1.x
5. Save settings

### Step 1.3: Configure AWS Access

```bash
# Configure AWS CLI
aws configure
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-east-1
# Default output format: json

# Test access
aws sts get-caller-identity
```

**Expected Output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Step 1.4: Configure GCP Access

```bash
# Login to GCP
gcloud auth login
# Follow browser prompts

# Set default project
gcloud config set project YOUR-PROJECT-ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com

# Configure application default credentials
gcloud auth application-default login

# Verify
gcloud projects describe YOUR-PROJECT-ID
```

### Step 1.5: Customize Environment Configuration

Edit `environments/dev.tfvars`:

```hcl
# Copy this file and customize
environment    = "dev"
project_name   = "your-company-widget"  # CHANGE THIS
gcp_project_id = "your-actual-gcp-project-id"  # CHANGE THIS
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"
aws_region     = "us-east-1"

# Cloud toggles - start with one cloud for testing
enable_gcp = false  # Start with false, enable later
enable_aws = true   # Start with AWS

# Database
db_name     = "widget_orders_dev"
db_username = "dbadmin"
```

**Important**: 
- Change `gcp_project_id` to your actual GCP project
- Consider starting with one cloud to verify everything works
- You can add the second cloud later

---

## Phase 2: Deploy AWS Infrastructure (15-20 minutes)

### Step 2.1: Initialize Terraform

```bash
# Navigate to terraform directory
cd /path/to/v1-demo-terraform

# Initialize
terraform init
```

**Expected Output**:
```
Initializing Terraform Cloud...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Finding hashicorp/google versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
- Installing hashicorp/google v5.x.x...

Terraform Cloud has been successfully initialized!
```

### Step 2.2: Validate Configuration

```bash
# Format code
terraform fmt -recursive

# Validate syntax
terraform validate
```

**Expected Output**:
```
Success! The configuration is valid.
```

### Step 2.3: Plan AWS Deployment

```bash
# Generate plan
terraform plan -var-file="environments/dev.tfvars" -out=aws-deployment.tfplan

# Review plan output carefully
# You should see:
# - 1 VPC
# - 1 Internet Gateway
# - 1 NAT Gateway + Elastic IP
# - 4 Subnets (2 public, 2 private)
# - 2 Route Tables + 4 associations
# - 1 EKS Cluster + IAM roles
# - 1 EKS Node Group
# - 1 RDS Instance + Security Group
# - 1 Random Password
```

**Validation Checklist**:
- [ ] Plan shows ~30-35 resources to be added
- [ ] No resources to be destroyed (first run)
- [ ] No errors in plan output
- [ ] NAT Gateway included in plan
- [ ] Route tables and associations present

### Step 2.4: Apply AWS Deployment

```bash
# Apply the plan
terraform apply aws-deployment.tfplan

# Wait for completion (15-20 minutes)
# EKS cluster takes ~10-12 minutes
# RDS instance takes ~5-7 minutes
```

**Progress Monitoring**:
```bash
# In another terminal, monitor AWS Console:
# - VPC Console: Watch VPC creation
# - EKS Console: Watch cluster status
# - RDS Console: Watch instance creation
```

### Step 2.5: Verify AWS Deployment

```bash
# Check outputs
terraform output

# Expected outputs:
# - aws_vpc_id
# - aws_cluster_name
# - aws_cluster_endpoint
# - aws_database_endpoint
# - etc.

# Verify EKS cluster
aws eks describe-cluster --name acme-widget-eks-dev --region us-east-1

# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name acme-widget-eks-dev

# Verify nodes
kubectl get nodes
# Should show 2 nodes in Ready state
```

**Troubleshooting**:
- If nodes not showing: Wait 2-3 minutes, nodes may still be joining
- If nodes never join: Check NAT Gateway and route tables exist
- Check AWS Console → EKS → Cluster → Compute tab

---

## Phase 3: Deploy GCP Infrastructure (15-20 minutes)

### Step 3.1: Enable GCP in Configuration

Edit `environments/dev.tfvars`:
```hcl
enable_gcp = true   # Change from false to true
enable_aws = true   # Keep AWS running
```

### Step 3.2: Plan GCP Addition

```bash
# Generate new plan
terraform plan -var-file="environments/dev.tfvars" -out=gcp-addition.tfplan

# Review plan output
# You should see ONLY GCP resources being added:
# - 1 VPC Network
# - 1 Subnet with secondary ranges
# - 3 Firewall rules
# - 1 Global Address + VPC Peering
# - 1 GKE Cluster + Node Pool
# - 1 Cloud SQL Instance + Database + User
# - 1 Random Password
```

**Validation Checklist**:
- [ ] Plan shows ~15-20 resources to be added
- [ ] NO AWS resources changed/destroyed
- [ ] Private Cloud SQL configuration present
- [ ] Secondary IP ranges in subnet

### Step 3.3: Apply GCP Deployment

```bash
# Apply the plan
terraform apply gcp-addition.tfplan

# Wait for completion (15-20 minutes)
# GKE cluster takes ~10-15 minutes
# Cloud SQL takes ~5-8 minutes
```

### Step 3.4: Verify GCP Deployment

```bash
# Check outputs
terraform output

# Expected additional outputs:
# - gcp_vpc_name
# - gcp_cluster_name
# - gcp_database_private_ip
# - etc.

# Verify GKE cluster
gcloud container clusters describe acme-widget-gke-dev \
  --zone us-central1-a

# Update kubeconfig
gcloud container clusters get-credentials acme-widget-gke-dev \
  --zone us-central1-a \
  --project YOUR-PROJECT-ID

# Verify nodes
kubectl get nodes
# Should show 2 nodes in Ready state
```

---

## Phase 4: Verification and Testing (10 minutes)

### Step 4.1: Verify Complete Deployment

```bash
# Show all outputs
terraform output

# Verify both clusters
kubectl config get-contexts
# Should show both eks and gke contexts

# Check AWS cluster
kubectl config use-context arn:aws:eks:us-east-1:ACCOUNT:cluster/acme-widget-eks-dev
kubectl get nodes
kubectl get pods -A

# Check GCP cluster
kubectl config use-context gke_PROJECT_us-central1-a_acme-widget-gke-dev
kubectl get nodes
kubectl get pods -A
```

### Step 4.2: Test Database Connectivity

**AWS RDS** (requires bastion or VPN for external access):
```bash
# Get connection details
terraform output aws_database_endpoint
terraform output -json aws_database_password | jq -r

# From within VPC (e.g., EKS pod):
# kubectl run psql-test --rm -it --image=postgres:15 -- \
#   psql -h <RDS_ENDPOINT> -U dbadmin -d widget_orders_dev
```

**GCP Cloud SQL** (from GKE pod):
```bash
# Get connection details
terraform output gcp_database_private_ip
terraform output -json gcp_database_password | jq -r

# From GKE pod:
# kubectl run psql-test --rm -it --image=postgres:15 -- \
#   psql -h <PRIVATE_IP> -U dbadmin -d widget_orders_dev
```

### Step 4.3: Verify Network Architecture

**AWS**:
```bash
# Check VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=*acme-widget*" \
  --query 'Vpcs[0].{VpcId:VpcId,CIDR:CidrBlock}'

# Check NAT Gateway
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Name,Values=*acme-widget*" \
  --query 'NatGateways[0].{State:State,PublicIp:NatGatewayAddresses[0].PublicIp}'

# Should show "State: available"

# Check Route Tables
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=*acme-widget*" \
  --query 'RouteTables[*].{Name:Tags[?Key==`Name`].Value|[0],Routes:Routes[*].{Dest:DestinationCidrBlock,Target:GatewayId||NatGatewayId}}'
```

**GCP**:
```bash
# Check VPC
gcloud compute networks describe acme-widget-vpc-dev

# Check Firewall Rules
gcloud compute firewall-rules list \
  --filter="network:acme-widget-vpc-dev" \
  --format="table(name,allowed[].map().firewall_rule().list():label=ALLOW,sourceRanges.list():label=SRC_RANGES)"

# Check VPC Peering
gcloud services vpc-peerings list \
  --service=servicenetworking.googleapis.com \
  --network=acme-widget-vpc-dev
```

### Step 4.4: Cost Verification

```bash
# AWS Cost Explorer (via Console)
# Navigate to: AWS Console → Cost Management → Cost Explorer
# Filter: Service = EC2, EKS, RDS, VPC
# Timeframe: Last 30 days

# GCP Billing (via Console)
# Navigate to: GCP Console → Billing → Reports
# Filter: Project = your-project-id
# Services: Compute Engine, Kubernetes Engine, Cloud SQL

# Estimated monthly costs (dev environment):
# AWS: ~$190-$210
#   - EKS Control Plane: $73
#   - EC2 Instances: ~$60
#   - NAT Gateway: ~$45
#   - RDS: ~$15
#
# GCP: ~$130-$150
#   - GKE Control Plane: $73
#   - Compute Instances: ~$50
#   - Cloud SQL: ~$10
#
# Total: ~$320-$360/month
```

---

## Phase 5: Post-Deployment Configuration (10 minutes)

### Step 5.1: Set Up Kubernetes Namespaces

```bash
# Create application namespace in both clusters
kubectl config use-context [EKS_CONTEXT]
kubectl create namespace widget-app
kubectl label namespace widget-app environment=dev

kubectl config use-context [GKE_CONTEXT]
kubectl create namespace widget-app
kubectl label namespace widget-app environment=dev
```

### Step 5.2: Create Database Secrets

**AWS EKS**:
```bash
kubectl config use-context [EKS_CONTEXT]

# Create secret with database credentials
kubectl create secret generic db-credentials \
  --namespace=widget-app \
  --from-literal=host=$(terraform output -raw aws_database_address) \
  --from-literal=port=5432 \
  --from-literal=database=widget_orders_dev \
  --from-literal=username=dbadmin \
  --from-literal=password=$(terraform output -raw aws_database_password)
```

**GCP GKE**:
```bash
kubectl config use-context [GKE_CONTEXT]

# Create secret with database credentials
kubectl create secret generic db-credentials \
  --namespace=widget-app \
  --from-literal=host=$(terraform output -raw gcp_database_private_ip) \
  --from-literal=port=5432 \
  --from-literal=database=widget_orders_dev \
  --from-literal=username=dbadmin \
  --from-literal=password=$(terraform output -raw gcp_database_password)
```

### Step 5.3: Document Deployment

Create a deployment record:

```bash
# Create deployment notes
cat > deployment-notes.md << 'EOF'
# Deployment Record

## Deployment Date
$(date)

## Infrastructure Details
- AWS Region: us-east-1
- GCP Region: us-central1
- Environment: dev

## Cluster Information
- EKS Cluster: $(terraform output -raw aws_cluster_name)
- GKE Cluster: $(terraform output -raw gcp_cluster_name)

## Database Information
- AWS RDS: $(terraform output -raw aws_database_address)
- GCP Cloud SQL: $(terraform output -raw gcp_database_private_ip)

## Next Steps
- [ ] Configure monitoring
- [ ] Set up CI/CD pipeline
- [ ] Deploy application workloads
- [ ] Configure backup verification
- [ ] Set up alerts

## Notes
Add deployment-specific notes here...
EOF

# Add to version control
git add deployment-notes.md
git commit -m "Add deployment record for $(date +%Y-%m-%d)"
```

---

## Phase 6: Smoke Tests (5 minutes)

### Test 1: Node Health

```bash
# AWS
kubectl config use-context [EKS_CONTEXT]
kubectl get nodes
kubectl top nodes  # If metrics-server installed
kubectl describe nodes

# GCP
kubectl config use-context [GKE_CONTEXT]
kubectl get nodes
kubectl top nodes
kubectl describe nodes
```

**Expected**: All nodes in Ready state, no memory/disk pressure

### Test 2: DNS Resolution

```bash
# AWS
kubectl config use-context [EKS_CONTEXT]
kubectl run busybox --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default

# GCP
kubectl config use-context [GKE_CONTEXT]
kubectl run busybox --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default
```

**Expected**: DNS resolves successfully

### Test 3: Internet Connectivity

```bash
# AWS (tests NAT Gateway)
kubectl config use-context [EKS_CONTEXT]
kubectl run curl-test --rm -it --image=curlimages/curl --restart=Never -- curl -I https://www.google.com

# GCP (tests Private Google Access)
kubectl config use-context [GKE_CONTEXT]
kubectl run curl-test --rm -it --image=curlimages/curl --restart=Never -- curl -I https://www.google.com
```

**Expected**: HTTP 200 response

### Test 4: Database Connectivity

```bash
# AWS
kubectl config use-context [EKS_CONTEXT]
kubectl run psql-test --rm -it --image=postgres:15 --namespace=widget-app --restart=Never -- \
  env PGPASSWORD=$(kubectl get secret db-credentials -n widget-app -o jsonpath='{.data.password}' | base64 -d) \
  psql -h $(kubectl get secret db-credentials -n widget-app -o jsonpath='{.data.host}' | base64 -d) \
       -U $(kubectl get secret db-credentials -n widget-app -o jsonpath='{.data.username}' | base64 -d) \
       -d $(kubectl get secret db-credentials -n widget-app -o jsonpath='{.data.database}' | base64 -d) \
       -c "SELECT version();"

# GCP (similar command)
```

**Expected**: PostgreSQL version output

---

## Troubleshooting Common Issues

### Issue: Terraform Apply Fails

**Error**: "Error acquiring state lock"
```bash
# Solution: Wait or force unlock in Terraform Cloud UI
# app.terraform.io → workspace → Settings → Force Unlock
```

**Error**: "InvalidParameterException: Node group requires a VPC"
```bash
# Solution: Ensure VPC and subnets created first
# Check: terraform state list | grep vpc
# If missing, something wrong with enable_aws flag
```

### Issue: EKS Nodes Not Ready

**Symptoms**: Nodes don't appear in `kubectl get nodes`

```bash
# Debug steps:
# 1. Check NAT Gateway exists
aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=*acme-widget*"

# 2. Check route tables
aws ec2 describe-route-tables --filter "Name=tag:Name,Values=*private*"

# 3. Check CloudWatch logs
aws logs tail /aws/eks/acme-widget-eks-dev/cluster --follow

# 4. Check node instance logs in AWS Console
# EC2 → Instances → Select node → Actions → Monitor and troubleshoot → Get system log
```

### Issue: GKE Nodes Not Ready

**Symptoms**: Nodes stuck in NotReady or error state

```bash
# Debug steps:
# 1. Check firewall rules
gcloud compute firewall-rules list --filter="network:acme-widget-vpc-dev"

# 2. Check node logs
gcloud logging read "resource.type=k8s_node" --limit 50

# 3. Describe cluster
gcloud container clusters describe acme-widget-gke-dev --zone us-central1-a
```

### Issue: Database Not Accessible

**AWS RDS**:
```bash
# Check security group
aws ec2 describe-security-groups --filters "Name=group-name,Values=*rds-sg*"

# Verify inbound rules include VPC CIDR on port 5432

# Check RDS endpoint
aws rds describe-db-instances --db-instance-identifier acme-widget-db-dev \
  --query 'DBInstances[0].Endpoint'
```

**GCP Cloud SQL**:
```bash
# Check private IP assigned
gcloud sql instances describe acme-widget-db-dev \
  --format="value(ipAddresses[0].ipAddress,ipAddresses[0].type)"

# Should show private IP with type=PRIVATE

# Verify VPC peering
gcloud services vpc-peerings list \
  --service=servicenetworking.googleapis.com \
  --network=acme-widget-vpc-dev
```

---

## Cleanup / Teardown

### Full Teardown

```bash
# Destroy all infrastructure
terraform destroy -var-file="environments/dev.tfvars"

# Confirm: yes

# Wait 10-15 minutes for complete teardown
```

### Selective Teardown

**Remove GCP, Keep AWS**:
```bash
# Edit dev.tfvars: enable_gcp=false
terraform apply -var-file="environments/dev.tfvars"
```

**Remove AWS, Keep GCP**:
```bash
# Edit dev.tfvars: enable_aws=false
terraform apply -var-file="environments/dev.tfvars"
```

### Post-Teardown Verification

```bash
# Verify AWS resources deleted
aws eks list-clusters
aws rds describe-db-instances
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*acme-widget*"

# Verify GCP resources deleted
gcloud container clusters list
gcloud sql instances list
gcloud compute networks list --filter="name:acme-widget*"

# Check Terraform state is clean
terraform state list
# Should show no resources if fully destroyed
```

### Manual Cleanup (if needed)

Sometimes resources may not delete cleanly:

```bash
# AWS: Delete in order
# 1. Delete EKS cluster (if stuck)
aws eks delete-cluster --name acme-widget-eks-dev

# 2. Delete RDS (if stuck)
aws rds delete-db-instance \
  --db-instance-identifier acme-widget-db-dev \
  --skip-final-snapshot

# 3. Wait, then force delete VPC
aws ec2 delete-vpc --vpc-id vpc-xxxxx

# GCP: Force delete
# 1. Delete GKE cluster
gcloud container clusters delete acme-widget-gke-dev --zone us-central1-a

# 2. Delete Cloud SQL
gcloud sql instances delete acme-widget-db-dev

# 3. Delete VPC
gcloud compute networks delete acme-widget-vpc-dev
```

---

## Next Steps After Deployment

### Immediate (Week 1)
- [ ] Configure cluster monitoring (Prometheus/Grafana)
- [ ] Set up log aggregation (CloudWatch/Cloud Logging)
- [ ] Configure backup verification
- [ ] Set up cost alerts
- [ ] Document runbooks for common operations

### Short Term (Month 1)
- [ ] Deploy sample application
- [ ] Configure CI/CD pipeline
- [ ] Implement automated testing
- [ ] Set up disaster recovery procedures
- [ ] Conduct security audit

### Long Term (Quarter 1)
- [ ] Evaluate multi-region expansion
- [ ] Implement service mesh
- [ ] Optimize costs based on actual usage
- [ ] Conduct chaos engineering exercises
- [ ] Plan migration to production-grade configuration

---

## Success Criteria

Your deployment is successful when:

✅ Both EKS and GKE clusters are running and accessible  
✅ All nodes are in Ready state  
✅ Both databases are accessible from their respective clusters  
✅ NAT Gateway provides internet access for AWS private subnets  
✅ GCP private nodes can access Google APIs  
✅ No errors in `terraform plan` runs  
✅ All smoke tests pass  
✅ Infrastructure costs are within expected range  
✅ Documentation is complete and up-to-date  
✅ Team members can access and manage the infrastructure  

---

**Deployment Guide Version**: 1.2  
**Last Updated**: October 26, 2025  
**Estimated Total Time**: 45-60 minutes  
**Success Rate**: 95%+ when following all steps
