# VPC Configuration
resource "sbercloud_vpc" "main" {
  name = "k8s-vpc"
  cidr = var.vpc_cidr

  tags = {
    Environment = "shared"
    Purpose     = "kubernetes"
  }
}

# Subnet Configuration
resource "sbercloud_vpc_subnet" "main" {
  name       = "k8s-subnet"
  cidr       = var.subnet_cidr
  gateway_ip = cidrhost(var.subnet_cidr, 1)
  vpc_id     = sbercloud_vpc.main.id

  tags = {
    Environment = "shared"
    Purpose     = "kubernetes"
  }
}

# Security Group for Kubernetes Nodes
resource "sbercloud_networking_secgroup" "k8s_nodes" {
  name        = "k8s-nodes-sg"
  description = "Security group for Kubernetes nodes"
}

resource "sbercloud_networking_secgroup_rule" "k8s_nodes_ingress_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.admin_ip_ranges[0]
  security_group_id = sbercloud_networking_secgroup.k8s_nodes.id
}

resource "sbercloud_networking_secgroup_rule" "k8s_nodes_ingress_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = var.admin_ip_ranges[0]
  security_group_id = sbercloud_networking_secgroup.k8s_nodes.id
}

resource "sbercloud_networking_secgroup_rule" "k8s_nodes_ingress_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = sbercloud_networking_secgroup.k8s_nodes.id
}

resource "sbercloud_networking_secgroup_rule" "k8s_nodes_ingress_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = sbercloud_networking_secgroup.k8s_nodes.id
}

resource "sbercloud_networking_secgroup_rule" "k8s_nodes_ingress_nodeports" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = sbercloud_networking_secgroup.k8s_nodes.id
}

resource "sbercloud_networking_secgroup_rule" "k8s_nodes_egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = sbercloud_networking_secgroup.k8s_nodes.id
}

# Security Group for PostgreSQL
resource "sbercloud_networking_secgroup" "postgresql" {
  name        = "postgresql-sg"
  description = "Security group for PostgreSQL instances"
}

resource "sbercloud_networking_secgroup_rule" "postgresql_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = sbercloud_networking_secgroup.postgresql.id
}

# Main Kubernetes Cluster
resource "sbercloud_cce_cluster" "main" {
  name                   = "main-cluster"
  flavor_id              = "cce.s1.small"
  vpc_id                 = sbercloud_vpc.main.id
  subnet_id              = sbercloud_vpc_subnet.main.id
  container_network_type = "overlay_l2"

  tags = {
    Environment = "shared"
    Purpose     = "kubernetes"
  }
}

# Node Pool for Development
resource "sbercloud_cce_node_pool" "dev" {
  cluster_id               = sbercloud_cce_cluster.main.id
  name                    = "dev-node-pool"
  os                      = "EulerOS 2.5"
  flavor_id               = "s6.large.2"
  initial_node_count      = 1
  availability_zone       = var.availability_zone
  key_pair                = sbercloud_compute_keypair.main.name
  scall_enable            = true
  min_node_count          = 1
  max_node_count          = 3
  scale_down_cooldown_time = 100
  priority                = 1

  root_volume {
    size       = 40
    volumetype = "SAS"
  }

  data_volumes {
    size       = 100
    volumetype = "SAS"
  }

  tags = {
    Environment = "dev"
  }
}

# Key Pair for Nodes
resource "sbercloud_compute_keypair" "main" {
  name = "k8s-keypair"
}

# PostgreSQL Instance for Development
resource "sbercloud_rds_instance" "dev_postgres" {
  name              = "dev-postgres"
  flavor            = "rds.pg.c2.medium"
  vpc_id            = sbercloud_vpc.main.id
  subnet_id         = sbercloud_vpc_subnet.main.id
  security_group_id = sbercloud_networking_secgroup.postgresql.id
  availability_zone = [var.availability_zone]

  db {
    type    = "PostgreSQL"
    version = "13"
    port    = 5432
  }

  volume {
    type = "COMMON"
    size = 40
  }

  backup_strategy {
    start_time = "08:00-09:00"
    keep_days  = 3
  }

  tags = {
    Environment = "dev"
  }
}
