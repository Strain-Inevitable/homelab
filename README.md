# homelab
.
├── apps
│   ├── cert-manager
│   │   ├── cert-manager.tf
│   │   ├── providers.tf -> ../../providers.tf
│   │   ├── terraform.tfstate
│   │   └── terraform.tfstate.backup
│   ├── local-path-storage
│   │   ├── local-path-storage.tf
│   │   ├── providers.tf -> ../../providers.tf
│   │   ├── terraform.tfstate
│   │   └── terraform.tfstate.backup
│   ├── monitoring
│   │   ├── grafana.tf
│   │   ├── providers.tf -> ../../providers.tf
│   │   ├── terraform.tfstate
│   │   ├── terraform.tfstate.backup
│   │   └── variables.tf
│   └── rancher
│       ├── providers.tf -> ../../providers.tf
│       ├── rancher.tf
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       └── variables.tf
├── providers.tf
├── README.md
├── scripts
│   └── restartEverything.sh
├── talos
│   ├── controlplane.yaml
│   ├── talosconfig
│   └── worker.yaml
└── terraform
    ├── k8s-inspect
    │   ├── providers.tf -> ../../providers.tf
    │   ├── terraform.tfstate
    │   └── terraform.tfstate.backup
    ├── proxmox
    │   ├── providers.tf -> ../../providers.tf
    │   ├── proxmox.tf
    │   ├── terraform.tfstate
    │   └── variables.tf
    ├── tailscale
    │   ├── providers.tf -> ../../providers.tf
    │   ├── tailscale.tf
    │   ├── terraform.tfstate
    │   ├── terraform.tfstate.backup
    │   └── variables.tf
    ├── vault
    │   ├── providers.tf -> ../../providers.tf
    │   ├── terraform.tfstate
    │   ├── terraform.tfstate.backup
    │   └── vault.tf
    └── vault-config
        ├── config.tf
        ├── providers.tf -> ../../providers.tf
        └── terraform.tfstate
