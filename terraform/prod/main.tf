resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
    labels = {
      environment = "prod"
    }
  }
}

resource "kubernetes_storage_class" "prod_sc" {
  metadata {
    name = "prod-sc"
  }

  storage_provisioner  = "everest-csi-provisioner"
  reclaim_policy       = "Retain"
  volume_binding_mode  = "Immediate"

  parameters = {
    "csi.storage.k8s.io/fstype"   = "ext4"
    "everest.io/disk-volume-type" = "SAS"
  }
}

resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name      = "jenkins-pvc"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.prod_sc.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "bitbucket_pvc" {
  metadata {
    name      = "bitbucket-pvc"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.prod_sc.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "jira_pvc" {
  metadata {
    name      = "jira-pvc"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
    storage_class_name = kubernetes_storage_class.prod_sc.metadata[0].name
  }
}

# -----------------------------
# RDS Databases for Prod (using existing prod_postgres)
# -----------------------------
resource "sbercloud_rds_pg_database" "jira_db" {
  instance_id = sbercloud_rds_instance.prod_postgres.id
  name        = "jira_prod"
}

resource "sbercloud_rds_pg_database" "bitbucket_db" {
  instance_id = sbercloud_rds_instance.prod_postgres.id
  name        = "bitbucket_prod"
}

resource "sbercloud_rds_pg_database" "jenkins_db" {
  instance_id = sbercloud_rds_instance.prod_postgres.id
  name        = "jenkins_prod"
}

# PostgreSQL Users
resource "sbercloud_rds_pg_account" "jira_user" {
  instance_id = sbercloud_rds_instance.prod_postgres.id
  name        = "jira_user"
  password    = var.jira_db_password
}

resource "sbercloud_rds_pg_account" "bitbucket_user" {
  instance_id = sbercloud_rds_instance.prod_postgres.id
  name        = "bitbucket_user"
  password    = var.bitbucket_db_password
}

resource "sbercloud_rds_pg_account" "jenkins_user" {
  instance_id = sbercloud_rds_instance.prod_postgres.id
  name        = "jenkins_user"
  password    = var.jenkins_db_password
}

# Helm releases
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "4.8.3"
  namespace  = kubernetes_namespace.prod.metadata[0].name

  values = [
    yamlencode({
      controller = {
        resources = {
          requests = { cpu = "1000m", memory = "2Gi" }
          limits   = { cpu = "2000m", memory = "4Gi" }
        }
        javaOpts = "-Xms2g -Xmx2g"
      }
      persistence = { existingClaim = kubernetes_persistent_volume_claim.jenkins_pvc.metadata[0].name }
      serviceAccount = { create = true }
      rbac           = { create = true }
      backup         = { enabled = true }
      database       = {
        type = "postgresql"
        url  = "jdbc:postgresql://${sbercloud_rds_instance.prod_postgres.private_ips[0]}:5432/jenkins_prod"
        credentials = { secretName = kubernetes_secret.jenkins_db.metadata[0].name }
      }
    })
  ]

  depends_on = [kubernetes_persistent_volume_claim.jenkins_pvc, kubernetes_secret.jenkins_db]
}

resource "helm_release" "bitbucket" {
  name       = "bitbucket"
  repository = "https://atlassian.github.io/data-center-helm-charts"
  chart      = "bitbucket"
  version    = "1.17.2"
  namespace  = kubernetes_namespace.prod.metadata[0].name

  values = [
    yamlencode({
      replicaCount = 2
      resources = {
        jvm = { minHeap = "1g", maxHeap = "2g" }
        container = {
          requests = { cpu = "2", memory = "4Gi" }
          limits   = { cpu = "4", memory = "8Gi" }
        }
      }
      volumes = {
        sharedHome = {
          persistentVolumeClaim = {
            create    = false
            claimName = kubernetes_persistent_volume_claim.bitbucket_pvc.metadata[0].name
          }
        }
      }
      database = {
        type = "postgresql"
        url  = "jdbc:postgresql://${sbercloud_rds_instance.prod_postgres.private_ips[0]}:5432/bitbucket_prod"
        credentials = { secretName = kubernetes_secret.bitbucket_db.metadata[0].name }
      }
    })
  ]

  depends_on = [kubernetes_persistent_volume_claim.bitbucket_pvc, kubernetes_secret.bitbucket_db]
}

resource "helm_release" "jira" {
  name       = "jira"
  repository = "https://atlassian.github.io/data-center-helm-charts"
  chart      = "jira"
  version    = "1.17.0"
  namespace  = kubernetes_namespace.prod.metadata[0].name

  values = [
    yamlencode({
      replicaCount = 2
      resources = {
        jvm = { minHeap = "1g", maxHeap = "2g" }
        container = {
          requests = { cpu = "2", memory = "4Gi" }
          limits   = { cpu = "4", memory = "8Gi" }
        }
      }
      volumes = {
        sharedHome = {
          persistentVolumeClaim = {
            create    = false
            claimName = kubernetes_persistent_volume_claim.jira_pvc.metadata[0].name
          }
        }
      }
      database = {
        type = "postgresql"
        url  = "jdbc:postgresql://${sbercloud_rds_instance.prod_postgres.private_ips[0]}:5432/jira_prod"
        credentials = { secretName = kubernetes_secret.jira_db.metadata[0].name }
      }
    })
  ]

  depends_on = [kubernetes_persistent_volume_claim.jira_pvc, kubernetes_secret.jira_db]
}

# Database secrets
resource "kubernetes_secret" "jira_db" {
  metadata {
    name      = "jira-db-secret"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }
  data = {
    username = sbercloud_rds_pg_account.jira_user.name
    password = var.jira_db_password
  }
  type = "Opaque"
}

resource "kubernetes_secret" "bitbucket_db" {
  metadata {
    name      = "bitbucket-db-secret"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }
  data = {
    username = sbercloud_rds_pg_account.bitbucket_user.name
    password = var.bitbucket_db_password
  }
  type = "Opaque"
}

resource "kubernetes_secret" "jenkins_db" {
  metadata {
    name      = "jenkins-db-secret"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }
  data = {
    username = sbercloud_rds_pg_account.jenkins_user.name
    password = var.jenkins_db_password
  }
  type = "Opaque"
}

# Production ingress
resource "kubernetes_ingress_v1" "prod_ingress" {
  metadata {
    name      = "prod-ingress"
    namespace = kubernetes_namespace.prod.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"        = "nginx"
      "cert-manager.io/cluster-issuer"     = "letsencrypt-prod"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    tls {
      hosts       = ["jenkins.company.com", "jira.company.com", "bitbucket.company.com"]
      secret_name = "prod-tls-secret"
    }

    rule {
      host = "jenkins.company.com"
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
      host = "jira.company.com"
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
      host = "bitbucket.company.com"
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

