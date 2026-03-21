module "factory" {
  source = "../l2/modules/common_vm_factory"

  hosts_json_path       = var.hosts_json_path
  template_manifest_path = var.template_manifest_path

  storage       = var.storage
  scsihw        = var.scsihw
  bridge        = var.bridge
  agent_enabled = var.agent_enabled

  ci_user             = var.ci_user
  ssh_authorized_keys = [var.proxmox_vm_public_key]
}