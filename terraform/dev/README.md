# Development Environment

Provisions a development Kubernetes environment on SberCloud and deploys Jenkins, Jira, and Bitbucket with enhanced security features.

## What It Creates

- **Networking**: VPC (`10.0.0.0/16`), subnet, security groups with restricted access
- **Kubernetes**: CCE cluster + small node pool (1-3 nodes, s6.large.2)
- **Database**: PostgreSQL instance + separate databases and users for each app
- **Storage**: StorageClass `dev-sc` with Delete reclaim policy and PVCs for apps
- **Applications**: Helm releases for Jenkins, Jira, Bitbucket in namespace `dev`
- **Ingress**: HTTP hosts `dev-jenkins.company.local`, `dev-jira.company.local`, `dev-bitbucket.company.local`

## Security Features

- **Restricted Access**: SSH (22) and Kubernetes API (6443) limited to `admin_ip_ranges`
- **Network Isolation**: PostgreSQL accessible only from VPC CIDR range
- **Individual Passwords**: Support for separate database passwords per service
- **Versioned Deployments**: Pinned Helm chart versions (Jenkins 4.8.3, Jira 1.17.0, Bitbucket 1.17.2)

## Required Variables

Defined in `variables.tf`. Provide values via `terraform.tfvars`:

- `access_key`, `secret_key`: SberCloud credentials
- `dev_postgres_password`: Master password for PostgreSQL instance

## Optional Security Variables

- `jira_db_password`: Individual password for Jira user (falls back to master if not set)
- `bitbucket_db_password`: Individual password for Bitbucket user (falls back to master if not set)  
- `jenkins_db_password`: Individual password for Jenkins user (falls back to master if not set)
- `admin_ip_ranges`: IP ranges allowed for SSH/API access (default: `["10.0.0.0/8"]`)

## Remote State

Configured in `backend.tf` using the `s3` backend and SberCloud OBS endpoint. Ensure the bucket exists and export credentials:

```bash
export AWS_ACCESS_KEY_ID=your-obs-access-key
export AWS_SECRET_ACCESS_KEY=your-obs-secret-key
```

## Quick Deploy

```bash
cd terraform/dev
cp ../terraform.tfvars.example ./terraform.tfvars

# IMPORTANT: Edit terraform.tfvars with your values, especially:
# - access_key, secret_key  
# - dev_postgres_password
# - admin_ip_ranges (update with your actual IP ranges!)

terraform init
terraform plan
terraform apply
```

## Database Configuration

- **Instance**: rds.pg.c2.medium with 40GB storage, 3-day backup retention
- **Databases**: `jira_dev`, `bitbucket_dev`, `jenkins_dev`
- **Users**: `jira_user`, `bitbucket_user`, `jenkins_user`
- **Passwords**: Individual passwords supported, falls back to master password

## Outputs

- Infrastructure: `cluster_id`, `vpc_id`, `subnet_id`, `postgres_endpoint` (sensitive)
- Applications: `jenkins_url`, `jira_url`, `bitbucket_url`
- Storage: `storage_class_name`, PVC names

## Access Applications

After deployment, update your DNS or `/etc/hosts` file:
```
<cluster-ingress-ip> dev-jenkins.company.local
<cluster-ingress-ip> dev-jira.company.local  
<cluster-ingress-ip> dev-bitbucket.company.local
```

## Cleanup

```bash
terraform destroy
```

**Note**: PVCs use Delete reclaim policy in dev environment, so data will be permanently deleted.