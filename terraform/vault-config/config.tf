# 1. Enable a KV-V2 Secrets Engine at path "secret/"
resource "vault_mount" "kvv2" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine for cluster apps"
}

# 2. Enable Kubernetes Auth Method so K8s pods can log into Vault
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

# 3. Configure Kubernetes Auth to talk to your cluster's API
# (When Vault runs inside K8s, it automatically reads its own service account token & CA cert)
resource "vault_kubernetes_auth_backend_config" "k8s_config" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://cluster.local"
}

# 4. Create a Read-Only Policy for your applications
resource "vault_policy" "app_read_policy" {
  name = "app-read-policy"

  policy = <<-EOT
    path "secret/data/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# 5. Bind a Kubernetes ServiceAccount ("my-app") in namespace ("default") to that policy
resource "vault_kubernetes_auth_backend_role" "app_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "my-app-role"
  bound_service_account_names      = ["my-app"]
  bound_service_account_namespaces = ["default"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.app_read_policy.name]
}

