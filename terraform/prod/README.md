# Production Environment

Provisions a production-ready Kubernetes environment on SberCloud and deploys Jenkins, Jira, and Bitbucket with higher resource settings.

## What It Creates

- Networking: VPC, subnet, security groups
- Kubernetes: CCE cluster + a larger node pool
- Database: PostgreSQL instance for production
- Storage: StorageClass `prod-sc` (retain policy) and PVCs
- Apps: Helm releases for Jenkins, Jira, Bitbucket in namespace `prod`
- Ingress: TLS-enabled hosts `jenkins.company.com`, `jira.company.com`, `bitbucket.company.com`

## Inputs

Defined in `variables.tf`. Provide values via `terraform.tfvars`:

- `access_key`, `secret_key`: SberCloud credentials
- `prod_postgres_password`: password for all prod app DB users
- `vpc_cidr`, `subnet_cidr`, `availability_zone`: networking defaults

A sample file is available at `../terraform.tfvars.example`.

## Remote State

Configured in `backend.tf` using the `s3` backend and SberCloud OBS endpoint. Ensure the bucket exists and export credentials for the backend:

```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

## How To Apply

```
cd terraform/prod
cp ../terraform.tfvars.example ./terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Outputs

- `namespace_name`, `storage_class_name`
- `jenkins_url`, `jira_url`, `bitbucket_url`
- `postgres_endpoint`

## Notes

- Ingress expects a valid TLS setup. Ensure cert-manager and a `ClusterIssuer` named `letsencrypt-prod` exist (or adjust annotations).
- Update the example ingress hosts to match your DNS.
- Use `terraform destroy` here to tear down prod resources when needed.