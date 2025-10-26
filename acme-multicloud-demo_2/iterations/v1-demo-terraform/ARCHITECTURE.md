# Architecture Diagrams - v1-demo-terraform

## Diagram 1: High-Level Multi-Cloud Architecture

```mermaid
graph TB
    subgraph "Terraform Code"
        TF[terraform.tf<br/>Backend + Providers]
        VARS[variables.tf]
        GCP_CODE[gcp.tf]
        AWS_CODE[aws.tf]
        OUT[outputs.tf]
    end
    
    subgraph "GCP Infrastructure"
        VPC1[VPC: acme-widget-vpc-dev<br/>10.1.0.0/24]
        GKE[GKE Cluster<br/>2x e2-medium nodes]
        CSQL[Cloud SQL PostgreSQL<br/>db-f1-micro]
        
        VPC1 --> GKE
        VPC1 --> CSQL
    end
    
    subgraph "AWS Infrastructure"
        VPC2[VPC: acme-widget-vpc-dev<br/>10.2.0.0/16]
        PUB[Public Subnets<br/>10.2.3.0/24, 10.2.4.0/24]
        PRIV[Private Subnets<br/>10.2.1.0/24, 10.2.2.0/24]
        EKS[EKS Cluster<br/>2x t3.medium nodes]
        RDS[RDS PostgreSQL<br/>db.t3.micro]
        
        VPC2 --> PUB
        VPC2 --> PRIV
        PRIV --> EKS
        PRIV --> RDS
    end
    
    TF --> GCP_CODE
    TF --> AWS_CODE
    GCP_CODE --> VPC1
    AWS_CODE --> VPC2
    
    style GKE fill:#4285F4
    style CSQL fill:#4285F4
    style EKS fill:#FF9900
    style RDS fill:#FF9900
```

## Diagram 2: GCP Resource Dependencies

```mermaid
graph TD
    NET[google_compute_network<br/>acme-widget-vpc-dev]
    SUB[google_compute_subnetwork<br/>10.1.0.0/24]
    GKE[google_container_cluster<br/>acme-widget-gke-dev]
    POOL[google_container_node_pool<br/>2 nodes, e2-medium]
    DB[google_sql_database_instance<br/>POSTGRES_15, db-f1-micro]
    DBNAME[google_sql_database<br/>widget_orders_dev]
    USER[google_sql_user<br/>dbadmin]
    PASS[random_password]
    
    NET --> SUB
    NET --> GKE
    SUB --> GKE
    GKE --> POOL
    DB --> DBNAME
    DB --> USER
    PASS --> USER
    
    style NET fill:#e3f2fd
    style GKE fill:#4285F4
    style DB fill:#4285F4
```

## Diagram 3: AWS Resource Dependencies

```mermaid
graph TD
    VPC[aws_vpc<br/>10.2.0.0/16]
    IGW[aws_internet_gateway]
    PUB1[aws_subnet public_1<br/>10.2.3.0/24]
    PUB2[aws_subnet public_2<br/>10.2.4.0/24]
    PRIV1[aws_subnet private_1<br/>10.2.1.0/24]
    PRIV2[aws_subnet private_2<br/>10.2.2.0/24]
    
    EKSROLE[aws_iam_role<br/>eks-cluster-role]
    EKS[aws_eks_cluster<br/>acme-widget-eks-dev]
    NODEROLE[aws_iam_role<br/>eks-node-role]
    NODEGROUP[aws_eks_node_group<br/>2 nodes, t3.medium]
    
    SG[aws_security_group<br/>rds-sg]
    SUBNET_GROUP[aws_db_subnet_group]
    RDS[aws_db_instance<br/>POSTGRES 15.3]
    PASS[random_password]
    
    VPC --> IGW
    VPC --> PUB1
    VPC --> PUB2
    VPC --> PRIV1
    VPC --> PRIV2
    VPC --> SG
    
    EKSROLE --> EKS
    PRIV1 --> EKS
    PRIV2 --> EKS
    PUB1 --> EKS
    PUB2 --> EKS
    
    NODEROLE --> NODEGROUP
    EKS --> NODEGROUP
    
    PRIV1 --> SUBNET_GROUP
    PRIV2 --> SUBNET_GROUP
    SUBNET_GROUP --> RDS
    SG --> RDS
    PASS --> RDS
    
    style VPC fill:#fff3e0
    style EKS fill:#FF9900
    style RDS fill:#FF9900
```

## Diagram 4: Terraform Variable Flow

```mermaid
graph LR
    ENV[environments/dev.tfvars]
    VARS[variables.tf<br/>Definitions + Defaults]
    
    subgraph "GCP Resources"
        GCP_RES[gcp.tf uses:<br/>• gcp_project_id<br/>• gcp_region<br/>• gcp_zone<br/>• enable_gcp]
    end
    
    subgraph "AWS Resources"
        AWS_RES[aws.tf uses:<br/>• aws_region<br/>• enable_aws]
    end
    
    subgraph "Shared"
        SHARED[Both use:<br/>• project_name<br/>• environment<br/>• db_name<br/>• db_username]
    end
    
    ENV --> VARS
    VARS --> GCP_RES
    VARS --> AWS_RES
    VARS --> SHARED
    
    style ENV fill:#d1c4e9
    style VARS fill:#b39ddb
```

## Diagram 5: Deployment Toggle Pattern

```mermaid
flowchart TD
    START[terraform apply]
    
    CHECK_GCP{enable_gcp?}
    CHECK_AWS{enable_aws?}
    
    START --> CHECK_GCP
    
    CHECK_GCP -->|true| GCP[Deploy GCP:<br/>• VPC<br/>• GKE<br/>• Cloud SQL]
    CHECK_GCP -->|false| SKIP_GCP[Skip GCP]
    
    GCP --> CHECK_AWS
    SKIP_GCP --> CHECK_AWS
    
    CHECK_AWS -->|true| AWS[Deploy AWS:<br/>• VPC<br/>• EKS<br/>• RDS]
    CHECK_AWS -->|false| SKIP_AWS[Skip AWS]
    
    AWS --> OUT[terraform output]
    SKIP_AWS --> OUT
    
    OUT --> DONE[Deployment Complete]
    
    style GCP fill:#4285F4,color:#fff
    style AWS fill:#FF9900,color:#fff
    style DONE fill:#51cf66
```

## Diagram 6: Network Architecture Detail

```mermaid
graph TB
    subgraph "GCP Network - 10.1.0.0/24"
        GCP_VPC[VPC: acme-widget-vpc-dev]
        GCP_SUB[Subnet: 10.1.0.0/24<br/>us-central1]
        
        GCP_VPC --> GCP_SUB
        
        subgraph "GKE"
            NODE1[Node 1<br/>e2-medium]
            NODE2[Node 2<br/>e2-medium]
        end
        
        GCP_SUB --> NODE1
        GCP_SUB --> NODE2
        
        DB1[Cloud SQL<br/>Private IP]
        GCP_SUB --> DB1
    end
    
    subgraph "AWS Network - 10.2.0.0/16"
        AWS_VPC[VPC: acme-widget-vpc-dev]
        
        subgraph "Public - AZ a,b"
            PUB_A[10.2.3.0/24]
            PUB_B[10.2.4.0/24]
        end
        
        subgraph "Private - AZ a,b"
            PRIV_A[10.2.1.0/24]
            PRIV_B[10.2.2.0/24]
        end
        
        AWS_VPC --> PUB_A
        AWS_VPC --> PUB_B
        AWS_VPC --> PRIV_A
        AWS_VPC --> PRIV_B
        
        subgraph "EKS"
            EKS_NODE1[Node 1<br/>t3.medium]
            EKS_NODE2[Node 2<br/>t3.medium]
        end
        
        PRIV_A --> EKS_NODE1
        PRIV_B --> EKS_NODE2
        
        DB2[RDS<br/>Private]
        PRIV_A --> DB2
        PRIV_B --> DB2
    end
    
    style GCP_VPC fill:#4285F4,color:#fff
    style AWS_VPC fill:#FF9900,color:#fff
    style DB1 fill:#4285F4
    style DB2 fill:#FF9900
```

## Diagram 7: File Structure

```mermaid
graph TB
    ROOT[v1-demo-terraform/]
    
    ROOT --> TF[terraform.tf<br/>Backend + Providers]
    ROOT --> VARS[variables.tf<br/>Input Definitions]
    ROOT --> OUT[outputs.tf<br/>Exported Values]
    ROOT --> GCP[gcp.tf<br/>GCP Resources]
    ROOT --> AWS[aws.tf<br/>AWS Resources]
    ROOT --> ENV[environments/]
    ROOT --> MOD[modules/]
    
    ENV --> DEV[dev.tfvars]
    ENV --> PROD[prod.tfvars]
    
    MOD --> API[widget-api/main.tf]
    
    style ROOT fill:#7B42BC,color:#fff
    style GCP fill:#4285F4
    style AWS fill:#FF9900
```

## Usage Notes

**Diagram 1:** Show for overall architecture overview  
**Diagram 2-3:** Use for technical deep-dive on specific cloud  
**Diagram 4:** Explain variable management strategy  
**Diagram 5:** Demonstrate toggle feature (enable_gcp/enable_aws)  
**Diagram 6:** Detailed networking for architecture discussion  
**Diagram 7:** Code organization and structure  

## Export Commands

```bash
# Install mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Export diagrams
mmdc -i architecture-v1.md -o diagrams/
```
