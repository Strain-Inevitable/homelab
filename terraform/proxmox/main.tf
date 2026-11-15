terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "~> 0.122.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.prox_endpoint
  api_token = var.prox_api
  insecure = true
}

# Read-only query to verify connection to your Proxmox host
data "proxmox_virtual_environment_nodes" "available_nodes" {}

output "proxmox_nodes" {
  value = data.proxmox_virtual_environment_nodes.available_nodes.names
}
