# AWS Network Module

This module creates an Amazon Web Services VPC with public and private subnets, Internet Gateway, NAT Gateway, and routing tables.

## Features

- VPC with DNS support enabled
- Public subnets with Internet Gateway access
- Private subnets with NAT Gateway for outbound internet access
- Proper route tables for public and private traffic
- Multi-AZ deployment support
- EKS-compatible subnet tagging
- Elastic IP for NAT Gateway

## Usage

```hcl
module "aws_network" {
  source = "./modules/aws-network"

  project_name       = "acme-widget"
  environment        = "dev"
  vpc_cidr           = "10.2.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  private_subnets    = ["10.2.1.0/24", "10.2.2.0/24"]
  public_subnets     = ["10.2.3.0/24", "10.2.4.0/24"]
  
  tags = {
    Project     = "acme-widget"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_cidr | CIDR block for VPC | string | - | yes |
| availability_zones | List of availability zones | list(string) | - | yes |
| private_subnets | List of private subnet CIDR blocks | list(string) | - | yes |
| public_subnets | List of public subnet CIDR blocks | list(string) | - | yes |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr | The CIDR block of the VPC |
| private_subnet_ids | List of private subnet IDs |
| public_subnet_ids | List of public subnet IDs |
| nat_gateway_id | The ID of the NAT Gateway |
| nat_gateway_ip | The Elastic IP address of the NAT Gateway |

## Resources Created

- `aws_vpc` - VPC with DNS enabled
- `aws_internet_gateway` - Internet Gateway for public access
- `aws_eip` - Elastic IP for NAT Gateway
- `aws_nat_gateway` - NAT Gateway for private subnet egress
- `aws_subnet` (4x default) - Public and private subnets across AZs
- `aws_route_table` (2x) - Route tables for public and private subnets
- `aws_route_table_association` (4x) - Subnet-route table associations

## Network Architecture

```
Internet
    ↓
Internet Gateway (0.0.0.0/0)
    ↓
Public Subnets (10.2.3.0/24, 10.2.4.0/24)
    ↓
NAT Gateway + Elastic IP
    ↓
Private Subnets (10.2.1.0/24, 10.2.2.0/24)
    ↓
EKS Nodes + RDS Database
```

### Routing:
- **Public Route Table**: 0.0.0.0/0 → Internet Gateway
- **Private Route Table**: 0.0.0.0/0 → NAT Gateway

## EKS Integration

Subnets are automatically tagged for EKS discovery:

**Private Subnets:**
- `kubernetes.io/role/internal-elb = 1` (internal load balancers)
- `kubernetes.io/cluster/CLUSTER_NAME = shared`

**Public Subnets:**
- `kubernetes.io/role/elb = 1` (external load balancers)
- `kubernetes.io/cluster/CLUSTER_NAME = shared`

## Security Considerations

- Private subnets have no direct internet access
- NAT Gateway provides controlled outbound access from private subnets
- Public subnets only used for load balancers and NAT Gateway
- All compute and databases deployed in private subnets
- VPC Flow Logs can be enabled (commented in code)

## Cost Optimization

- Single NAT Gateway (not highly available)
  - For production, consider NAT Gateway per AZ
- Elastic IP is released on destroy
- VPC Flow Logs commented out to reduce costs
  - Enable for production environments

## Multi-AZ Considerations

Current setup:
- 2 AZs for demonstration
- Subnets evenly distributed across AZs
- Single NAT Gateway (not HA)

For production:
- Use 3+ AZs
- Deploy NAT Gateway in each AZ for high availability
- Consider using VPC endpoints to reduce NAT costs

## Notes

- The module creates equal numbers of public and private subnets
- NAT Gateway is placed in the first public subnet
- All private subnets share the same NAT Gateway (cost optimization)
- DNS resolution and hostnames are enabled in the VPC
