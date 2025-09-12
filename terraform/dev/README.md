# Development Environment

Provisions a development Kubernetes environment on SberCloud and deploys Jenkins, Jira, and Bitbucket.

## What It Creates

- Networking: VPC, subnet, security groups
- Kubernetes: CCE cluster + a small node pool
- Database: PostgreSQL instance + databases and users for apps
- Storage: StorageClass `dev-sc` and PVCs for apps
- Apps: Helm releases for Jenkins, Jira, Bitbucket in namespace `dev`
- Ingress: Hosts `dev-jenkins.company.local`, `dev-jira.company.local`, `dev-bitbucket.company.local`

## Inputs

Defined in `variables.tf`. Provide values via `terraform.tfvars`:

- `access_key`, `secret_key`: SberCloud credentials
- `dev_postgres_password`: password for all dev app DB users
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
cd terraform/dev
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

- Kubernetes and Helm providers are auto-configured from the created cluster.
- Update the example ingress hosts to match your DNS.
- Use `terraform destroy` here to tear down dev resources when finished.