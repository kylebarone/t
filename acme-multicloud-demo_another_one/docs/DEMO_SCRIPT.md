# Demo Script for Solutions Engineers

**Audience:** Technical decision-makers, infrastructure teams, DevOps engineers  
**Duration:** 30-45 minutes  
**Objective:** Demonstrate enterprise-grade multi-cloud infrastructure management with Terraform

## Demo Overview

This demo showcases how ACME Corporation manages infrastructure across Google Cloud Platform and Amazon Web Services using a unified Infrastructure-as-Code approach with Terraform and HashiCorp products.

---

## Part 1: Business Context (5 minutes)

### Talking Points

**Scenario Introduction:**
> "Let me share a real-world scenario that many organizations face today. ACME Corporation's engineering team has been running on Google Cloud Platform for years. Recently, through an acquisition, they've inherited a critical Kubernetes-based service that runs on AWS. Now their IT team needs to manage infrastructure across both cloud providers."

**Key Challenges:**
1. **Consistency**: Need unified approach across multiple clouds
2. **Governance**: Centralized control over infrastructure
3. **Efficiency**: Single codebase, single deployment process
4. **Visibility**: Unified view of all resources

**Our Solution:**
> "This demo shows how Terraform enables ACME to manage both clouds from a single codebase, with standardized modules, consistent security postures, and the flexibility to scale as needed."

---

## Part 2: Architecture Walkthrough (10 minutes)

### Show: Architecture Diagram

**Network Architecture:**

```
GCP (Primary Platform)              AWS (Acquired Service)
┌─────────────────────────┐        ┌─────────────────────────┐
│ Custom VPC              │        │ VPC (10.2.0.0/16)       │
│ ├─ Primary: 10.1.0.0/24 │        │ ├─ Public Subnets       │
│ ├─ Pods: 10.1.16.0/20   │        │ │  └─ NAT Gateway       │
│ └─ Services: 10.1.32.0/20│       │ └─ Private Subnets      │
│                          │        │    ├─ EKS Nodes         │
│ GKE Private Cluster      │        │    └─ RDS PostgreSQL    │
│ Cloud SQL (Private IP)   │        │                         │
└─────────────────────────┘        └─────────────────────────┘
```

**Talking Points:**

> "Notice the architectural differences between the clouds:
> 
> On **GCP**, we use their native patterns:
> - Custom VPC with secondary IP ranges for Kubernetes
> - Private GKE cluster with Workload Identity
> - Cloud SQL with VPC peering - no public IP
> - Private Google Access for secure API calls
> 
> On **AWS**, we follow AWS best practices:
> - Traditional VPC with public and private subnets
> - NAT Gateway for private subnet egress
> - EKS with IAM roles for service accounts
> - RDS in private subnets only
> 
> Despite these architectural differences, we manage both from a single Terraform codebase with consistent security policies."

### Key Features to Highlight:

1. **Multi-Cloud Toggle Pattern**
   - Boolean flags to enable/disable clouds
   - No cross-cloud dependencies
   - Deploy to one or both clouds

2. **Production-Ready Networking**
   - Private-first architecture
   - Proper routing and NAT configuration
   - Firewall rules and security groups

3. **Modular Design**
   - Reusable modules for each component
   - Separation of concerns
   - Easy to extend

---

## Part 3: Live Demo - Code Walkthrough (15 minutes)

### Step 1: Project Structure

**Show: Directory tree**
```bash
cd acme-multicloud-demo
tree -L 2
```

**Talking Points:**
> "The project structure follows Terraform best practices:
> - Root module orchestrates everything
> - Separate modules for each component (network, compute, database)
> - Environment-specific configurations in the environments folder
> - Helper scripts for common operations"

### Step 2: Configuration

**Show: terraform.tfvars**
```bash
cat terraform.tfvars
```

**Talking Points:**
> "Configuration is straightforward. The multi-cloud toggle is just two boolean flags:
> - `enable_gcp = true` deploys GCP infrastructure
> - `enable_aws = true` deploys AWS infrastructure
> 
> This gives us incredible flexibility:
> - Start with one cloud, expand later
> - Test disaster recovery by toggling between clouds
> - Cost optimization during development
> - Gradual migration scenarios"

### Step 3: Module Deep Dive

**Show: GCP Network Module**
```bash
cat modules/gcp-network/main.tf
```

**Talking Points:**
> "Let's look at a module. The GCP network module:
> - Creates VPC with custom routing
> - Configures secondary IP ranges for GKE pods and services
> - Sets up VPC peering for Cloud SQL
> - Implements firewall rules following least-privilege
> - All resources properly tagged and labeled
> 
> Notice the professional touches:
> - VPC Flow Logs for security monitoring
> - Private Google Access enabled
> - Health check rules for load balancers
> - IAP access for secure SSH"

**Show: AWS EKS Module**
```bash
cat modules/aws-eks/main.tf | head -50
```

**Talking Points:**
> "The AWS EKS module shows similar quality:
> - Proper IAM roles with managed policies
> - Security groups with minimal required access
> - Managed node groups with autoscaling
> - CloudWatch logging enabled
> - All following AWS best practices"

### Step 4: Outputs and Observability

**Show: outputs.tf**
```bash
cat outputs.tf
```

**Talking Points:**
> "The outputs provide everything needed to access and manage the infrastructure:
> - kubectl connection commands for both clusters
> - Database connection strings
> - Network information for troubleshooting
> - Even a quick reference guide
> 
> All sensitive values are properly marked as sensitive - they won't appear in logs or console output."

---

## Part 4: Live Deployment (5-10 minutes)

### Option A: Show Existing Deployment

If infrastructure is already deployed:

**Show: Terraform outputs**
```bash
terraform output
```

**Access Kubernetes clusters:**
```bash
# GCP
$(terraform output -raw gcp_kubectl_command)
kubectl get nodes
kubectl get pods --all-namespaces

# AWS
$(terraform output -raw aws_kubectl_command)
kubectl get nodes
kubectl get pods --all-namespaces
```

**Talking Points:**
> "With one Terraform apply, we've deployed:
> - Two production-ready Kubernetes clusters
> - Two highly available PostgreSQL databases
> - Complete networking with proper security boundaries
> - All configured and ready to receive workloads
> 
> The entire deployment took about 15 minutes - that's the power of Infrastructure as Code."

### Option B: Show Plan (No Apply)

If doing a dry-run demo:

```bash
terraform plan
```

**Talking Points:**
> "Let me show you what Terraform would deploy. The plan shows:
> - Every resource that will be created
> - Their dependencies and relationships
> - Estimated changes before applying
> 
> This plan can be reviewed, approved, and version controlled as part of your governance process."

---

## Part 5: Key Value Propositions (5 minutes)

### 1. **Single Source of Truth**
> "All infrastructure is defined in code, version controlled, and auditable. No more configuration drift or undocumented manual changes."

### 2. **Consistency Across Clouds**
> "Same deployment process, same security standards, same operational procedures - regardless of cloud provider."

### 3. **Flexibility and Agility**
> "Toggle clouds on/off for testing, DR, or cost optimization. Deploy to new regions in minutes, not weeks."

### 4. **Enterprise Security**
> "Private-first architecture, minimal IAM permissions, encrypted databases, comprehensive audit logging - security is built in, not bolted on."

### 5. **Cost Optimization**
> "Right-sizing through variables, destroy environments when not in use, autoscaling to match demand. Infrastructure as Code enables FinOps."

### 6. **Team Productivity**
> "Developers self-service via approved modules, Operations manages through code reviews, Security enforces policies through guardrails."

---

## Part 6: Advanced Features & Roadmap (5 minutes)

### Available Today:

**Show: Module extensibility**
> "These modules are building blocks. Teams can:
> - Create environment-specific configurations (dev/staging/prod)
> - Add custom networking rules
> - Integrate with existing infrastructure
> - Build higher-level abstractions"

**Show: scripts directory**
> "We've included helper scripts:
> - Setup script for initial configuration
> - Validation script to check deployment health
> - Easy to add custom automation"

### Future Enhancements:

1. **Service Mesh Integration**
   - Istio for cross-cluster communication
   - Unified observability

2. **Policy as Code**
   - Sentinel for policy enforcement
   - Compliance scanning

3. **GitOps Integration**
   - Terraform Cloud for remote state
   - GitHub Actions for CI/CD

4. **Advanced Networking**
   - Cross-cloud VPN for hybrid workloads
   - Multi-region deployments

---

## Part 7: Q&A Preparation

### Common Questions & Answers

**Q: How do you handle secrets?**
> "Database passwords are generated randomly and stored in Terraform state. For production, we recommend:
> - HashiCorp Vault for secret management
> - AWS Secrets Manager / GCP Secret Manager
> - Kubernetes secrets for application-level secrets
> The modules support all these approaches."

**Q: What about disaster recovery?**
> "The multi-cloud approach provides inherent DR capabilities:
> - Deploy to both clouds, route traffic based on availability
> - Regular backups with 7-day retention
> - Point-in-time recovery for databases
> - Entire infrastructure can be recreated from code"

**Q: How do you manage state files?**
> "For production, we recommend:
> - Terraform Cloud for hosted state management
> - S3/GCS with state locking for self-managed
> - The code includes backend configuration examples
> - Never commit state files to Git"

**Q: What's the total cost?**
> "Development environment (minimal): ~$300-400/month total
> Production environment (HA): ~$1,000-1,400/month total
> 
> Costs scale with:
> - Node counts and instance types
> - Database sizes
> - Data transfer
> - Additional services"

**Q: How do you handle updates?**
> "Terraform provides:
> - Declarative updates - just change the code
> - Plan before apply - review changes first
> - Kubernetes auto-upgrades can be enabled/disabled
> - Database maintenance windows are configured
> - All changes go through version control and review"

**Q: Can we integrate with existing infrastructure?**
> "Absolutely. Terraform can:
> - Import existing resources
> - Reference external resources via data sources
> - Integrate with existing VPCs/networks
> - Work alongside other IaC tools"

---

## Demo Tips

### Before the Demo:
1. ✅ Test the deployment in advance
2. ✅ Have cloud credentials configured
3. ✅ Prepare a backup plan (slides) if live demo fails
4. ✅ Know the customer's cloud preferences
5. ✅ Review recent Terraform updates

### During the Demo:
1. **Start with context** - why multi-cloud matters
2. **Show, don't just tell** - walk through actual code
3. **Highlight security** - enterprises care deeply about this
4. **Be honest about tradeoffs** - builds credibility
5. **Connect to business value** - not just technical features

### After the Demo:
1. Share the GitHub repository
2. Offer to customize for their specific needs
3. Provide cost estimates based on their scale
4. Schedule technical deep-dive with their architects
5. Follow up with Terraform Cloud trial

---

## Success Metrics

Track these to measure demo effectiveness:
- Technical questions asked (shows engagement)
- Request for follow-up meeting
- Trial/POC requests
- Competitive displacement mentions
- Time to close after demo

---

## Appendix: Quick Commands

```bash
# Setup
./scripts/setup.sh

# Deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Validate
./scripts/validate.sh
terraform output

# Access clusters
$(terraform output -raw gcp_kubectl_command)
$(terraform output -raw aws_kubectl_command)

# Cleanup
terraform destroy
```

---

**Demo Version:** 1.2  
**Last Updated:** October 26, 2025  
**Contact:** infrastructure-team@acme.example.com
