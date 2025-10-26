# V1 Demo Scope: ACME Multi-Cloud Widget Platform

## Primary Scenario: Terraform 2 (Multi-Cloud IaC)
**Customer Context**: ACME + Initech merger requires multi-cloud strategy  
**Current Pain**: AWS-only, Python scripts, ServiceNow, Ansible fragmentation  
**Decision Timeline**: Budget planning underway, CTO wants decision ASAP

## Bonus Integration: Vault 1 (Database Secrets)
**Connection Point**: Show how Vault provides dynamic credentials for databases we provision with Terraform  
**Competitive Angle**: Demonstrates HashiCorp platform thinking vs point solutions

---

## What We'll Build

### Infrastructure (Simple, Real, Repeatable)
```
GCP Environment (Primary):
├─ GKE Cluster (small, 3 nodes)
├─ Cloud SQL PostgreSQL (widget orders database)
└─ Cloud Load Balancer

AWS Environment (DR/Failover):
├─ EKS Cluster (small, 2 nodes)  
├─ RDS PostgreSQL (widget orders replica)
└─ Application Load Balancer

Application:
└─ Widget API (Node.js REST) - writes orders to database
```

### Key Demo Moments

**Terraform 2 Requirements (Primary Focus):**
- ✅ Multi-cloud: GCP + AWS simultaneously
- ✅ IaC value: Version controlled, repeatable, auditable
- ✅ Live demo: Actual deployment with Terraform 1.0+
- ✅ Platform consolidation: Replaces Python/ServiceNow/Ansible

**Terraform 1 Requirements (Natural Bonus):**
- ✅ VCS integration: GitHub repo with Terraform code
- ✅ Workspaces: Separate dev/prod environments
- ✅ Remote backend: Terraform Cloud execution
- ✅ Team collaboration: Show workspace locking, plan approvals
- ✅ Multi-cloud provisioning: Single tool, multiple clouds

**Vault 1 Integration (Platform Bonus):**
- ✅ Show Terraform provisioning database
- ✅ Show Vault providing dynamic credentials to app
- ✅ Mention this addresses their breach concerns
- ✅ Positions full HashiCorp platform value

---

## Demo Flow (20 minutes)

**[0-3min] Context Setting**
- ACME's merger challenge
- Current tool sprawl (diagram)
- What they'll see today

**[3-8min] Terraform Multi-Cloud Demo**
- Show GitHub repo structure
- `terraform init` → Terraform Cloud backend
- `terraform plan` → Show GCP + AWS resources
- `terraform apply` → Deploy to both clouds
- Show outputs: endpoints for both clouds

**[8-12min] Collaboration Features**
- Create new workspace for "prod"
- Show state locking in action
- Demonstrate remote execution
- Show plan approval workflow

**[12-15min] Platform Integration (Vault Bonus)**
- Show Vault dynamic database credentials
- Connect app to database using Vault secrets
- Mention: "This addresses your breach concerns from Vault scenario"

**[15-18min] Competitive Positioning**
- Why better than Pulumi, CloudFormation, Ansible
- Module reusability for Initech merger
- Cost optimization through standardization

**[18-20min] Next Steps**
- POC proposal for their widget platform
- Mention: Can add Consul service mesh, Nomad orchestration
- Show platform roadmap

---

## Out of Scope (Mention for Future)

- Full CI/CD pipeline integration
- Sentinel/OPA policy as code
- Consul service discovery
- Advanced networking (service mesh)
- Production-grade HA configuration
- Cost allocation tags across clouds

---

## Success Metrics

**Technical Win:**
- They see working multi-cloud deployment
- They understand workspace model
- They see VCS-driven workflow value

**Business Win:**
- CIO: Cost reduction story lands
- Cloud Architect: Multi-cloud strategy validated
- DevOps Engineer: Excited about Git workflow
- SRE: Sees reproducibility value

**Competitive Win:**
- Better than custom Python scripts (maintainability)
- Better than Ansible (cloud-native abstractions)
- Better than ServiceNow (automation over tickets)
- Platform thinking: Vault integration shows ecosystem

---

## Risk Mitigations

**Demo Failure Scenarios:**
1. Network issues → Have recorded video backup
2. Quota limits → Pre-deploy resources, just show updates
3. Timing runs long → Skip Vault integration, focus on Terraform
4. Technical questions exceed depth → Acknowledge, offer follow-up with SA

**Preparation Checklist:**
- [ ] GCP/AWS accounts configured
- [ ] Terraform Cloud workspace created
- [ ] GitHub repo pushed
- [ ] Test run completed day before
- [ ] Backup slides showing expected output
- [ ] Talking points for each persona memorized
