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

# Talos enforces Pod Security Admission; node-exporter needs privileged access
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "69.8.2"

  # Expose to tailscale
  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "grafana.service.loadBalancerClass"
    value = "tailscale"
  }
  set {
    name  = "grafana.service.annotations.tailscale\\.com/hostname"
    value = "grafana"
  }

  # Disable components that Talos locks down on control-plane nodes
  set {
    name  = "kubeEtcd.enabled"
    value = "false"
  }
  set {
    name  = "kubeControllerManager.enabled"
    value = "false"
  }
  set {
    name  = "kubeScheduler.enabled"
    value = "false"
  }
}
