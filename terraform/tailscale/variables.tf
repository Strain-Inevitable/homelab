variable tailscale_tag {
  type      = string
  sensitive = false
}

variable tailscale_cid {
  type      = string
  sensitive = true
}

variable tailscale_secret {
  type      = string
  sensitive = true
}
