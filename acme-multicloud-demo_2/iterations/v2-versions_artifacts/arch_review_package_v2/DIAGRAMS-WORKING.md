# Technical Architecture Diagrams - Working Reference

**Purpose**: Detailed technical diagrams for engineering teams, architecture reviews, and implementation reference.  
**Version**: 1.2 Current State  
**Last Updated**: October 26, 2025

---

## Diagram 1: Complete Infrastructure Overview

```mermaid
graph TB
    subgraph "Version Control & State"
        GIT[Git Repository]
        TFC[Terraform Cloud<br/>State Management]
    end
    
    subgraph "Terraform Configuration"
        TF[terraform.tf<br/>Providers & Backend]
        VARS[variables.tf<br/>enable_gcp, enable_aws]
        GCP_CODE[gcp.tf<br/>450+ lines]
        AWS_CODE[aws.tf<br/>470+ lines]
        OUT[outputs.tf<br/>Network, Cluster, DB info]
    end
    
    subgraph "GCP Infrastructure - us-central1"
        VPC1[VPC: acme-widget-vpc-dev<br/>Custom Mode, Regional Routing]
        SUB1[Subnet: 10.1.0.0/24<br/>+ Pods: 10.1.16.0/20<br/>+ Services: 10.1.32.0/20]
        FW1[Firewall Rules<br/>Internal, Health Check, SSH]
        PRIV_CONN[Private Service Connection<br/>VPC Peering]
        
        GKE[GKE Cluster<br/>Private Nodes<br/>Control Plane: 172.16.0.0/28]
        POOL1[Node Pool<br/>2x e2-medium<br/>Auto-scaling 1-3]
        
        CSQL[Cloud SQL PostgreSQL 15<br/>db-f1-micro, 10GB SSD<br/>PRIVATE IP ONLY]
        CSQL_DB[Database: widget_orders_dev]
        CSQL_USER[User: dbadmin]
        
        VPC1 --> SUB1
        VPC1 --> FW1
        VPC1 --> PRIV_CONN
        SUB1 --> GKE
        GKE --> POOL1
        PRIV_CONN --> CSQL
        CSQL --> CSQL_DB
        CSQL --> CSQL_USER
    end
    
    subgraph "AWS Infrastructure - us-east-1"
        VPC2[VPC: acme-widget-vpc-dev<br/>10.2.0.0/16<br/>DNS Support + Hostnames]
        
        IGW[Internet Gateway<br/>Public Internet Access]
        EIP[Elastic IP<br/>Static Public IP]
        NAT[NAT Gateway<br/>Private → Internet]
        
        PUB1[Public Subnet 1<br/>10.2.3.0/24, AZ-a<br/>Route: IGW]
        PUB2[Public Subnet 2<br/>10.2.4.0/24, AZ-b<br/>Route: IGW]
        PRIV1[Private Subnet 1<br/>10.2.1.0/24, AZ-a<br/>Route: NAT]
        PRIV2[Private Subnet 2<br/>10.2.2.0/24, AZ-b<br/>Route: NAT]
        
        RT_PUB[Public Route Table<br/>0.0.0.0/0 → IGW]
        RT_PRIV[Private Route Table<br/>0.0.0.0/0 → NAT]
        
        EKS_ROLE[EKS Cluster IAM Role<br/>+ EKS Policies]
        EKS_SG[EKS Security Group<br/>443 Ingress]
        EKS[EKS Cluster v1.28<br/>Private/Public Endpoint]
        
        NODE_ROLE[Node IAM Role<br/>+ Worker, CNI, ECR]
        NODEGROUP[EKS Node Group<br/>2x t3.medium<br/>Auto-scaling 1-3]
        
        RDS_SG[RDS Security Group<br/>5432 from VPC]
        RDS_SUBNET[DB Subnet Group<br/>Private Subnets]
        RDS[RDS PostgreSQL 15.3<br/>db.t3.micro, 20GB GP2<br/>PRIVATE, Encrypted]
        
        VPC2 --> IGW
        VPC2 --> PUB1
        VPC2 --> PUB2
        VPC2 --> PRIV1
        VPC2 --> PRIV2
        
        PUB1 --> NAT
        EIP --> NAT
        IGW --> PUB1
        IGW --> PUB2
        
        RT_PUB --> PUB1
        RT_PUB --> PUB2
        RT_PRIV --> PRIV1
        RT_PRIV --> PRIV2
        
        NAT --> RT_PRIV
        IGW --> RT_PUB
        
        EKS_ROLE --> EKS
        EKS_SG --> EKS
        PRIV1 --> EKS
        PRIV2 --> EKS
        PUB1 --> EKS
        PUB2 --> EKS
        
        NODE_ROLE --> NODEGROUP
        EKS --> NODEGROUP
        PRIV1 --> NODEGROUP
        PRIV2 --> NODEGROUP
        
        RDS_SUBNET --> RDS
        RDS_SG --> RDS
        PRIV1 --> RDS_SUBNET
        PRIV2 --> RDS_SUBNET
    end
    
    GIT --> TF
    TF --> TFC
    TF --> GCP_CODE
    TF --> AWS_CODE
    GCP_CODE --> VPC1
    AWS_CODE --> VPC2
    
    style GKE fill:#4285F4,color:#fff
    style CSQL fill:#4285F4,color:#fff
    style EKS fill:#FF9900,color:#fff
    style RDS fill:#FF9900,color:#fff
    style NAT fill:#FFD700
    style PRIV_CONN fill:#90EE90
```

---

## Diagram 2: AWS Network Topology with Routing Details

```mermaid
graph TB
    INTERNET[Internet]
    
    subgraph "VPC: 10.2.0.0/16"
        IGW[Internet Gateway<br/>aws_internet_gateway]
        
        subgraph "Availability Zone A"
            PUB_A[Public Subnet<br/>10.2.3.0/24<br/>map_public_ip: true]
            PRIV_A[Private Subnet<br/>10.2.1.0/24<br/>kubernetes.io/role/internal-elb]
            
            NAT_GW[NAT Gateway<br/>in Public Subnet A]
            EIP_NAT[Elastic IP<br/>Static Public IP]
            
            EKS_NODE_A[EKS Node<br/>t3.medium<br/>Private IP]
            RDS_AZ_A[RDS Instance<br/>Primary in AZ-a]
        end
        
        subgraph "Availability Zone B"
            PUB_B[Public Subnet<br/>10.2.4.0/24<br/>map_public_ip: true]
            PRIV_B[Private Subnet<br/>10.2.2.0/24<br/>kubernetes.io/role/internal-elb]
            
            EKS_NODE_B[EKS Node<br/>t3.medium<br/>Private IP]
        end
        
        subgraph "Routing"
            RT_PUBLIC[Public Route Table<br/>aws_route_table.public]
            RT_PRIVATE[Private Route Table<br/>aws_route_table.private]
            
            ROUTE_PUB[Route: 0.0.0.0/0<br/>→ Internet Gateway]
            ROUTE_PRIV[Route: 0.0.0.0/0<br/>→ NAT Gateway]
        end
        
        subgraph "EKS Control Plane"
            EKS_CP[EKS Control Plane<br/>Managed by AWS<br/>Public/Private Access]
        end
        
        subgraph "Security"
            EKS_SG[EKS Cluster SG<br/>Ingress: 443<br/>Egress: All]
            RDS_SG[RDS SG<br/>Ingress: 5432 from VPC<br/>Egress: All]
        end
    end
    
    INTERNET --> IGW
    IGW --> ROUTE_PUB
    
    ROUTE_PUB --> RT_PUBLIC
    RT_PUBLIC -.associates.-> PUB_A
    RT_PUBLIC -.associates.-> PUB_B
    
    EIP_NAT --> NAT_GW
    NAT_GW --> PUB_A
    NAT_GW --> ROUTE_PRIV
    
    ROUTE_PRIV --> RT_PRIVATE
    RT_PRIVATE -.associates.-> PRIV_A
    RT_PRIVATE -.associates.-> PRIV_B
    
    PRIV_A --> EKS_NODE_A
    PRIV_B --> EKS_NODE_B
    
    EKS_SG --> EKS_CP
    EKS_CP -.manages.-> EKS_NODE_A
    EKS_CP -.manages.-> EKS_NODE_B
    
    PRIV_A --> RDS_AZ_A
    PRIV_B -.backup.-> RDS_AZ_A
    RDS_SG --> RDS_AZ_A
    
    EKS_NODE_A -.NAT egress.-> NAT_GW
    EKS_NODE_B -.NAT egress.-> NAT_GW
    
    EKS_NODE_A -.database.-> RDS_AZ_A
    EKS_NODE_B -.database.-> RDS_AZ_A
    
    style NAT_GW fill:#FFD700
    style EIP_NAT fill:#FFD700
    style RT_PUBLIC fill:#90EE90
    style RT_PRIVATE fill:#FFA07A
    style EKS_CP fill:#FF9900,color:#fff
```

---

## Diagram 3: GCP Network Topology with Private Service Connection

```mermaid
graph TB
    INTERNET[Internet]
    
    subgraph "VPC: acme-widget-vpc-dev"
        direction TB
        
        VPC[VPC Network<br/>Custom Mode<br/>Regional Routing]
        
        subgraph "Subnet: us-central1"
            PRIMARY[Primary Range<br/>10.1.0.0/24<br/>256 IPs for Nodes]
            POD_RANGE[Secondary Range: Pods<br/>10.1.16.0/20<br/>4,096 IPs]
            SVC_RANGE[Secondary Range: Services<br/>10.1.32.0/20<br/>4,096 IPs]
        end
        
        subgraph "Firewall Rules"
            FW_INT[allow-internal<br/>TCP/UDP/ICMP<br/>Source: 10.1.0.0/24, pod, svc ranges]
            FW_HEALTH[allow-health-check<br/>TCP from 35.191.0.0/16<br/>130.211.0.0/22]
            FW_SSH[allow-ssh<br/>TCP:22 from IAP<br/>35.235.240.0/20]
        end
        
        subgraph "GKE Cluster"
            GKE_CP[GKE Control Plane<br/>Master CIDR: 172.16.0.0/28<br/>Public Endpoint Enabled]
            
            GKE_NODE1[GKE Node 1<br/>e2-medium<br/>Private IP: 10.1.0.x<br/>No Public IP]
            GKE_NODE2[GKE Node 2<br/>e2-medium<br/>Private IP: 10.1.0.y<br/>No Public IP]
            
            POD1[Pods<br/>IP: 10.1.16.0/20]
            POD2[Services<br/>IP: 10.1.32.0/20]
        end
        
        subgraph "Private Service Connection"
            GLOBAL_ADDR[Global Address<br/>Reserved IP Range<br/>Purpose: VPC_PEERING]
            VPC_PEER[Service Networking<br/>Connection<br/>servicenetworking.googleapis.com]
        end
        
        subgraph "Cloud SQL"
            CSQL[Cloud SQL Instance<br/>PostgreSQL 15<br/>Private IP Only<br/>No Public IP]
            CSQL_PRIV_IP[Private IP<br/>Assigned from<br/>Peered Range]
        end
        
        subgraph "Access Patterns"
            PRIV_GOOGLE[Private Google Access<br/>Enabled on Subnet<br/>Access GCP APIs]
        end
    end
    
    INTERNET -.public endpoint.-> GKE_CP
    
    VPC --> PRIMARY
    VPC --> POD_RANGE
    VPC --> SVC_RANGE
    VPC --> FW_INT
    VPC --> FW_HEALTH
    VPC --> FW_SSH
    
    PRIMARY --> GKE_NODE1
    PRIMARY --> GKE_NODE2
    
    GKE_CP -.manages.-> GKE_NODE1
    GKE_CP -.manages.-> GKE_NODE2
    
    POD_RANGE --> POD1
    SVC_RANGE --> POD2
    
    GKE_NODE1 --> POD1
    GKE_NODE2 --> POD1
    POD1 --> POD2
    
    VPC --> GLOBAL_ADDR
    GLOBAL_ADDR --> VPC_PEER
    VPC_PEER -.private peering.-> CSQL
    CSQL --> CSQL_PRIV_IP
    
    GKE_NODE1 -.database access.-> CSQL_PRIV_IP
    GKE_NODE2 -.database access.-> CSQL_PRIV_IP
    
    PRIMARY --> PRIV_GOOGLE
    PRIV_GOOGLE -.API calls.-> INTERNET
    
    FW_INT --> GKE_NODE1
    FW_INT --> GKE_NODE2
    FW_HEALTH --> GKE_NODE1
    FW_HEALTH --> GKE_NODE2
    
    style CSQL fill:#4285F4,color:#fff
    style VPC_PEER fill:#90EE90
    style PRIV_GOOGLE fill:#87CEEB
    style GKE_CP fill:#4285F4,color:#fff
```

---

## Diagram 4: Resource Dependency Graph - AWS

```mermaid
graph TD
    VPC[aws_vpc.main<br/>10.2.0.0/16]
    
    IGW[aws_internet_gateway.main]
    EIP[aws_eip.nat<br/>depends_on: IGW]
    
    PUB1[aws_subnet.public_1<br/>10.2.3.0/24]
    PUB2[aws_subnet.public_2<br/>10.2.4.0/24]
    PRIV1[aws_subnet.private_1<br/>10.2.1.0/24]
    PRIV2[aws_subnet.private_2<br/>10.2.2.0/24]
    
    NAT[aws_nat_gateway.main<br/>depends_on: IGW]
    
    RT_PUB[aws_route_table.public]
    RT_PRIV[aws_route_table.private]
    
    RTA_PUB1[aws_route_table_association<br/>public_1]
    RTA_PUB2[aws_route_table_association<br/>public_2]
    RTA_PRIV1[aws_route_table_association<br/>private_1]
    RTA_PRIV2[aws_route_table_association<br/>private_2]
    
    EKS_ROLE[aws_iam_role<br/>eks_cluster]
    EKS_POL1[aws_iam_role_policy_attachment<br/>EKSClusterPolicy]
    EKS_POL2[aws_iam_role_policy_attachment<br/>EKSVPCResourceController]
    EKS_SG[aws_security_group<br/>eks_cluster]
    
    EKS[aws_eks_cluster.main<br/>depends_on: policies]
    
    NODE_ROLE[aws_iam_role<br/>eks_nodes]
    NODE_POL1[aws_iam_role_policy_attachment<br/>WorkerNodePolicy]
    NODE_POL2[aws_iam_role_policy_attachment<br/>CNI_Policy]
    NODE_POL3[aws_iam_role_policy_attachment<br/>ContainerRegistryReadOnly]
    
    NODEGROUP[aws_eks_node_group.main<br/>depends_on: node policies]
    
    DB_SUBNET[aws_db_subnet_group.main]
    RDS_SG[aws_security_group.rds]
    RDS_PASS[random_password<br/>db_password_aws]
    RDS[aws_db_instance.main]
    
    VPC --> IGW
    VPC --> PUB1
    VPC --> PUB2
    VPC --> PRIV1
    VPC --> PRIV2
    VPC --> RT_PUB
    VPC --> RT_PRIV
    VPC --> EKS_SG
    VPC --> RDS_SG
    
    IGW --> EIP
    IGW --> NAT
    EIP --> NAT
    PUB1 --> NAT
    
    IGW --> RT_PUB
    NAT --> RT_PRIV
    
    RT_PUB --> RTA_PUB1
    RT_PUB --> RTA_PUB2
    PUB1 --> RTA_PUB1
    PUB2 --> RTA_PUB2
    
    RT_PRIV --> RTA_PRIV1
    RT_PRIV --> RTA_PRIV2
    PRIV1 --> RTA_PRIV1
    PRIV2 --> RTA_PRIV2
    
    EKS_ROLE --> EKS_POL1
    EKS_ROLE --> EKS_POL2
    EKS_POL1 --> EKS
    EKS_POL2 --> EKS
    EKS_SG --> EKS
    PRIV1 --> EKS
    PRIV2 --> EKS
    PUB1 --> EKS
    PUB2 --> EKS
    
    NODE_ROLE --> NODE_POL1
    NODE_ROLE --> NODE_POL2
    NODE_ROLE --> NODE_POL3
    NODE_POL1 --> NODEGROUP
    NODE_POL2 --> NODEGROUP
    NODE_POL3 --> NODEGROUP
    EKS --> NODEGROUP
    PRIV1 --> NODEGROUP
    PRIV2 --> NODEGROUP
    
    PRIV1 --> DB_SUBNET
    PRIV2 --> DB_SUBNET
    DB_SUBNET --> RDS
    RDS_SG --> RDS
    RDS_PASS --> RDS
    
    style NAT fill:#FFD700
    style EKS fill:#FF9900,color:#fff
    style RDS fill:#FF9900,color:#fff
```

---

## Diagram 5: Resource Dependency Graph - GCP

```mermaid
graph TD
    VPC[google_compute_network.vpc<br/>Custom Mode]
    
    SUBNET[google_compute_subnetwork.subnet<br/>10.1.0.0/24 + secondary ranges]
    
    FW1[google_compute_firewall<br/>allow_internal]
    FW2[google_compute_firewall<br/>allow_health_check]
    FW3[google_compute_firewall<br/>allow_ssh]
    
    GLOBAL_ADDR[google_compute_global_address<br/>private_ip_address<br/>Purpose: VPC_PEERING]
    
    SVC_CONN[google_service_networking_connection<br/>private_vpc_connection]
    
    GKE[google_container_cluster.primary<br/>depends_on: subnet]
    
    NODE_POOL[google_container_node_pool<br/>primary_nodes]
    
    CSQL[google_sql_database_instance.main<br/>depends_on: svc_connection]
    
    CSQL_DB[google_sql_database.database]
    
    PASS[random_password<br/>db_password]
    CSQL_USER[google_sql_user.user]
    
    VPC --> SUBNET
    VPC --> FW1
    VPC --> FW2
    VPC --> FW3
    VPC --> GLOBAL_ADDR
    
    SUBNET --> GKE
    
    GLOBAL_ADDR --> SVC_CONN
    VPC --> SVC_CONN
    
    GKE --> NODE_POOL
    
    SVC_CONN --> CSQL
    VPC --> CSQL
    
    CSQL --> CSQL_DB
    CSQL --> CSQL_USER
    PASS --> CSQL_USER
    
    style GKE fill:#4285F4,color:#fff
    style CSQL fill:#4285F4,color:#fff
    style SVC_CONN fill:#90EE90
```

---

## Diagram 6: Traffic Flow - Kubernetes Pod to Database

### AWS EKS to RDS

```mermaid
sequenceDiagram
    participant POD as Pod in EKS
    participant NODE as EKS Node<br/>(Private Subnet)
    participant VPC as VPC Network
    participant SG as RDS Security Group
    participant RDS as RDS PostgreSQL<br/>(Private Subnet)
    
    POD->>NODE: Connect to RDS endpoint
    Note over POD,NODE: Pod uses kube-dns<br/>or CoreDNS
    
    NODE->>VPC: Route within VPC<br/>10.2.0.0/16
    Note over NODE,VPC: No NAT needed<br/>Same VPC traffic
    
    VPC->>SG: Check security group rules
    Note over VPC,SG: Allow from VPC CIDR<br/>Port 5432
    
    SG->>RDS: Connection allowed
    Note over SG,RDS: Private IP only<br/>No public endpoint
    
    RDS-->>POD: Database connection established
    Note over POD,RDS: Encrypted in transit<br/>Storage encrypted at rest
```

### GCP GKE to Cloud SQL

```mermaid
sequenceDiagram
    participant POD as Pod in GKE
    participant NODE as GKE Node<br/>(10.1.0.0/24)
    participant VPC as VPC Network
    participant PEER as VPC Peering
    participant CSQL as Cloud SQL<br/>(Private IP)
    
    POD->>NODE: Connect to Cloud SQL<br/>private IP
    Note over POD,NODE: Pod from<br/>10.1.16.0/20 range
    
    NODE->>VPC: Internal routing
    Note over NODE,VPC: Firewall rules<br/>allow internal
    
    VPC->>PEER: Route via VPC peering
    Note over VPC,PEER: servicenetworking<br/>googleapis.com
    
    PEER->>CSQL: Private connection
    Note over PEER,CSQL: No public IP<br/>No Cloud SQL Proxy needed
    
    CSQL-->>POD: Database connection
    Note over POD,CSQL: SSL optional<br/>(require_ssl configurable)
```

---

## Diagram 7: Internet Egress Patterns

### AWS - NAT Gateway Egress

```mermaid
graph LR
    POD[Pod in EKS<br/>10.1.16.x]
    NODE[EKS Node<br/>10.2.1.x<br/>Private Subnet]
    RT[Private Route Table<br/>0.0.0.0/0 → NAT]
    NAT[NAT Gateway<br/>Public Subnet<br/>Elastic IP]
    IGW[Internet Gateway]
    INTERNET[Internet<br/>Docker Hub, etc]
    
    POD --> NODE
    NODE --> RT
    RT --> NAT
    NAT --> IGW
    IGW --> INTERNET
    
    style NAT fill:#FFD700
    style RT fill:#FFA07A
```

### GCP - Private Google Access

```mermaid
graph LR
    POD[Pod in GKE<br/>10.1.16.x]
    NODE[GKE Node<br/>10.1.0.x<br/>No Public IP]
    SUBNET[Subnet with<br/>Private Google Access]
    GOOGLE[Google APIs<br/>storage.googleapis.com<br/>etc]
    INTERNET[Internet<br/>via Google's network]
    
    POD --> NODE
    NODE --> SUBNET
    SUBNET --> GOOGLE
    SUBNET -.optional.-> INTERNET
    
    style SUBNET fill:#87CEEB
    style GOOGLE fill:#90EE90
```

---

## Diagram 8: Conditional Resource Creation Logic

```mermaid
flowchart TD
    START[terraform apply]
    
    READ_VARS[Read variables.tf<br/>+ environments/*.tfvars]
    
    CHECK_GCP{enable_gcp == true?}
    CHECK_AWS{enable_aws == true?}
    
    START --> READ_VARS
    READ_VARS --> CHECK_GCP
    
    CHECK_GCP -->|Yes| GCP_COUNT[All GCP resources<br/>count = 1]
    CHECK_GCP -->|No| GCP_SKIP[All GCP resources<br/>count = 0, SKIP]
    
    GCP_COUNT --> CREATE_GCP[Create GCP:<br/>• VPC + Subnet + Firewall<br/>• Global Address + VPC Peering<br/>• GKE Cluster + Node Pool<br/>• Cloud SQL + Database + User<br/>• Random Password]
    
    GCP_COUNT --> CHECK_AWS
    GCP_SKIP --> CHECK_AWS
    
    CHECK_AWS -->|Yes| AWS_COUNT[All AWS resources<br/>count = 1]
    CHECK_AWS -->|No| AWS_SKIP[All AWS resources<br/>count = 0, SKIP]
    
    AWS_COUNT --> CREATE_AWS[Create AWS:<br/>• VPC + IGW + NAT + EIP<br/>• 4 Subnets + Route Tables<br/>• EKS Cluster + Node Group<br/>• RDS Instance<br/>• Security Groups<br/>• Random Password]
    
    CREATE_GCP --> OUTPUTS
    CREATE_AWS --> OUTPUTS
    AWS_SKIP --> OUTPUTS
    
    OUTPUTS[Generate outputs.tf<br/>Conditionally display values]
    
    OUTPUTS --> DONE[Deployment Complete<br/>State saved to Terraform Cloud]
    
    style CREATE_GCP fill:#4285F4,color:#fff
    style CREATE_AWS fill:#FF9900,color:#fff
    style DONE fill:#90EE90
```

---

## Diagram 9: File Structure and Module Organization

```mermaid
graph TB
    ROOT[v1-demo-terraform/]
    
    subgraph "Core Configuration"
        TF[terraform.tf<br/>• Backend: Terraform Cloud<br/>• Providers: aws ~5.0, google ~5.0<br/>• kubernetes ~2.23]
        VARS[variables.tf<br/>• enable_gcp, enable_aws<br/>• regions, zones, project IDs<br/>• database config]
        OUT[outputs.tf<br/>• VPC/Network details<br/>• Cluster endpoints<br/>• Database connections]
    end
    
    subgraph "Cloud Resources"
        GCP[gcp.tf (366 lines)<br/>• VPC + Subnet + Secondary ranges<br/>• Firewall rules (3)<br/>• Private service connection<br/>• GKE + Node pool<br/>• Cloud SQL + DB + User]
        
        AWS[aws.tf (472 lines)<br/>• VPC + IGW + NAT + EIP<br/>• 4 Subnets + 2 Route Tables<br/>• 4 Route table associations<br/>• EKS + Node group<br/>• IAM roles (2) + policies (5)<br/>• RDS + Security groups (2)]
    end
    
    subgraph "Environment Configs"
        ENV_DIR[environments/]
        DEV[dev.tfvars<br/>• environment = dev<br/>• enable_gcp = true<br/>• enable_aws = true]
        PROD[prod.tfvars<br/>• environment = prod<br/>• enable_gcp = true<br/>• enable_aws = true]
    end
    
    subgraph "Modules (Future)"
        MOD_DIR[modules/]
        API[widget-api/<br/>• main.tf (placeholder)<br/>• Variables for K8s deployment]
    end
    
    subgraph "Documentation"
        README[README.md<br/>Getting Started Guide]
        ARCH[ARCHITECTURE.md<br/>Design & Decisions]
        SETUP[SETUP.md<br/>Detailed Setup]
        GITIGNORE[.gitignore<br/>Terraform artifacts]
    end
    
    ROOT --> TF
    ROOT --> VARS
    ROOT --> OUT
    ROOT --> GCP
    ROOT --> AWS
    ROOT --> ENV_DIR
    ROOT --> MOD_DIR
    ROOT --> README
    ROOT --> ARCH
    ROOT --> SETUP
    ROOT --> GITIGNORE
    
    ENV_DIR --> DEV
    ENV_DIR --> PROD
    
    MOD_DIR --> API
    
    style GCP fill:#4285F4,color:#fff
    style AWS fill:#FF9900,color:#fff
    style ROOT fill:#7B42BC,color:#fff
```

---

## Notes for Engineering Teams

### Using These Diagrams

1. **Diagram 1**: Start here for overall system understanding
2. **Diagrams 2-3**: Network architecture details for troubleshooting
3. **Diagrams 4-5**: Resource dependencies for understanding creation order
4. **Diagrams 6-7**: Traffic patterns for security reviews
5. **Diagram 8**: Logic flow for understanding toggle mechanism
6. **Diagram 9**: Code organization for new team members

### Rendering These Diagrams

```bash
# Using mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# Render all diagrams
mmdc -i DIAGRAMS-WORKING.md -o output/

# Or use online renderer
# https://mermaid.live/
```

### Updating These Diagrams

When infrastructure changes:
1. Update the affected diagram(s)
2. Update version number in header
3. Add note to version history
4. Run terraform plan to verify
5. Update ARCHITECTURE.md if needed

---

**Version**: 1.2 Current State  
**Last Updated**: October 26, 2025  
**Maintained by**: Engineering Team
