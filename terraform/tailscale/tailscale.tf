resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = "1.104.7"
  namespace  = kubernetes_namespace_v1.tailscale.metadata[0].name

  set_list = [
    {
      name  = "operatorConfig.defaultTags"
      value = [var.tailscale_tag]
    }
  ]
  set_sensitive = [
    {
      name  = "oauth.clientId"
      value = var.tailscale_cid
    },
    {
      name  = "oauth.clientSecret"
      value = var.tailscale_secret
    }
  ]
}
