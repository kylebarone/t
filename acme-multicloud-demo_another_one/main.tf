# Local values for resource naming and tagging
locals {
  project_prefix = "${var.project_name}-${var.environment}"
  
  common_labels = merge(
    {
      project     = var.project_name
      environment = var.environment
      managed_by  = "terraform"
    },
    var.common_tags
  )
}

# Random password generation for databases
resource "random_password" "gcp_db_password" {
  count   = var.enable_gcp ? 1 : 0
  length  = 16
  special = true
}

resource "random_password" "aws_db_password" {
  count   = var.enable_aws ? 1 : 0
  length  = 16
  special = true
}

#------------------------------------------------------------------------------
# GCP Infrastructure
#------------------------------------------------------------------------------

# GCP Network
module "gcp_network" {
  count  = var.enable_gcp ? 1 : 0
  source = "./modules/gcp-network"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.gcp_region
  network_cidr        = var.gcp_network_cidr
  pods_cidr           = var.gcp_pods_cidr
  services_cidr       = var.gcp_services_cidr
  labels              = local.common_labels
}

# GCP GKE Cluster
module "gcp_gke" {
  count  = var.enable_gcp ? 1 : 0
  source = "./modules/gcp-gke"

  project_name         = var.project_name
  environment          = var.environment
  region               = var.gcp_region
  zone                 = var.gcp_zone
  network_name         = module.gcp_network[0].network_name
  subnet_name          = module.gcp_network[0].subnet_name
  pods_range_name      = module.gcp_network[0].pods_range_name
  services_range_name  = module.gcp_network[0].services_range_name
  machine_type         = var.gke_machine_type
  min_nodes            = var.gke_min_nodes
  max_nodes            = var.gke_max_nodes
  initial_node_count   = var.gke_initial_node_count
  labels               = local.common_labels
}

# GCP Cloud SQL Database
module "gcp_database" {
  count  = var.enable_gcp ? 1 : 0
  source = "./modules/gcp-database"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.gcp_region
  network_id          = module.gcp_network[0].network_id
  database_name       = var.db_name
  database_user       = var.db_username
  database_password   = random_password.gcp_db_password[0].result
  tier                = var.cloudsql_tier
  disk_size           = var.cloudsql_disk_size
  backup_retention    = var.db_backup_retention_days
  labels              = local.common_labels

  depends_on = [module.gcp_network]
}

#------------------------------------------------------------------------------
# AWS Infrastructure
#------------------------------------------------------------------------------

# AWS Network
module "aws_network" {
  count  = var.enable_aws ? 1 : 0
  source = "./modules/aws-network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.aws_vpc_cidr
  availability_zones   = var.aws_availability_zones
  private_subnets      = var.aws_private_subnets
  public_subnets       = var.aws_public_subnets
  tags                 = local.common_labels
}

# AWS EKS Cluster
module "aws_eks" {
  count  = var.enable_aws ? 1 : 0
  source = "./modules/aws-eks"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.aws_network[0].vpc_id
  private_subnet_ids = module.aws_network[0].private_subnet_ids
  public_subnet_ids  = module.aws_network[0].public_subnet_ids
  instance_type      = var.eks_instance_type
  desired_size       = var.eks_desired_size
  min_size           = var.eks_min_size
  max_size           = var.eks_max_size
  tags               = local.common_labels

  depends_on = [module.aws_network]
}

# AWS RDS Database
module "aws_database" {
  count  = var.enable_aws ? 1 : 0
  source = "./modules/aws-database"

  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.aws_network[0].vpc_id
  private_subnet_ids  = module.aws_network[0].private_subnet_ids
  vpc_cidr            = var.aws_vpc_cidr
  database_name       = var.db_name
  database_user       = var.db_username
  database_password   = random_password.aws_db_password[0].result
  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  backup_retention    = var.db_backup_retention_days
  tags                = local.common_labels

  depends_on = [module.aws_network]
}
