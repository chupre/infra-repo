output "namespace_name" {
  description = "Kubernetes namespace for dev environment"
  value       = kubernetes_namespace.dev.metadata[0].name
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
  value       = "http://dev-jenkins.company.local"
}

output "bitbucket_url" {
  description = "URL for Bitbucket access"
  value       = "http://dev-bitbucket.company.local"
}

output "jira_url" {
  description = "URL for Jira access"
  value       = "http://dev-jira.company.local"
}

output "postgres_endpoint" {
  description = "PostgreSQL instance endpoint"
  value       = sbercloud_rds_instance.dev_postgres.private_ips[0]
}

output "storage_class_name" {
  description = "Storage class name for dev environment"
  value       = kubernetes_storage_class.dev_sc.metadata[0].name
}

