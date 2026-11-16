resource "helm_release" "local_path_provisioner" {
  name             = "local-path-provisioner"
  repository       = "https://charts.containeroo.ch"
  chart            = "local-path-provisioner"
  namespace        = "local-path-storage"
  create_namespace = true

  values = [
    yamlencode({
      storageClass = {
        defaultClass = true
      }
      nodePathMap = [
        { node  = "DEFAULT_PATH_FOR_NON_LISTED_NODES", paths = ["/var/local-path-provisioner"] }
      ]
    })
  ]
}
