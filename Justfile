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

# Write cloud-init ISOs to removable USB drives
l1-cloud-init-usbs os_iso ci_iso:
  {{run_prefix}} scripts/l1/write-arch-usbs.sh "{{os_iso}}" "{{ci_iso}}"

# Export a HAOS Proxmox VM's boot disk to an S3 bucket
l1-haos-capture vmid:
  S3_BUCKET=gitops-homelab-orchestrator-disks \
  S3_PREFIX=proxmox-images \
  {{run_prefix}} scripts/l1/appliance-capture.sh haos "{{vmid}}"

# Prepare a Proxmox VM template suitable for HAOS installations
l1-haos-template:
  {{run_prefix}} scripts/l1/appliance-template.sh haos

# Prepare a Proxmox VM template suitable for NixOS installations
l1-nixos-template:
  {{run_prefix}} scripts/l1/nixos-template.sh

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

# Apply Terraform resources for an OS/persona pair
l2-apply tfdir apply_flag="0":
  APPLY="{{apply_flag}}" \
  {{run_prefix}} scripts/l2/terraform.sh "{{tf_base_dir}}/{{tfdir}}" apply

# Destroy Terraform resources for an OS/persona pair
l2-destroy tfdir apply_flag="0":
  APPLY="{{apply_flag}}" \
  {{run_prefix}} scripts/l2/terraform.sh "{{tf_base_dir}}/{{tfdir}}" destroy

# Converge a group of hosts (capabilities)
l3-converge group tags="":
  TAGS="{{tags}}" \
  {{run_prefix}} scripts/converge.sh "{{group}}" l3

# Converge a group of NixOS hosts (capabilities)
l3-converge-nixos:
  {{run_prefix}} scripts/l3/converge-nixos.sh

# Download backups from S3 and upload to an HAOS host 
l3-homeassistant-backups:
  {{run_prefix}} scripts/l3/haos.sh

# Reboot a group of hosts (default: dryrun)
l3-reboot group action="dryrun":
  REBOOT_ACTION="{{action}}" \
  {{run_prefix}} scripts/l3/reboot.sh "{{group}}"

# Shut down a group of hosts
l3-shutdown group:
  {{run_prefix}} scripts/l3/shutdown.sh "{{group}}"

# Attach disks to a TrueNAS host
l3-truenas vmid:
  {{run_prefix}} scripts/l3/proxmox-disks.sh \
    "$PVE_SSH_IP" \
    "{{vmid}}" \
    "infra/os/truenas/personas/nas/spec/terraform.json"

# Converge a group of hosts (workloads)
l4-converge group tags="":
  TAGS="{{tags}}" \
  {{run_prefix}} scripts/converge.sh "{{group}}" l4

# Full converge of Gatus
l4-converge-gatus:
  TAGS=step_docker_gatus_all \
  {{run_prefix}} scripts/converge.sh flagg l4

# Quick converge of Gatus (just config)
l4-converge-gatus-config:
  TAGS=step_docker_gatus \
  {{run_prefix}} scripts/converge.sh flagg l4

# Full converge of Traefik
l4-converge-traefik:
  TAGS=step_docker_traefik \
  {{run_prefix}} scripts/converge.sh flagg l4

# Full converge of Pi-hole
l4-converge-pihole:
  TAGS=step_docker_pihole_all \
  {{run_prefix}} scripts/converge.sh flagg l4

# Quick converge of Pi-hole (just DNS records)
l4-converge-pihole-dns:
  TAGS=step_docker_pihole \
  {{run_prefix}} scripts/converge.sh flagg l4

# Full converge of Authentik
l4-converge-authentik:
  TAGS=step_docker_authentik \
  {{run_prefix}} scripts/converge.sh flagg l4

# Full converge of Immich
l4-converge-immich:
  TAGS=step_docker_immich \
  {{run_prefix}} scripts/converge.sh misery l4

# Full converge of Homepage
l4-converge-homepage:
  TAGS=step_docker_homepage_all \
  {{run_prefix}} scripts/converge.sh carrie l4

# Quick converge of Homepage (just config)
l4-converge-homepage-config:
  TAGS=step_docker_homepage \
  {{run_prefix}} scripts/converge.sh carrie l4

# Full converge of Vaultwarden
l4-converge-vaultwarden:
  TAGS=step_docker_vaultwarden \
  {{run_prefix}} scripts/converge.sh carrie l4

# Full converge of Twingate
l4-converge-twingate:
  TAGS=step_docker_twingate \
  {{run_prefix}} scripts/converge.sh ubuntu_docker_twingate l4

# Full converge of Prometheus/Grafana/Alertmanager
l4-converge-observability:
  TAGS=step_docker_observability \
  {{run_prefix}} scripts/converge.sh flagg l4

# Full converge of Trilium
l4-converge-trilium:
  TAGS=step_docker_trilium \
  {{run_prefix}} scripts/converge.sh carrie l4

# Full converge of Cloudflare
l4-converge-cloudflare:
  TAGS=step_docker_cloudflare \
  {{run_prefix}} scripts/converge.sh flagg l4

# Full converge of Plex
l4-converge-plex:
  TAGS=step_docker_plex \
  {{run_prefix}} scripts/converge.sh misery l4

# Full converge of Jellyfin
l4-converge-jellyfin:
  TAGS=step_docker_jellyfin \
  {{run_prefix}} scripts/converge.sh misery l4

