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
  name            = "kube-prometheus-stack"
  repository      = "oci://ghcr.io/prometheus-community/charts"
  chart           = "kube-prometheus-stack"
  namespace       = kubernetes_namespace_v1.monitoring.metadata[0].name
  upgrade_install = true
  version         = "93.3.0"

  # Expose to tailscale
  set = [
    # Enable Grafana Ingress and expose via Tailscale
    { name = "grafana.ingress.enabled", value = "true" },
    { name = "grafana.ingress.ingressClassName", value = "tailscale" },
    { name = "grafana.ingress.hosts[0]", value = var.grafana_hostname },
    { name = "grafana.ingress.tls[0].hosts[0]", value = var.grafana_hostname },
    # Disable components that Talos locks down on control-plane nodes
    { name  = "kubeEtcd.enabled", value = "false" },
    { name  = "kubeControllerManager.enabled", value = "false" },
    { name  = "kubeScheduler.enabled", value = "false" },
    { name  = "kubeProxy.enabled", value = "false" }
  ]

  set_sensitive = [
    { name  = "grafana.adminPassword", value = var.db_password }
  ]
}
