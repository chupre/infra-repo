variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "dev_postgres_password" {
  type        = string
  sensitive   = true
  description = "Master password for PostgreSQL instance in dev environment"
}

variable "jira_db_password" {
  type        = string
  sensitive   = true
  description = "Password for Jira PostgreSQL user"
  default     = ""
}

variable "bitbucket_db_password" {
  type        = string
  sensitive   = true
  description = "Password for Bitbucket PostgreSQL user"
  default     = ""
}

variable "jenkins_db_password" {
  type        = string
  sensitive   = true
  description = "Password for Jenkins PostgreSQL user"
  default     = ""
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

variable "admin_ip_ranges" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "IP ranges allowed for SSH and K8s API access"
}

