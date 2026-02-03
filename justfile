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

# Remove all non-versioned build artifacts and temporary files
clean:
  {{run_prefix}} scripts/clean.sh

# Runway checks (OS/persona independent)
l0-runway:
  {{run_prefix}} scripts/l0/runway.sh

# Prepare a cloud-init seed ISO for use on bare metal Arch installations
l1-arch-cloud-init host:
  {{run_prefix}} scripts/l1/cloud-init-seed.sh "{{host}}"

# Put a custom, bootable Arch ISO onto Proxmox
l1-arch-iso:
  {{run_prefix}} scripts/l1/arch-iso.sh

# Prepare a Proxmox VM template suitable for Arch installations
l1-arch-template:
  {{run_prefix}} scripts/l1/arch-template.sh packer/l1/arch

# Export a HAOS Proxmox VM's boot disk to an S3 bucket
l1-haos-capture vmid:
  S3_BUCKET=gitops-homelab-orchestrator-disks \
  S3_PREFIX=proxmox-images \
  {{run_prefix}} scripts/l1/appliance-capture.sh haos "{{vmid}}"

# Prepare a Proxmox VM template suitable for HAOS installations
l1-haos-template:
  {{run_prefix}} scripts/l1/appliance-template.sh haos

# Export a TrueNAS Proxmox VM's boot disk to an S3 bucket
l1-truenas-capture vmid:
  S3_BUCKET=gitops-homelab-orchestrator-disks \
  S3_PREFIX=proxmox-images \
  {{run_prefix}} scripts/l1/appliance-capture.sh truenas "{{vmid}}"

# Prepare a Proxmox VM template suitable for TrueNAS installations
l1-truenas-template:
  {{run_prefix}} scripts/l1/appliance-template.sh truenas

# Prepare a Proxmox VM template suitable for Ubuntu installations
l1-ubuntu-template:
  {{run_prefix}} scripts/l1/ubuntu-template.sh

