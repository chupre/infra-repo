variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "prod_postgres_password" {
  type        = string
  sensitive   = true
  description = "Password for PostgreSQL users in prod environment"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block for subnet"
}

variable "availability_zone" {
  type        = string
  default     = "ru-moscow-1a"
  description = "Availability zone for resources"
}

