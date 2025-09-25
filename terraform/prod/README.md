# Production Environment

Provisions a production-ready Kubernetes environment on SberCloud with enhanced security, high availability, and performance optimizations.

## What It Creates

- **Networking**: VPC (`10.1.0.0/16`), subnet, security groups with restricted access
- **Kubernetes**: CCE cluster + larger node pool (2-5 nodes, s6.xlarge.4)
- **Database**: PostgreSQL instance (rds.pg.c2.large, 100GB) with separate databases and users
- **Storage**: StorageClass `prod-sc` with Retain reclaim policy and larger PVCs (20-50Gi)
- **Applications**: High-availability Helm releases (2 replicas) for Jenkins, Jira, Bitbucket in namespace `prod`
- **Ingress**: HTTPS-enabled hosts with forced SSL redirect and TLS certificates

## Security Features

- **Restricted Access**: SSH (22) and Kubernetes API (6443) limited to `admin_ip_ranges`
- **Network Isolation**: PostgreSQL accessible only from VPC CIDR range
- **Individual Passwords**: Separate database passwords required for each service
- **TLS/SSL**: Forced HTTPS with cert-manager integration for automatic certificates
- **Versioned Deployments**: Pinned Helm chart versions for reproducible deployments

## Required Variables

Defined in `variables.tf`. Provide values via `terraform.tfvars`:

- `access_key`, `secret_key`: SberCloud credentials
- `prod_postgres_password`: Master password for PostgreSQL instance
- `jira_db_password`: Individual password for Jira database user
- `bitbucket_db_password`: Individual password for Bitbucket database user  
- `jenkins_db_password`: Individual password for Jenkins database user

## Optional Security Variables

- `admin_ip_ranges`: IP ranges allowed for SSH/API access (default: `["10.0.0.0/8"]`)
- Network variables: `vpc_cidr`, `subnet_cidr`, `availability_zone`

## Production Configuration

| Component | Specification |
|-----------|---------------|
| **Nodes** | 2-5 nodes, s6.xlarge.4 (4 vCPU, 8GB RAM) |
| **PostgreSQL** | rds.pg.c2.large, 100GB storage, 7-day backup |
| **Jenkins** | 2GB RAM limit, 2GB heap, backup enabled |
| **Jira/Bitbucket** | 2 replicas, 4GB-8GB RAM, 1-2GB heap |
| **Storage** | Jenkins 20Gi, Jira/Bitbucket 50Gi each |
| **Backup Schedule** | 02:00-03:00 daily |

## Prerequisites

- **cert-manager**: Required for automatic TLS certificate management
- **ClusterIssuer**: Named `letsencrypt-prod` for Let's Encrypt certificates
- **DNS**: Valid domains pointing to your cluster ingress

## Remote State

Configured in `backend.tf` using the `s3` backend and SberCloud OBS endpoint:

```bash
export AWS_ACCESS_KEY_ID=your-obs-access-key
export AWS_SECRET_ACCESS_KEY=your-obs-secret-key
```

## Quick Deploy

```bash
cd terraform/prod
cp ../terraform.tfvars.example ./terraform.tfvars

# CRITICAL: Edit terraform.tfvars with your values:
# - access_key, secret_key
# - prod_postgres_password (master password)
# - Individual service passwords (jira_db_password, etc.)
# - admin_ip_ranges (update with your actual IP ranges!)

terraform init
terraform plan
terraform apply
```

## Database Configuration

- **Instance**: rds.pg.c2.large with 100GB storage, 7-day backup retention
- **Backup Window**: 02:00-03:00 (low traffic period)
- **Databases**: `jira_prod`, `bitbucket_prod`, `jenkins_prod`
- **Users**: `jira_user`, `bitbucket_user`, `jenkins_user` (each with individual passwords)

## Application Access

After deployment, applications will be available at:
- Jenkins: https://jenkins.company.com
- Jira: https://jira.company.com
- Bitbucket: https://bitbucket.company.com

**DNS Setup Required**: Update your DNS records to point these domains to your cluster's ingress IP address.

## Monitoring & Backup

- **Database Backups**: Automated daily backups with 7-day retention
- **Application Data**: Persistent volumes with Retain policy (data preserved on deletion)
- **Jenkins Backup**: Built-in backup enabled in Helm configuration

## Outputs

- Infrastructure: `cluster_id`, `vpc_id`, `subnet_id`, `postgres_endpoint` (sensitive)
- Applications: `jenkins_url`, `jira_url`, `bitbucket_url`
- Storage: `storage_class_name`, PVC names

## Security Considerations

1. **Update IP Ranges**: Change `admin_ip_ranges` from defaults to your specific networks
2. **Strong Passwords**: Use complex, unique passwords for each database user
3. **Certificate Management**: Ensure cert-manager is properly configured for your domain
4. **Network Policies**: Consider implementing Kubernetes Network Policies for additional isolation

## Cleanup

```bash
terraform destroy
```

**Warning**: Due to Retain reclaim policy, persistent volumes must be manually deleted after destroy if you want to remove all data permanently.