output "namespace_name" {
  description = "Kubernetes namespace for prod environment"
  value       = kubernetes_namespace.prod.metadata[0].name
}

output "jenkins_pvc_name" {
  description = "PVC name for Jenkins"
  value       = kubernetes_persistent_volume_claim.jenkins_pvc.metadata[0].name
}

output "bitbucket_pvc_name" {
  description = "PVC name for Bitbucket"
  value       = kubernetes_persistent_volume_claim.bitbucket_pvc.metadata[0].name
}

output "jira_pvc_name" {
  description = "PVC name for Jira"
  value       = kubernetes_persistent_volume_claim.jira_pvc.metadata[0].name
}

output "jenkins_url" {
  description = "URL for Jenkins access"
  value       = "https://jenkins.company.com"
}

output "bitbucket_url" {
  description = "URL for Bitbucket access"
  value       = "https://bitbucket.company.com"
}

output "jira_url" {
  description = "URL for Jira access"
  value       = "https://jira.company.com"
}

output "postgres_endpoint" {
  description = "PostgreSQL instance endpoint"
  value       = sbercloud_rds_instance.prod_postgres.private_ips[0]
  sensitive   = true
}

output "cluster_id" {
  description = "CCE cluster ID"
  value       = sbercloud_cce_cluster.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = sbercloud_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = sbercloud_vpc_subnet.main.id
}

output "storage_class_name" {
  description = "Storage class name for prod environment"
  value       = kubernetes_storage_class.prod_sc.metadata[0].name
}

