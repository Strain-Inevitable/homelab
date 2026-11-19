# Strain-Inevitable's Talos OS Kubernetes Home Lab
## Pre-requisites
- [Talos OS](www.siderolabs.com/talos-linux)
- [Proxmox](www.proxmox.com/en) (or another hypervisor of your choice)
## Setup
### Installing Talos OS
> [!IMPORTANT]
> These instructions may be different if you used a different hypervisor.

<details>
<summary>Prepping the ISO</summary>

- Go to Talos's [image factory](factory.talos.dev/)
- Choose `Cloud Server`
- Choose `1.14.6`
- Choose `Nocloud`
- Choose `amd64` and enable Secure Boot
- Choose *only* `siderolabs/qemu-guest-agent (11.1.1)`
- Leave both boxes blank and choose `UEFI only`
- Copy the link *(do not download)* from under `SecureBoot ISO` and open Proxmox.
- Go to your Proxmox node's physical storage volume and select `ISO Images`
- Click on `Download from URL`
- Paste the link into the top box and click `Query URL`
- Click on `Download`
</details>
<details>
<summary>Setting up the VMs</summary>

- Click `Create VM`
    <details>
    <summary>General Tab</summary>

    - Set a VMID and a Name for your VM that indicates it is a control plane
    - Optionally, set a tag or multiple tags
    - Click `Next`
    </details>
    <details>
    <summary>OS Tab</summary>

    - For the `ISO Image:` field, choose the name of the ISO you just downloaded
    - Click `Next`
    </details>
    <details>
    <summary>System Tab</summary>

    - For `Machine:` choose `q35`
    - For `BIOS:` choose `OVFM (UEFI)`
    - Ensure that `Add EFI Disk:` is selected
    - For `EFI Storage:` select the same volume your VM is on
    - Ensure that `Pre-enroll Keys:` is *not* selected
    - For `SCSI Controller:` choose `VirtIO SCSI` *(there is currently a bug that causes failure on `VirtIO SCSI single`)*
    - Ensure that `QEMU Agent:` is selected
    - Ensure that `Add TPM:` is selected
    - Select a secure storage for the TPM
    - Ensure that `Version:` is set to 2.0
    - Click `Next`
    </details>
    <details>
    <summary>Disks Tab</summary>

    - For `Disk size (GiB):` set the field to 100
    - Ensure that `SSID emulation:` is selected if you are using SSID
    - For `Cache:` choose `Write through` or `No cache`
    - Ensure that `Discard:` is selected
    - Click `Next`
    </details>
    <details>
    <summary>CPU Tab</summary>

    - For `Cores:` set the field to 2
    - For `Type:` choose `host`
    - Click `Next`
    </details>
    <details>
    <summary>Memory Tab</summary>

    - For `Memory (MiB):`
        - Recommended: 4096
        - Required: 2048
    - Ensure that `Ballooning Device:` is *not* selected
    - Click `Next`
    </details>
    <details>
    <summary>Network Tab</summary>

    - For `Bridge:` choose the bridge you intend to host the machines on
    - For `Model:` choose `VirtIO`
    - Click `Next`
    </details>
    <details>
    <summary>Confirm Tab</summary>

    - Go over all of the values above to ensure they are correct
    - Ensure that `Start after created` is selected
    - Click `Finish`
    - Write down the IP in the top right corner
    </details>
    <details>
    <summary>Worker Node 1</summary>

    - Repeat the above process with these changes:
        - Set an appropriate VMID and Name for your first worker node.
        - For `Cores:` set the field to 4
        - For `Memory (MiB):`
            - Recommended: 16384
            - Required: 6144
    - Be sure to write down this IP too
    </details>
    <details>
    <summary>Worker Node 2</summary>

    - Right click on Worker Node 1
    - Select `Clone`
    - Set an appropriate VMID and Name for your second worker node.
    - Write down this IP
    </details>
</details>

### Setting up Kubernetes
<details>
<summary>Installing Controls</summary>

#### talosctl
```shell
curl -sL "https://talos.dev/install" | sh
talosctl version
```
#### kubectl
```shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version
```
#### HashiCorp Terraform
<details>
<summary>Debian/Ubuntu</summary>

```shell
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```
</details>
<details>
<summary>CentOS/RHEL</summary>

```shell
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```
</details>
<details>
<summary>Fedora</summary>

```shell
wget -O- https://rpm.releases.hashicorp.com/fedora/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
sudo yum list available | grep hashicorp
sudo dnf -y install terraform
```
</details>
</details>

### Preparing the repo
<details>
<summary>Pre-Deployment Hygiene</summary>

```shell
cd
mkdir homelab && cd homelab
nano .gitignore
```
```nano
\# Terraform state and local plans (sensitive metadata)
.terraform/
*.tfstate
*.tfstate.*
*.lock.hcl
plan
tfplan

\# Secret variable files
*.tfvars
*.auto.tfvars
secret*.yaml

\#Environments
.env
*.snapshot

\# Talos OS config
talos/controlplane.yaml
talos/worker.yaml
talos/talosconfig
```
</details>
<details>
<summary>Staging the files</summary>

```shell
cd ~/homelab
git init -b main
git add */*
git commit -m "Initial commit"
gh repo create --source=. --public --push
```
</details>

### Initializing Kubernetes
<details>
<summary>Creating the configs</summary>

```shell
mkdir -p talos
talosctl gen config <cluster-name> https://<control-plane-ip>:6443 -o talos/
nano talos/tpmEncryption.yaml
```
```nano
apiVersion: v1alpha1
     kind: VolumeConfig
     name: STATE
     encryption:
       provider: luks2
       keys:
         - slot: 0
           tpm: {}
     ---
     apiVersion: v1alpha1
     kind: VolumeConfig
     name: EPHEMERAL
     encryption:
       provider: luks2
       keys:
         - slot: 0
           tpm: {}
           lockToState: true
```
```shell
talosctl machineconfig patch talos/controlplane.yaml \
> --patch @talos/tpmEncryption.yaml -o talos/controlplane.yaml
talosctl machineconfig patch talos/worker.yaml \
> --patch @talos/tpmEncryption.yaml -o talos/worker.yaml
chmod 600 talos/*
```
</details>
<details>
<summary>Patching and booting</summary>

```shell
talosctl apply-config --insecure -n <control-plane-ip> -f talos/controlplane.yaml
talosctl apply-config --insecure -n <worker1-ip> -f talos/worker.yaml
talosctl apply-config --insecure -n <worker2-ip> -f talow/worker.yaml

talosctl bootstrap -n <control-plane-ip>
talosctl kubeconfig -n <control-plane-ip>
```
</details>
<details>
<summary>Verifying secure boot</summary>

For every node:
```shell
talosctl get securitystate -n <node-ip>
talosctl get volumestatus STATE -n <node-ip> -o yaml
talosctl get volumestatus EPHEMERAL -n <node-ip> -o yaml
```


> [!IMPORTANT]
> On every node:
> 	SECUREBOOT: true
> 	encryptionProvider: luks2
> 	pcrs: [7]
> 	pubKeyPcrs: [11]

</details>

> [!NOTE]
> **TODO:** Continue setup from here

## Security
### The First C: Cloud
<details>
<summary>Tailscale</summary>

In the Tailscale Admin Console -> DNS, enable:
- MagicDNS
- HTTPS Certificates
In your terminal:
```shell
mkdir -p infrastructure && cd infrastructure
mkdir -p tailscale && cd tailscale
nano tailscale.tf
```
```nano
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
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = "<your-tailscale-email>"
  }
}
```
```shell
terraform plan -out plan
```
If the plan shows correct:
```shell
terraform apply plan
tailscale configure kubeconfig tailscale-operator
```
</details>
<details>
<summary>Network Perimeter Hardening</summary>

1 - Reserve static DHCP leases on your router for your desktop workstation, Proxmox host, and Talos nodes (the same ones you currently have - just make them permanent)  
2 - Go to your Proxmox Datacenter -> Firewall -> IPSet  
	- Create a new IPSet and name it something like 'trusted_k8s' or something that makes sense to you.  
	- Add each of your node IPs  
	- Add your desktop workstation IP  
	- Add the Tailscale CGNAT Subnet (100.64.0.0/10)  

> [!IMPORTANT]
> Do this step BEFORE turning your firewall on!

3 - Go to your Proxmox Datacenter -> Firewall  
	- Add Rule: Direction: in | Action: ACCEPT | Source: +trusted_k8s | Protocol: tcp | Dest. port: 8006,22  
	  *Note*: The + in front of your IPSet's name is very important  
4 - Go to your Proxmox Datacenter -> Firewall  
	- Options: Firewall: Yes | Input Policy: DROP | Output Policy: ACCEPT  
5 - Go to your Proxmox Datacenter -> Firewall -> Security Group  
	- Create a new security group and name it something like 'k8s_nodes' or something that makes sense to you.  
	- Rule 0: Direction: in | Action: ACCEPT | Protocol: udp | Dest. port: 67:68 | Comment: Allow DHCP  
	- Rule 1: Direction: in | Action: ACCEPT | Source: +dc/trusted_k8s  
6 - Go to each of your Talos VMs -> Firewall  
	- Insert: Security Group -> k8s_nodes and ensure that it is enabled.  
	- Options: Firewall: Yes | DHCP: Yes | NDP: Yes | MAC filter: Yes | Input Policy: DROP | Output Policy: ACCEPT  
7 - Verify Perimeter Enforcement  
	- From somewhere *not* on your LAN with Tailscale OFF: kubectl should time out  
	- From somewhere *not* on your LAN with Tailscale ON: kubectl should work  
	- From untrusted host on your LAN: ping your control plane and you should get 100% packet loss  
</details>
<details>
<summary>Secrets!</summary> 

> [!NOTE]
> **TODO:** Elaborate on deploying Vault

- Deploy Vault using terraform under homelab/apps/vault and Vault's config under homelab/infrastructure/vault-config
```shell
kubectl exec -it -n vault vault-0 -- vault operator init
```
You will get 5 unseal keys followed by an initial root token. You need to save all of these (for now).
```shell
kubectl exec -it -n vault vault-0 -- vault operator unseal <any-of-the-five-keys>
kubectl exec -it -n vault vault-0 -- vault operator unseal <another-of-the-keys>
kubectl exec -it -n vault vault-0 -- vault operator unseal <a-third-of-the-keys>
kubectl port-forward -n vault pod/vault-0 8200:8200 &
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="<initial-root-token>"
terraform -chdir=../../infrastructure/vault-config apply
kubectl exec -it -n vault vault-0 -- \
> env VAULT_TOKEN="<initial-root-token>" vault token revoke -self
```


> [!IMPORTANT]
> It is normally not a good idea to get used to having your tokens show up in your local history or be sent this way, however in this case you are destroying the token, and it will never be used against you.

</details>

> [!NOTE]
> **TODO:** Complete the security section

### The Second C: Cluster

### The Third C: Container

### The Fourth C: Code

> [!NOTE]
> **TODO:** Update the tree

```console
homelab/
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
```
