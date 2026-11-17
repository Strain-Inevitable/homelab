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
    </details>
    <details>
    <summary>Worker Node 1</summary>

    - Repeat the above process with these changes:
        - Set an appropriate VMID and Name for your first worker node.
        - For `Cores:` set the field to 4
        - For `Memory (MiB):`
            - Recommended: 16384
            - Required: 6144
    </details>
    <details>
    <summary>Worker Node 2</summary>

    - Right click on Worker Node 1
    - Select `Clone`
    - Set an appropriate VMID and Name for your second worker node.
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
### HashiCorp Terraform
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
