resource "helm_release" "rancher" {
  name             = "rancher"
  repository       = "https://releases.rancher.com/server-charts/latest"
  chart            = "rancher"
  namespace        = "cattle-system"
  create_namespace = true
  version          = "2.15.3"

  set = [
    { name  = "hostname", value = var.rancher_hostname },
    { name  = "ingress.ingressClassName", value = "tailscale" },
    { name  = "tls", value = "external" }
  ]

  set_sensitive = [
    { name  = "bootstrapPassword", value = var.rancher_password }
  ]
}
