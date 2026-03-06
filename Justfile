# justfile

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set dotenv-load := true

export ANSIBLE_CONFIG := "{{ justfile_directory() }}/ansible.cfg"

ci := env_var_or_default("CI", "false")
force_doppler := env_var_or_default("FORCE_DOPPLER", "0")
doppler := env_var_or_default("DOPPLER", "1")

run_prefix := if doppler == "0" {
  ""
} else if ci == "true" {
  if force_doppler == "1" {
    "doppler run --"
  } else {
    ""
  }
} else {
  "doppler run --"
}

tf_base_dir := env_var_or_default("TF_BASE_DIR", "terraform/l2")

#############################
#### GENERAL/CROSS-OS #######
#############################

# Prepare a Linux cloud-init seed ISO for a host (based on inventory)
all-cloud-init-prepare host:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/cloud-init-prepare.yaml" "localhost" "" "" "target_host={{host}}"

# Write cloud-init ISOs to removable USB drives
all-cloud-init-isos os_iso ci_iso:
  {{run_prefix}} scripts/cloud-init-isos.sh "{{os_iso}}" "{{ci_iso}}"

# Remove all non-versioned build artifacts and temporary files
all-clean:
  {{run_prefix}} scripts/clean.sh

# Runway checks (OS/persona independent)
all-proxmox-runway:
  {{run_prefix}} scripts/proxmox-runway.sh

# Reboot a group of hosts (default: dryrun)
all-reboot group action="dryrun":
  {{run_prefix}} scripts/reboot.sh "{{group}}" "{{action}}"

# Shut down a group of hosts
all-shutdown group:
  {{run_prefix}} scripts/shutdown.sh "{{group}}"

#############################
#### PROXMOX APPLICANCES ####
#############################

#############################
#### ARCH ###################
#############################

# Put a custom, bootable Arch ISO onto Proxmox
arch-iso update_stable="yes":
  {{run_prefix}} scripts/arch-iso.sh "{{update_stable}}"

# Prepare a Proxmox VM template suitable for Arch installations
arch-vm-template update_stable="yes":
  {{run_prefix}} scripts/arch-vm-template.sh packer/arch "{{update_stable}}"

# Apply or destroy Arch Proxmox VMs using Terraform
arch-terraform persona action approve="0":
  {{run_prefix}} scripts/terraform.sh "arch" "{{persona}}" "{{action}}" "{{approve}}"

# Fully converge a group of Arch hosts
arch-converge group tags="" limit="":
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/linux/converge.yaml" "{{group}}" "{{tags}}" "{{limit}}"

#############################
#### HAOS ###################
#############################

# Export a HAOS Proxmox VM's boot disk to an S3 bucket
l1-haos-capture vmid:
  S3_BUCKET=gitops-homelab-orchestrator-disks \
  S3_PREFIX=proxmox-images \
  {{run_prefix}} scripts/l1/appliance-capture.sh haos "{{vmid}}"

# Download backups from S3 and upload to an HAOS host 
l3-homeassistant-backups:
  {{run_prefix}} scripts/l3/haos.sh

# Apply or detroy HAOS Proxmox VM(s) using Terraform
haos-terraform action approve="0":
  {{run_prefix}} scripts/terraform.sh "haos" "homeassistant" "{{action}}" "{{approve}}"

# Prepare a Proxmox VM template for cloning HAOS VMs
haos-vm-template update_stable="yes":
  {{run_prefix}} scripts/appliance-vm-template.sh haos {{update_stable}}

#############################
#### NIXOS ##################
#############################

# Prepare a custom bootable ISO for installing NixOS on a bare metal VM
nixos-iso hostname disk iface ip:
  {{run_prefix}} scripts/nixos-iso.sh \
    --out artifacts/nix-iso/{{hostname}} \
    --hostname {{hostname}} \
    --disk {{disk}} \
    --iface {{iface}} \
    --ip {{ip}}

# Prepare a Proxmox VM template for cloning NixOS VMs
nixos-vm-template update_stable="yes":
  {{run_prefix}} scripts/nixos-vm-template.sh {{update_stable}}

# Apply or detroy NixOS Proxmox VM(s) using Terraform
nixos-terraform persona action approve="0":
  {{run_prefix}} scripts/terraform.sh "nixos" "{{persona}}" "{{action}}" "{{approve}}"

# Fully converge a group of NixOS hosts
nixos-converge group tags="" limit="":
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "{{group}}" "{{tags}}" "{{limit}}"

# Converge only the Docker Homepage application
nixos-converge-homepage:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "carrie" "docker" "" "nixos_docker_services=homepage"

# Converge only the Docker Immich application
nixos-converge-immich:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "misery" "docker" "" "nixos_docker_services=immich"

# Converge only the Docker Jellyfin application
nixos-converge-jellyfin:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "misery" "docker" "" "nixos_docker_services=jellyfin"

# Converge only the Docker Plex application
nixos-converge-plex:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "misery" "docker" "" "nixos_docker_services=plex"

# Converge only the Docker Trilium application
nixos-converge-trilium:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "carrie" "docker" "" "nixos_docker_services=trilium"

# Converge only the Docker Vaultwarden application
nixos-converge-vaultwarden:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/nixos/converge.yaml" "carrie" "docker" "" "nixos_docker_services=vaultwarden"

#############################
#### TRUENAS ################
#############################

# Export a TrueNAS Proxmox VM's boot disk to an S3 bucket
l1-truenas-capture vmid:
  S3_BUCKET=gitops-homelab-orchestrator-disks \
  S3_PREFIX=proxmox-images \
  {{run_prefix}} scripts/l1/appliance-capture.sh truenas "{{vmid}}"

# Attach disks to a TrueNAS host
l3-truenas vmid:
  {{run_prefix}} scripts/l3/proxmox-disks.sh \
    "$PVE_SSH_IP" \
    "{{vmid}}" \
    "infra/os/truenas/personas/nas/spec/terraform.json"

# Apply or detroy TrueNAS Proxmox VM(s) using Terraform
truenas-terraform action approve="0":
  {{run_prefix}} scripts/terraform.sh "truenas" "nas" "{{action}}" "{{approve}}"

# Prepare a Proxmox VM template for cloning TrueNAS VMs
truenas-vm-template update_stable="yes":
  {{run_prefix}} scripts/appliance-vm-template.sh truenas {{update_stable}}

#############################
#### UBUNTU #################
#############################

# Prepare a Proxmox VM template suitable for Ubuntu installations
ubuntu-vm-template update_stable="yes":
  {{run_prefix}} scripts/ubuntu-vm-template.sh {{update_stable}}

# Apply or destroy Ubuntu Proxmox VM(s) using Terraform
ubuntu-terraform persona action approve="0":
  {{run_prefix}} scripts/terraform.sh "ubuntu" "{{persona}}" "{{action}}" "{{approve}}"

# Fully converge a group of Ubuntu hosts
ubuntu-converge group tags="" limit="":
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/linux/converge.yaml" "{{group}}" "{{tags}}" "{{limit}}"
