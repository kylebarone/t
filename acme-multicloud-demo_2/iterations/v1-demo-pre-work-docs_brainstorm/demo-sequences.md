# Demo Flow & Sequence Diagrams

## Demo Sequence Diagram (Complete Flow)

```mermaid
sequenceDiagram
    participant SE as Solutions Engineer
    participant GH as GitHub
    participant TC as Terraform Cloud
    participant GCP as Google Cloud
    participant AWS as Amazon Web Services
    participant VAULT as HashiCorp Vault
    
    Note over SE: [0-3min] Context Setting
    SE->>SE: Show Current State diagram
    SE->>SE: Explain ACME's pain points
    
    Note over SE,GH: [3-5min] Show VCS Integration
    SE->>GH: Navigate to terraform repo
    SE->>GH: Show main.tf, modules/
    SE->>GH: Explain workspace strategy
    
    Note over SE,TC: [5-8min] Initialize & Plan
    SE->>TC: terraform init (remote backend)
    TC-->>SE: Backend configured
    SE->>TC: terraform plan
    TC->>GCP: Query current state
    TC->>AWS: Query current state
    TC-->>SE: Plan output (10 resources to add)
    SE->>SE: Walk through plan output
    
    Note over SE,AWS: [8-12min] Live Deployment
    SE->>TC: terraform apply
    TC->>GCP: Create GKE cluster
    TC->>GCP: Create Cloud SQL
    TC->>GCP: Create Load Balancer
    GCP-->>TC: Resources created
    
    TC->>AWS: Create EKS cluster
    TC->>AWS: Create RDS instance
    TC->>AWS: Create ALB
    AWS-->>TC: Resources created
    
    TC-->>SE: Apply complete! (outputs shown)
    SE->>SE: Show outputs (endpoints, IPs)
    
    Note over SE,TC: [12-15min] Collaboration Demo
    SE->>TC: Create "prod" workspace
    TC-->>SE: Workspace created
    SE->>SE: Show workspace isolation
    SE->>TC: Show state locking in UI
    SE->>TC: Show plan approval workflow
    
    Note over SE,VAULT: [15-17min] Vault Integration (Bonus)
    SE->>VAULT: Configure DB secrets engine
    VAULT->>GCP: Test connection to Cloud SQL
    VAULT-->>SE: Connection successful
    SE->>VAULT: Generate dynamic credentials
    VAULT-->>SE: Temp creds (TTL: 1h)
    SE->>SE: Show creds in application config
    
    Note over SE: [17-20min] Wrap-up
    SE->>SE: Competitive comparison slides
    SE->>SE: Answer questions
    SE->>SE: Propose next steps (POC)
```

## Detailed Demo Flow (Minute-by-Minute)

```mermaid
gantt
    title Demo Timeline (20 minutes)
    dateFormat  mm:ss
    
    section Context
    Current State Pain       :00:00, 02:00
    Proposed Solution Value  :02:00, 01:00
    
    section VCS Demo
    Show GitHub Repo         :03:00, 02:00
    Explain Module Structure :05:00, 01:00
    
    section Terraform Core
    terraform init           :06:00, 01:00
    terraform plan           :07:00, 02:00
    Explain Plan Output      :09:00, 01:00
    terraform apply          :10:00, 04:00
    Show Outputs             :14:00, 01:00
    
    section Collaboration
    Workspace Creation       :15:00, 01:00
    State Locking Demo       :16:00, 01:00
    
    section Platform Bonus
    Vault Integration        :17:00, 02:00
    
    section Closing
    Q&A and Next Steps       :19:00, 01:00
```

## CLI Interaction Flow

```mermaid
flowchart TD
    START([Start Demo])
    
    START --> INIT[Run: terraform init]
    INIT --> INIT_CHECK{Backend Connected?}
    INIT_CHECK -->|Yes| PLAN[Run: terraform plan]
    INIT_CHECK -->|No| INIT_FIX[Troubleshoot backend config]
    INIT_FIX --> INIT
    
    PLAN --> PLAN_CHECK{Plan Successful?}
    PLAN_CHECK -->|Yes| REVIEW[Review Plan Output with Audience]
    PLAN_CHECK -->|No| PLAN_FIX[Debug syntax errors]
    PLAN_FIX --> PLAN
    
    REVIEW --> EXPLAIN[Explain Resources Being Created]
    EXPLAIN --> APPLY_DECISION{Proceed with Apply?}
    
    APPLY_DECISION -->|Yes| APPLY[Run: terraform apply -auto-approve]
    APPLY_DECISION -->|Skip if time short| WORKSPACE
    
    APPLY --> APPLY_PROGRESS[Show Progress in TC UI]
    APPLY_PROGRESS --> APPLY_CHECK{Apply Successful?}
    
    APPLY_CHECK -->|Yes| OUTPUTS[Show: terraform output]
    APPLY_CHECK -->|No| ROLLBACK[Explain rollback strategy]
    ROLLBACK --> RECOVERY[Use backup slides/video]
    
    OUTPUTS --> VERIFY[Verify in Cloud Console]
    VERIFY --> WORKSPACE[Demo Workspace Creation]
    
    WORKSPACE --> LOCK[Show State Locking]
    LOCK --> VAULT_BONUS{Time for Vault?}
    
    VAULT_BONUS -->|Yes| VAULT[Demo Vault Integration]
    VAULT_BONUS -->|No| QA
    
    VAULT --> QA[Q&A Session]
    QA --> END([End Demo])
    
    style START fill:#51cf66
    style END fill:#51cf66
    style APPLY fill:#7B42BC
    style VAULT fill:#000000,color:#fff
```

## Error Handling Flowchart

```mermaid
flowchart TD
    ERROR{Demo Failure?}
    
    ERROR -->|Network Issue| NET_FIX
    ERROR -->|Quota Limit| QUOTA_FIX
    ERROR -->|Syntax Error| SYNTAX_FIX
    ERROR -->|Timeout| TIME_FIX
    ERROR -->|No Error| CONTINUE[Continue Demo]
    
    NET_FIX[Fallback: Recorded Video]
    QUOTA_FIX[Fallback: Pre-deployed Resources]
    SYNTAX_FIX[Fix on the fly - Show debugging]
    TIME_FIX[Skip to next section]
    
    NET_FIX --> RECOVER[Recover and Continue]
    QUOTA_FIX --> RECOVER
    SYNTAX_FIX --> RECOVER
    TIME_FIX --> RECOVER
    
    RECOVER --> ACKNOWLEDGE[Acknowledge Issue Transparently]
    ACKNOWLEDGE --> VALUE[Emphasize Value Prop]
    VALUE --> CONTINUE
    
    CONTINUE --> SUCCESS[Complete Demo]
    
    style ERROR fill:#ff6b6b
    style SUCCESS fill:#51cf66
    style ACKNOWLEDGE fill:#ffd43b
```

## Workspace Collaboration Sequence

```mermaid
sequenceDiagram
    participant SE as Solutions Engineer
    participant TC as Terraform Cloud
    participant GH as GitHub
    participant TEAM as Team Member
    
    Note over SE,TC: Workspace Setup
    SE->>TC: Create "acme-dev" workspace
    SE->>TC: Connect to GitHub repo
    SE->>TC: Configure variables (cloud creds)
    TC-->>SE: Workspace ready
    
    Note over SE,GH: First Deployment
    SE->>GH: Push terraform code
    GH->>TC: Webhook triggers
    TC->>TC: Run terraform plan
    TC-->>SE: Plan ready for review
    SE->>TC: Approve plan
    TC->>TC: Run terraform apply
    TC-->>SE: Apply complete
    
    Note over TEAM,TC: Concurrent Access
    TEAM->>TC: Attempt to run plan
    TC-->>TEAM: State locked by SE
    TC->>TC: Queue plan until unlock
    
    Note over SE,TC: State Locking Demo
    SE->>TC: Show locked state in UI
    SE->>SE: Complete current operation
    TC->>TEAM: Lock released, plan runs
    
    Note over SE,TC: Workspace Isolation
    SE->>TC: Create "acme-prod" workspace
    SE->>TC: Show separate state file
    SE->>SE: Explain: Dev can't affect Prod
```

## Module Reuse Pattern

```mermaid
flowchart LR
    subgraph "Module Definition"
        MODULE[modules/widget-api/]
        MODULE --> VARS[variables.tf<br/>cloud agnostic inputs]
        MODULE --> MAIN[main.tf<br/>resource definitions]
        MODULE --> OUT[outputs.tf<br/>exported values]
    end
    
    subgraph "GCP Usage"
        GCP_CALL[module "widget_gcp"]
        GCP_CALL --> GCP_VARS[cloud = "gcp"<br/>region = "us-central1"]
        GCP_CALL --> MODULE
        MODULE --> GCP_INFRA[GKE + Cloud SQL]
    end
    
    subgraph "AWS Usage"
        AWS_CALL[module "widget_aws"]
        AWS_CALL --> AWS_VARS[cloud = "aws"<br/>region = "us-east-1"]
        AWS_CALL --> MODULE
        MODULE --> AWS_INFRA[EKS + RDS]
    end
    
    BENEFIT[Same Code, Multiple Clouds]
    
    GCP_INFRA --> BENEFIT
    AWS_INFRA --> BENEFIT
    
    style MODULE fill:#7B42BC
    style BENEFIT fill:#51cf66
```

## Persona Engagement Flow

```mermaid
flowchart TD
    START[Demo Begins]
    
    START --> CIO_HOOK[CIO Hook: Cost & Standardization]
    CIO_HOOK --> ARCH_HOOK[Architect Hook: Multi-Cloud Strategy]
    ARCH_HOOK --> DEV_HOOK[DevOps Hook: Git Workflow]
    DEV_HOOK --> SRE_HOOK[SRE Hook: Reproducibility]
    
    SRE_HOOK --> LIVE_DEMO[Live Demo Starts]
    
    LIVE_DEMO --> TECH_DEPTH{Technical Questions?}
    
    TECH_DEPTH -->|Yes from Architect| DEEP_DIVE[Deeper Technical Explanation]
    TECH_DEPTH -->|Yes from DevOps| WORKFLOW[Show CI/CD Integration]
    TECH_DEPTH -->|Yes from SRE| OPS[Show Operational Details]
    TECH_DEPTH -->|No Questions| CONTINUE
    
    DEEP_DIVE --> CONTINUE[Continue Demo]
    WORKFLOW --> CONTINUE
    OPS --> CONTINUE
    
    CONTINUE --> VAULT_DECISION{Show Vault Integration?}
    
    VAULT_DECISION -->|Security Questions Raised| VAULT[Vault Demo]
    VAULT_DECISION -->|Time Running Short| SKIP_VAULT[Skip, Mention for Future]
    
    VAULT --> CLOSE[Closing Statements]
    SKIP_VAULT --> CLOSE
    
    CLOSE --> CIO_CLOSE[CIO: ROI Summary]
    CIO_CLOSE --> ARCH_CLOSE[Architect: Architecture Validation]
    ARCH_CLOSE --> DEV_CLOSE[DevOps: Workflow Benefits]
    DEV_CLOSE --> SRE_CLOSE[SRE: Reliability Gains]
    
    SRE_CLOSE --> NEXT_STEPS[Propose Next Steps]
    NEXT_STEPS --> END[Demo Complete]
    
    style START fill:#51cf66
    style VAULT fill:#000000,color:#fff
    style END fill:#51cf66
```

## Command Cheat Sheet (For Reference During Demo)

```mermaid
flowchart LR
    subgraph "Initialization"
        CMD1[terraform init]
        CMD1_DESC[Connect to remote backend<br/>Download providers]
    end
    
    subgraph "Planning"
        CMD2[terraform plan]
        CMD2_DESC[Show what will change<br/>No actual changes made]
    end
    
    subgraph "Deployment"
        CMD3[terraform apply]
        CMD3_DESC[Create/update resources<br/>Interactive approval]
        
        CMD4[terraform apply -auto-approve]
        CMD4_DESC[Skip confirmation<br/>Use for demos]
    end
    
    subgraph "Inspection"
        CMD5[terraform output]
        CMD5_DESC[Show exported values<br/>Endpoints, IPs]
        
        CMD6[terraform show]
        CMD6_DESC[Show current state<br/>All managed resources]
    end
    
    subgraph "Workspace"
        CMD7[terraform workspace list]
        CMD7_DESC[List all workspaces]
        
        CMD8[terraform workspace select prod]
        CMD8_DESC[Switch workspace context]
    end
    
    subgraph "Cleanup"
        CMD9[terraform destroy]
        CMD9_DESC[Delete all resources<br/>Run after demo]
    end
    
    style CMD1 fill:#7B42BC,color:#fff
    style CMD2 fill:#7B42BC,color:#fff
    style CMD3 fill:#7B42BC,color:#fff
    style CMD4 fill:#7B42BC,color:#fff
```

---

## Usage During Actual Demo

1. **Keep this file open** on second monitor
2. **Reference sequence diagram** to stay on track
3. **Use gantt chart** to monitor timing
4. **Follow CLI flow** to avoid mistakes
5. **Check error handling** if issues arise

**Pro Tip**: Print the "Command Cheat Sheet" and keep it next to keyboard.
