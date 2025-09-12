# -----------------------------
# Kubernetes Namespace
# -----------------------------
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
    labels = { environment = "dev" }
  }
}

# -----------------------------
# StorageClass
# -----------------------------
resource "kubernetes_storage_class" "dev_sc" {
  metadata {
    name = "dev-sc"
  }

  storage_provisioner  = "everest-csi-provisioner"
  reclaim_policy       = "Delete"
  volume_binding_mode  = "Immediate"

  parameters = {
    "csi.storage.k8s.io/fstype"   = "ext4"
    "everest.io/disk-volume-type" = "SAS"
  }
}

# -----------------------------
# PersistentVolumeClaims
# -----------------------------
resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name      = "jenkins-pvc"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources { requests = { storage = "10Gi" } }
    storage_class_name = kubernetes_storage_class.dev_sc.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "bitbucket_pvc" {
  metadata {
    name      = "bitbucket-pvc"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources { requests = { storage = "10Gi" } }
    storage_class_name = kubernetes_storage_class.dev_sc.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "jira_pvc" {
  metadata {
    name      = "jira-pvc"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources { requests = { storage = "10Gi" } }
    storage_class_name = kubernetes_storage_class.dev_sc.metadata[0].name
  }
}

# -----------------------------
# RDS Databases for Dev (using existing dev_postgres)
# -----------------------------
resource "sbercloud_rds_pg_database" "jira_db" {
  instance_id = sbercloud_rds_instance.dev_postgres.id
  name        = "jira_dev"
}

resource "sbercloud_rds_pg_database" "bitbucket_db" {
  instance_id = sbercloud_rds_instance.dev_postgres.id
  name        = "bitbucket_dev"
}

resource "sbercloud_rds_pg_database" "jenkins_db" {
  instance_id = sbercloud_rds_instance.dev_postgres.id
  name        = "jenkins_dev"
}

# PostgreSQL Users
resource "sbercloud_rds_pg_account" "jira_user" {
  instance_id = sbercloud_rds_instance.dev_postgres.id
  name        = "jira_user"
  password    = var.dev_postgres_password
}

resource "sbercloud_rds_pg_account" "bitbucket_user" {
  instance_id = sbercloud_rds_instance.dev_postgres.id
  name        = "bitbucket_user"
  password    = var.dev_postgres_password
}

resource "sbercloud_rds_pg_account" "jenkins_user" {
  instance_id = sbercloud_rds_instance.dev_postgres.id
  name        = "jenkins_user"
  password    = var.dev_postgres_password
}

# -----------------------------
# Kubernetes Secrets for DB credentials
# -----------------------------
resource "kubernetes_secret" "jira_db" {
  metadata {
    name      = "jira-db-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  data = {
    username = sbercloud_rds_pg_account.jira_user.name
    password = var.dev_postgres_password
  }
  type = "Opaque"
}

resource "kubernetes_secret" "bitbucket_db" {
  metadata {
    name      = "bitbucket-db-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  data = {
    username = sbercloud_rds_pg_account.bitbucket_user.name
    password = var.dev_postgres_password
  }
  type = "Opaque"
}

resource "kubernetes_secret" "jenkins_db" {
  metadata {
    name      = "jenkins-db-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  data = {
    username = sbercloud_rds_pg_account.jenkins_user.name
    password = var.dev_postgres_password
  }
  type = "Opaque"
}

# -----------------------------
# Helm Releases
# -----------------------------
# -----------------------------
# Jenkins Helm release
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.dev.metadata[0].name

  values = [
    yamlencode({
      persistence = {
        existingClaim = kubernetes_persistent_volume_claim.jenkins_pvc.metadata[0].name
      }
      serviceAccount = { create = true }
      rbac           = { create = true }
      database = {
        type  = "postgresql"
        url   = "jdbc:postgresql://${sbercloud_rds_instance.dev_postgres.private_ips[0]}:5432/jenkins_dev"
        credentials = { secretName = kubernetes_secret.jenkins_db.metadata[0].name }
      }
    })
  ]

  depends_on = [kubernetes_persistent_volume_claim.jenkins_pvc, kubernetes_secret.jenkins_db]
}

# Jira Helm release
resource "helm_release" "jira" {
  name       = "jira"
  repository = "https://atlassian.github.io/data-center-helm-charts"
  chart      = "jira"
  namespace  = kubernetes_namespace.dev.metadata[0].name

  values = [
    yamlencode({
      volumes = {
        sharedHome = {
          persistentVolumeClaim = {
            create    = false
            claimName = kubernetes_persistent_volume_claim.jira_pvc.metadata[0].name
          }
        }
      }
      database = {
        type  = "postgresql"
        url   = "jdbc:postgresql://${sbercloud_rds_instance.dev_postgres.private_ips[0]}:5432/jira_dev"
        credentials = { secretName = kubernetes_secret.jira_db.metadata[0].name }
      }
    })
  ]

  depends_on = [kubernetes_persistent_volume_claim.jira_pvc, kubernetes_secret.jira_db]
}

# Bitbucket Helm release
resource "helm_release" "bitbucket" {
  name       = "bitbucket"
  repository = "https://atlassian.github.io/data-center-helm-charts"
  chart      = "bitbucket"
  namespace  = kubernetes_namespace.dev.metadata[0].name

  values = [
    yamlencode({
      volumes = {
        sharedHome = {
          persistentVolumeClaim = {
            create    = false
            claimName = kubernetes_persistent_volume_claim.bitbucket_pvc.metadata[0].name
          }
        }
      }
      database = {
        type  = "postgresql"
        url   = "jdbc:postgresql://${sbercloud_rds_instance.dev_postgres.private_ips[0]}:5432/bitbucket_dev"
        credentials = { secretName = kubernetes_secret.bitbucket_db.metadata[0].name }
      }
    })
  ]

  depends_on = [kubernetes_persistent_volume_claim.bitbucket_pvc, kubernetes_secret.bitbucket_db]
}

# Ingress
# -----------------------------
resource "kubernetes_ingress_v1" "dev_ingress" {
  metadata {
    name      = "dev-ingress"
    namespace = kubernetes_namespace.dev.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    rule {
      host = "dev-jenkins.company.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "jenkins"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    rule {
      host = "dev-jira.company.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "jira"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }

    rule {
      host = "dev-bitbucket.company.local"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "bitbucket"
              port {
                number = 7990
              }
            }
          }
        }
      }
    }
  }
}
