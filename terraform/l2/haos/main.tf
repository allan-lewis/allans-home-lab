locals {
  # Path to this persona's hosts.json spec
  hosts_json_path = "${path.module}/../../../infra/os/haos/personas/homeassistant/spec/terraform.json"

  # Logical template refs → manifest JSON files for this persona
  template_manifest_map = {
    "haos/homeassistant/stable" = "${path.module}/../../../infra/os/haos/artifacts/vm-template-20260118T211015Z.json"
    # Add canary/etc here later if needed
  }
}

module "factory" {
  source = "../modules/common_vm_factory"

  # Spec inputs
  hosts_json_path       = local.hosts_json_path
  template_manifest_map = local.template_manifest_map

  # Infra defaults (passed down to cloudinit)
  storage = var.storage
  scsihw  = var.scsihw
  bridge  = var.bridge
  agent_enabled = false

  # Cloud-init settings
  ci_user             = var.ci_user
  ssh_authorized_keys = [var.proxmox_vm_public_key]
}

