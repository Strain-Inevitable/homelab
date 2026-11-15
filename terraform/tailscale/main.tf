terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  namespace  = kubernetes_namespace_v1.tailscale.metadata[0].name

  set {
    name  = "operatorConfig.defaultTags"
    value = var.tailscale_tag
  }
  set_sensitive {
    name  = "oauth.clientId"
    value = var.tailscale_cid
  }
  set_sensitive {
    name  = "oauth.clientSecret"
    value = var.tailscale_secret
  }
}
