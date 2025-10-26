# ============================================================================
# AWS INFRASTRUCTURE - FIXED VERSION
# ============================================================================
# This file contains all AWS resources with complete networking configuration
# including NAT Gateway, Route Tables, and proper EKS integration.
# ============================================================================

# ----------------------------------------------------------------------------
# VPC
# ----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  count                = var.enable_aws ? 1 : 0
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                                    = "${var.project_name}-vpc-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-eks-${var.environment}" = "shared"
  }
}

# ----------------------------------------------------------------------------
# Internet Gateway
# ----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  count  = var.enable_aws ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}"
  }
}

# ----------------------------------------------------------------------------
# Elastic IP for NAT Gateway
# ----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_aws ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ----------------------------------------------------------------------------
# NAT Gateway (in public subnet for private subnet internet access)
# ----------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  count         = var.enable_aws ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_1[0].id

  tags = {
    Name = "${var.project_name}-nat-gateway-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ----------------------------------------------------------------------------
# Subnets - Private (for EKS nodes and RDS)
# ----------------------------------------------------------------------------
resource "aws_subnet" "private_1" {
  count             = var.enable_aws ? 1 : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                                                    = "${var.project_name}-private-1-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-eks-${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"                      = "1"
    Type                                                    = "private"
  }
}

resource "aws_subnet" "private_2" {
  count             = var.enable_aws ? 1 : 0
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                                                    = "${var.project_name}-private-2-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-eks-${var.environment}" = "shared"
    "kubernetes.io/role/internal-elb"                      = "1"
    Type                                                    = "private"
  }
}

# ----------------------------------------------------------------------------
# Subnets - Public (for NAT Gateway and potential load balancers)
# ----------------------------------------------------------------------------
resource "aws_subnet" "public_1" {
  count                   = var.enable_aws ? 1 : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.2.3.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                                    = "${var.project_name}-public-1-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-eks-${var.environment}" = "shared"
    "kubernetes.io/role/elb"                               = "1"
    Type                                                    = "public"
  }
}

resource "aws_subnet" "public_2" {
  count                   = var.enable_aws ? 1 : 0
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.2.4.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                                    = "${var.project_name}-public-2-${var.environment}"
    "kubernetes.io/cluster/${var.project_name}-eks-${var.environment}" = "shared"
    "kubernetes.io/role/elb"                               = "1"
    Type                                                    = "public"
  }
}

# ----------------------------------------------------------------------------
# Route Tables
# ----------------------------------------------------------------------------

# Public Route Table (routes to Internet Gateway)
resource "aws_route_table" "public" {
  count  = var.enable_aws ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
    Type = "public"
  }
}

# Private Route Table (routes to NAT Gateway)
resource "aws_route_table" "private" {
  count  = var.enable_aws ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}"
    Type = "private"
  }
}

# ----------------------------------------------------------------------------
# Route Table Associations
# ----------------------------------------------------------------------------

resource "aws_route_table_association" "public_1" {
  count          = var.enable_aws ? 1 : 0
  subnet_id      = aws_subnet.public_1[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "public_2" {
  count          = var.enable_aws ? 1 : 0
  subnet_id      = aws_subnet.public_2[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private_1" {
  count          = var.enable_aws ? 1 : 0
  subnet_id      = aws_subnet.private_1[0].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "private_2" {
  count          = var.enable_aws ? 1 : 0
  subnet_id      = aws_subnet.private_2[0].id
  route_table_id = aws_route_table.private[0].id
}

# ============================================================================
# EKS CLUSTER RESOURCES
# ============================================================================

# ----------------------------------------------------------------------------
# EKS Cluster IAM Role
# ----------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  count = var.enable_aws ? 1 : 0
  name  = "${var.project_name}-eks-cluster-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.enable_aws ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count      = var.enable_aws ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster[0].name
}

# ----------------------------------------------------------------------------
# EKS Cluster Security Group
# ----------------------------------------------------------------------------
resource "aws_security_group" "eks_cluster" {
  count       = var.enable_aws ? 1 : 0
  name        = "${var.project_name}-eks-cluster-sg-${var.environment}"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-cluster-sg"
  }
}

resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count             = var.enable_aws ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster[0].id
  description       = "Allow workstation to communicate with the cluster API Server"
}

# ----------------------------------------------------------------------------
# EKS Cluster
# ----------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  count    = var.enable_aws ? 1 : 0
  name     = "${var.project_name}-eks-${var.environment}"
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = "1.28"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_1[0].id,
      aws_subnet.private_2[0].id,
      aws_subnet.public_1[0].id,
      aws_subnet.public_2[0].id
    ]
    
    security_group_ids      = [aws_security_group.eks_cluster[0].id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name = "${var.project_name}-eks-${var.environment}"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}

# ----------------------------------------------------------------------------
# EKS Node Group IAM Role
# ----------------------------------------------------------------------------
resource "aws_iam_role" "eks_nodes" {
  count = var.enable_aws ? 1 : 0
  name  = "${var.project_name}-eks-node-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.enable_aws ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.enable_aws ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.enable_aws ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes[0].name
}

# ----------------------------------------------------------------------------
# EKS Node Group
# ----------------------------------------------------------------------------
resource "aws_eks_node_group" "main" {
  count           = var.enable_aws ? 1 : 0
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.project_name}-node-group-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes[0].arn
  
  # Place nodes in private subnets
  subnet_ids = [
    aws_subnet.private_1[0].id,
    aws_subnet.private_2[0].id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  tags = {
    Name = "${var.project_name}-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]
}

# ============================================================================
# RDS DATABASE RESOURCES
# ============================================================================

# ----------------------------------------------------------------------------
# RDS Subnet Group
# ----------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  count      = var.enable_aws ? 1 : 0
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = [
    aws_subnet.private_1[0].id,
    aws_subnet.private_2[0].id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ----------------------------------------------------------------------------
# RDS Security Group
# ----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  count       = var.enable_aws ? 1 : 0
  name        = "${var.project_name}-rds-sg-${var.environment}"
  description = "Allow PostgreSQL traffic from within VPC"
  vpc_id      = aws_vpc.main[0].id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main[0].cidr_block]
    description = "PostgreSQL from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ----------------------------------------------------------------------------
# Random Password for RDS
# ----------------------------------------------------------------------------
resource "random_password" "db_password_aws" {
  length  = 16
  special = true
  
  # Prevent password rotation on apply
  lifecycle {
    ignore_changes = [
      length,
      special
    ]
  }
}

# ----------------------------------------------------------------------------
# RDS PostgreSQL Instance
# ----------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  count                  = var.enable_aws ? 1 : 0
  identifier             = "${var.project_name}-db-${var.environment}"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  storage_encrypted      = true
  
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password_aws.result
  
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  
  # Disable public access - only accessible from VPC
  publicly_accessible = false
  
  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # For demo purposes - in production set to true
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-rds-${var.environment}"
  }
}
