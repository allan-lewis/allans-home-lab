# justfile

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set dotenv-load := true

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

#############################
#### GENERAL/CROSS-OS #######
#############################

# Prepare a Linux cloud-init seed ISO for a host (based on inventory)
all-cloud-init-prepare host:
  {{run_prefix}} scripts/ansible-playbook.sh "ansible/prepare-cloud-init.yaml" "localhost" "" "" "target_host={{host}}"

# Write cloud-init ISOs to removable USB drives
all-cloud-init-isos os_iso ci_iso:
  {{run_prefix}} scripts/cloud-init-isos.sh "{{os_iso}}" "{{ci_iso}}"

# Remove all non-versioned build artifacts and temporary files
all-clean:
  {{run_prefix}} shared/scripts/clean.sh

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
#### ARCH ###################
#############################

# Put a custom, bootable Arch ISO onto Proxmox
arch-iso update_stable="yes":
  {{run_prefix}} linux/scripts/iso-arch.sh "{{update_stable}}"

# Prepare a Proxmox VM template suitable for Arch installations
arch-vm-template update_stable="yes":
  {{run_prefix}} linux/scripts/vm-template-arch.sh "{{update_stable}}"

#############################
#### HAOS ###################
#############################

# Export a HAOS Proxmox VM's boot disk to an S3 bucket
haos-boot-disk-capture vmid update_stable="yes":
  {{run_prefix}} appliance/scripts/boot-disk-capture.sh "haos" "gitops-homelab-orchestrator-disks" "proxmox-images" "{{vmid}}" "{{update_stable}}"

# Prepare a Proxmox VM template for cloning HAOS VMs
haos-vm-template update_stable="yes":
  {{run_prefix}} appliance/scripts/vm-template.sh haos {{update_stable}}

#############################
#### LINUX ##################
#############################

# Fully converge a group of Ubuntu hosts
linux-converge tags="" limit="": inventory-build
  {{run_prefix}} linux/scripts/ansible-playbook.sh "playbooks/converge-linux.yaml" "{{tags}}" "{{limit}}"

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
  {{run_prefix}} nixos/scripts/vm-template.sh {{update_stable}}

#############################
#### TRUENAS ################
#############################

# Export a TrueNAS Proxmox VM's boot disk to an S3 bucket
truenas-boot-disk-capture vmid update_stable="yes":
  {{run_prefix}} appliance/scripts/boot-disk-capture.sh "truenas" "gitops-homelab-orchestrator-disks" "proxmox-images" "{{vmid}}" "{{update_stable}}"

# Attach physical disks to a TrueNAS host
truenas-attach-disks vmid: inventory-build
  {{run_prefix}} appliance/scripts/attach-disks.sh "{{vmid}}" "truenas" "nas"

# Prepare a Proxmox VM template for cloning TrueNAS VMs
truenas-vm-template update_stable="yes":
  {{run_prefix}} appliance/scripts/vm-template.sh truenas {{update_stable}}

#############################
#### UBUNTU #################
#############################

# Prepare a Proxmox VM template suitable for Ubuntu installations
ubuntu-vm-template update_stable="yes":
  {{run_prefix}} linux/scripts/vm-template-ubuntu.sh {{update_stable}}

#############################
#### NIXOS/GITOPS ###########
#### EXPERIMENTAL! ##########
#############################

NIXOS_GITOPS_DIR := "./infra/os/nixos-gitops"

inventory-build:
	uv run --with jsonschema python3 shared/scripts/render-inventory.py

nix-check host: inventory-build
    ./nixos/scripts/converge.sh {{host}} check

nix-test host: inventory-build
    {{run_prefix}} ./nixos/scripts/converge.sh {{host}} test

nix-switch host: inventory-build
    {{run_prefix}} ./nixos/scripts/converge.sh {{host}} switch

#Apply or destroy a Proxmox VM using Terraform
terraform host action approve="0": inventory-build
  {{run_prefix}} shared/terraform/provision.sh \
    "{{host}}" \
    "{{action}}" \
    "{{approve}}"

