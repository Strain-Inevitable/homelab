resource "kubernetes_namespace_v1" "vault" {
  metadata {
    name = "vault"
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.34.1"
  namespace  = kubernetes_namespace_v1.vault.metadata[0].name

  values = [
    yamlencode({
      global = {
        enabled    = true
        tlsDisable = true
      }

      injector = {
        enabled = true
      }

      server = {
        dataStorage = {
          enabled = true
          size    = "5Gi"
          storageClass = "local-path"
        }

        standalone = {
          enabled = false
        }

        ha = {
          enabled  = true
          replicas = 1

          raft = {
            enabled   = true
            setNodeId = true

            config = <<-EOT
              ui = true

              listener "tcp" {
                tls_disable     = 1
                address         = "[::]:8200"
                cluster_address = "[::]:8201"
              }

              storage "raft" {
                path = "/vault/data"
              }

              service_registration "kubernetes" {}
            EOT
          }
        }
      }
    })
  ]
}
