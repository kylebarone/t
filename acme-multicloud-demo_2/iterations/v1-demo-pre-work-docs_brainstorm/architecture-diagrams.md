# Architecture Diagrams

## Diagram 1: Current State (The Problem)

```mermaid
graph TB
    subgraph "ACME Corp - AWS Only"
        A1[Dev Team A]
        A2[Dev Team B]
        A3[Dev Team C]
        
        A1 -->|Python Script v1| AWS1[AWS EC2/RDS]
        A2 -->|Python Script v2| AWS2[AWS Lambda/DynamoDB]
        A3 -->|ServiceNow Ticket| SNow[ServiceNow]
        SNow -->|Manual| OPS[Ops Team]
        OPS -->|Console Clicks| AWS3[AWS EKS/RDS]
        
        style AWS1 fill:#FF9900
        style AWS2 fill:#FF9900
        style AWS3 fill:#FF9900
    end
    
    subgraph "Initech - GCP + Azure"
        I1[Initech Team X]
        I2[Initech Team Y]
        
        I1 -->|Ansible Playbook 1| GCP1[GCP GCE/SQL]
        I2 -->|Ansible Playbook 2| AZ1[Azure VM/SQL]
        
        style GCP1 fill:#4285F4
        style AZ1 fill:#0078D4
    end
    
    PAIN1[No Standardization]
    PAIN2[Vendor Lock-in]
    PAIN3[3-5 Day SLA]
    PAIN4[No Reusability]
    
    style PAIN1 fill:#ff6b6b
    style PAIN2 fill:#ff6b6b
    style PAIN3 fill:#ff6b6b
    style PAIN4 fill:#ff6b6b
```

## Diagram 2: Proposed Solution (Terraform Platform)

```mermaid
graph TB
    subgraph "Development Teams"
        DEV1[Team A]
        DEV2[Team B]
        DEV3[Team X - Initech]
    end
    
    subgraph "Version Control System"
        GH[GitHub Repository]
        GH --> MOD[Terraform Modules]
        GH --> ENV1[Dev Workspace]
        GH --> ENV2[Prod Workspace]
    end
    
    subgraph "Terraform Cloud"
        TC[Terraform Cloud]
        TC --> STATE[Remote State]
        TC --> POLICY[Policy Enforcement]
        TC --> AUDIT[Audit Logs]
    end
    
    subgraph "Multi-Cloud Infrastructure"
        AWS[AWS Resources]
        GCP[GCP Resources]
        AZURE[Azure Resources]
    end
    
    subgraph "Security Layer - Vault"
        VAULT[HashiCorp Vault]
        VAULT --> CREDS[Dynamic Credentials]
    end
    
    DEV1 --> GH
    DEV2 --> GH
    DEV3 --> GH
    
    GH -->|Git Push| TC
    TC -->|Terraform Apply| AWS
    TC -->|Terraform Apply| GCP
    TC -->|Terraform Apply| AZURE
    
    TC <-->|Secrets| VAULT
    
    BENEFITS1[Single Tool]
    BENEFITS2[Git Workflow]
    BENEFITS3[Cloud Agnostic]
    BENEFITS4[Reusable Modules]
    
    style TC fill:#7B42BC
    style VAULT fill:#000000,color:#fff
    style AWS fill:#FF9900
    style GCP fill:#4285F4
    style AZURE fill:#0078D4
    style BENEFITS1 fill:#51cf66
    style BENEFITS2 fill:#51cf66
    style BENEFITS3 fill:#51cf66
    style BENEFITS4 fill:#51cf66
```

## Diagram 3: Demo Architecture (What We'll Build)

```mermaid
graph TB
    subgraph "Demo Application: Widget API"
        APP[Node.js REST API]
        APP -->|Reads/Writes| DB
    end
    
    subgraph "GCP Environment - Primary"
        GKE[GKE Cluster<br/>3 nodes]
        CSQL[Cloud SQL<br/>PostgreSQL]
        GLB[Cloud Load Balancer]
        
        GKE --> APP
        APP --> CSQL
        GLB --> GKE
        
        style GKE fill:#4285F4
        style CSQL fill:#4285F4
        style GLB fill:#4285F4
    end
    
    subgraph "AWS Environment - DR/Failover"
        EKS[EKS Cluster<br/>2 nodes]
        RDS[RDS PostgreSQL]
        ALB[Application LB]
        
        EKS --> APP
        APP --> RDS
        ALB --> EKS
        
        style EKS fill:#FF9900
        style RDS fill:#FF9900
        style ALB fill:#FF9900
    end
    
    subgraph "Terraform Cloud"
        WS1[Dev Workspace]
        WS2[Prod Workspace]
        
        WS1 -->|Provisions| GKE
        WS2 -->|Provisions| EKS
    end
    
    subgraph "Vault Integration - Bonus"
        VAULT[Vault Dynamic Secrets]
        VAULT -->|DB Creds| CSQL
        VAULT -->|DB Creds| RDS
        
        style VAULT fill:#000000,color:#fff
    end
    
    DB[(Widget Orders<br/>Database)]
    
    DEMO1[Terraform provisions both clouds]
    DEMO2[Single codebase, multiple environments]
    DEMO3[Vault secures database access]
    
    style DEMO1 fill:#51cf66
    style DEMO2 fill:#51cf66
    style DEMO3 fill:#51cf66
```

## Diagram 4: Network Topology (Detailed View)

```mermaid
graph LR
    subgraph "GCP - us-central1"
        VPC1[VPC: acme-gcp]
        SUB1[Subnet: 10.1.0.0/24]
        
        subgraph "GKE Cluster"
            POD1[Widget API Pod 1]
            POD2[Widget API Pod 2]
            POD3[Widget API Pod 3]
        end
        
        CSQL[Cloud SQL Private IP<br/>10.1.1.10]
        
        VPC1 --> SUB1
        SUB1 --> POD1
        SUB1 --> POD2
        SUB1 --> POD3
        POD1 --> CSQL
        POD2 --> CSQL
        POD3 --> CSQL
    end
    
    subgraph "AWS - us-east-1"
        VPC2[VPC: acme-aws]
        SUB2[Subnet: 10.2.0.0/24]
        
        subgraph "EKS Cluster"
            POD4[Widget API Pod 1]
            POD5[Widget API Pod 2]
        end
        
        RDS[RDS Private IP<br/>10.2.1.10]
        
        VPC2 --> SUB2
        SUB2 --> POD4
        SUB2 --> POD5
        POD4 --> RDS
        POD5 --> RDS
    end
    
    INTERNET[Internet Users]
    INTERNET -->|HTTPS| VPC1
    INTERNET -->|HTTPS| VPC2
    
    VPC1 -.->|VPN/Interconnect<br/>Future State| VPC2
    
    style CSQL fill:#4285F4
    style RDS fill:#FF9900
```

## Diagram 5: Module Structure (Reusability Pattern)

```mermaid
graph TB
    subgraph "Terraform Root Module"
        MAIN[main.tf<br/>Backend + Providers]
        VARS[variables.tf<br/>Input Variables]
        OUT[outputs.tf<br/>Exported Values]
    end
    
    subgraph "Reusable Modules"
        MOD1[modules/widget-api/]
        MOD2[modules/database/]
        MOD3[modules/networking/]
    end
    
    subgraph "Cloud-Specific Implementations"
        GCP_IMPL[gcp.tf<br/>GKE + Cloud SQL]
        AWS_IMPL[aws.tf<br/>EKS + RDS]
    end
    
    MAIN --> MOD1
    MAIN --> MOD2
    MAIN --> MOD3
    
    GCP_IMPL --> MOD1
    GCP_IMPL --> MOD2
    
    AWS_IMPL --> MOD1
    AWS_IMPL --> MOD2
    
    MOD1 -->|Creates| K8S[Kubernetes Deployment]
    MOD2 -->|Creates| DB[Database Instance]
    MOD3 -->|Creates| NET[VPC/Subnets]
    
    REGISTRY[Terraform Registry<br/>Public Modules]
    REGISTRY -.->|Can Import| MOD1
    
    style MOD1 fill:#7B42BC
    style MOD2 fill:#7B42BC
    style MOD3 fill:#7B42BC
```

## Diagram 6: Data Flow (Secrets Management with Vault)

```mermaid
graph TB
    subgraph "Terraform Provisioning Flow"
        TF[Terraform Cloud]
        TF -->|1. Create DB| CSQL[Cloud SQL]
        TF -->|2. Configure Vault| VAULT
    end
    
    subgraph "Vault Secrets Engine"
        VAULT[Vault Server]
        VAULT -->|3. Enable DB Engine| DB_ENGINE[PostgreSQL Secrets Engine]
        DB_ENGINE -->|4. Configure Connection| CSQL
    end
    
    subgraph "Application Runtime"
        APP[Widget API Pod]
        APP -->|5. Request Creds| VAULT
        VAULT -->|6. Generate Dynamic Creds<br/>TTL: 1 hour| APP
        APP -->|7. Connect with Temp Creds| CSQL
        VAULT -->|8. Revoke After TTL| CSQL
    end
    
    BENEFIT1[No Static Credentials in Code]
    BENEFIT2[Automatic Credential Rotation]
    BENEFIT3[Audit Trail of Access]
    
    style VAULT fill:#000000,color:#fff
    style BENEFIT1 fill:#51cf66
    style BENEFIT2 fill:#51cf66
    style BENEFIT3 fill:#51cf66
```

---

## Diagram Usage Guide

**Diagram 1 (Current State)**: Use at start of demo to set context. "This is what ACME faces today - fragmented tools, vendor lock-in, slow processes."

**Diagram 2 (Proposed Solution)**: Show after current state. "Here's how Terraform solves these problems - single tool, git workflow, cloud agnostic."

**Diagram 3 (Demo Architecture)**: Show before live demo. "This is exactly what I'm about to build for you live."

**Diagram 4 (Network Topology)**: Use for Cloud Architect deep-dive. Shows you understand networking details.

**Diagram 5 (Module Structure)**: Use for DevOps Engineer. Shows code organization and reusability.

**Diagram 6 (Data Flow)**: Use for bonus Vault integration. Shows platform thinking beyond just Terraform.

---

## Mermaid Rendering Notes

These diagrams are in Mermaid format and can be:
- Rendered in GitHub/GitLab markdown
- Exported to PNG/SVG using Mermaid CLI
- Embedded in presentation slides
- Live-edited during demo if needed

To render locally:
```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i architecture-diagrams.md -o diagrams/
```
