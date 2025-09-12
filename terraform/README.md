# Terraform

This directory contains Terraform configurations for two environments.

- dev/: Development cluster and apps
- prod/: Production cluster and apps
- terraform.tfvars.example: Sample variables to copy into each env as `terraform.tfvars`

## Remote State

Both environments use the Terraform `s3` backend pointing to SberCloud OBS (`endpoint = https://obs.ru-moscow-1.hc.sbercloud.ru`). Ensure the bucket (default `terraformbucket`) exists and export:

```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

## Common Commands

- `terraform fmt -recursive`
- `terraform validate`
- `terraform plan`
- `terraform apply`
- `terraform destroy`

See each environment README for details.