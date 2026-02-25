locals {
  # Path to this persona's hosts.json spec
  hosts_json_path = "${path.module}/../../../infra/os/nixos/personas/media/spec/hosts.json"

  # Logical template refs → manifest JSON files for this persona
  template_manifest_map = {
    "nixos/media/stable" = "${path.module}/../../../infra/os/nixos/spec/vm-template-stable.json"
    # Add canary/etc here later if needed
  }
}

module "factory" {
  source = "../../l2/modules/common_vm_factory"

  hosts_json_path       = local.hosts_json_path
  template_manifest_map = local.template_manifest_map

  storage       = var.storage
  scsihw        = var.scsihw
  bridge        = var.bridge
  agent_enabled = true

  ci_user             = var.ci_user
  ssh_authorized_keys = [var.proxmox_vm_public_key]
}

