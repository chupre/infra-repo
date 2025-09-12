terraform {
  required_providers {
    sbercloud = {
      source  = "sbercloud-terraform/sbercloud"
      version = "~> 1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "sbercloud" {
  auth_url   = "https://iam.ru-moscow-1.hc.sbercloud.ru/v3"
  region     = "ru-moscow-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "kubernetes" {
  host                   = sbercloud_cce_cluster.main.kube_config_raw != "" ? yamldecode(sbercloud_cce_cluster.main.kube_config_raw)["clusters"][0]["cluster"]["server"] : null
  cluster_ca_certificate = sbercloud_cce_cluster.main.kube_config_raw != "" ? base64decode(yamldecode(sbercloud_cce_cluster.main.kube_config_raw)["clusters"][0]["cluster"]["certificate-authority-data"]) : null
  token                  = sbercloud_cce_cluster.main.kube_config_raw != "" ? yamldecode(sbercloud_cce_cluster.main.kube_config_raw)["users"][0]["user"]["token"] : null
}

provider "helm" {
  kubernetes = {
    host                   = sbercloud_cce_cluster.main.kube_config_raw != "" ? yamldecode(sbercloud_cce_cluster.main.kube_config_raw)["clusters"][0]["cluster"]["server"] : null
    cluster_ca_certificate = sbercloud_cce_cluster.main.kube_config_raw != "" ? base64decode(yamldecode(sbercloud_cce_cluster.main.kube_config_raw)["clusters"][0]["cluster"]["certificate-authority-data"]) : null
    token                  = sbercloud_cce_cluster.main.kube_config_raw != "" ? yamldecode(sbercloud_cce_cluster.main.kube_config_raw)["users"][0]["user"]["token"] : null
  }
}

