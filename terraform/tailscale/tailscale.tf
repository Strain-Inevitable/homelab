resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "kubernetes_cluster_role_binding_v1" "tailscale_admin" {
  metadata {
    name = "tailscale-operator-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "User"
    name      = "Strain-Inevitable@github"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = "1.104.7"
  namespace  = kubernetes_namespace_v1.tailscale.metadata[0].name

  set = [
    {
      name  = "apiServerProxyConfig.mode"
      value = "true"
    }
  ]
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
