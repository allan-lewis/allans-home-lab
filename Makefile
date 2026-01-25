SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c 
.ONESHELL:

RUN ?= doppler run -- # by default, run using doppler
ifeq ($(CI),true) # skip doppler in CI mode 
  ifneq ($(FORCE_DOPPLER),1) # unless forcing doppler usage
    override RUN :=
  endif
endif
ifeq ($(DOPPLER),0) # kill switch to disable doppler 
  override RUN :=
endif

export ANSIBLE_CONFIG := $(CURDIR)/ansible.cfg
# export ANSIBLE_HOST_KEY_CHECKING := False
# export PIP_DISABLE_PIP_VERSION_CHECK := 1
export RUN

ifneq (,$(wildcard ./.env))
include .env # load .env if present
export
endif

TF_DIR ?= terraform/l2
.DEFAULT_GOAL := help

.PHONY: \
  help \
  clean \
  l0-runway \
  l1-arch-iso \
  l1-arch-template \
  l1-haos-capture-% \
  l1-haos-template \
	l1-truenas-capture-% \
	l1-truenas-template \
  l1-ubuntu-template \
  l2-apply-% \
  l2-destroy-% \
  l3-converge-% \
  l3-reboot-% \
  l3-shutdown-% \
  l4-converge-% \
  l4-converge-authentik-prod \
  l4-converge-authentik-tinker \
  l4-converge-gatus \
  l4-converge-gatus-config \
  l4-converge-homepage \
  l4-converge-homepage-config \
  l4-converge-immich-tinker \
  l4-converge-immich-tinker \
  l4-converge-observability \
  l4-converge-pihole-dns \
  l4-converge-pihole \
  l4-converge-traefik \
  l4-converge-twingate \
  l4-converge-vaultwarden

help: ## Show a list of all targets
	@awk 'BEGIN{FS=":.*##"; printf "\nTargets:\n"} /^[a-zA-Z0-9_%.\/\-]+:.*##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

clean: ## Remove all non-versioned build artifacts and temporary files
	@$(RUN) bash -lc 'scripts/clean.sh'

l0-runway: ## Runway checks (OS/persona independent)
	@$(RUN) bash -lc 'scripts/l0/runway.sh'

l1-arch-iso: ## Put a custom, bootable Arch ISO onto Proxmox
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/arch-iso.sh'

l1-arch-template: ## Prepare a Proxmox VM template suitable for Arch installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/arch-template.sh packer/l1/arch'

l1-haos-capture-%: ## Export a Proxmox VM's boot disk to an S3 bucket
	@$(RUN) bash -lc 'set -euo pipefail; \
	  S3_BUCKET=gitops-homelab-orchestrator-disks \
	  S3_PREFIX=proxmox-images \
    scripts/l1/appliance-capture.sh haos "$*"'

l1-truenas-capture-%: ## Export a Proxmox VM's boot disk to an S3 bucket
	@$(RUN) bash -lc 'set -euo pipefail; \
	  S3_BUCKET=gitops-homelab-orchestrator-disks \
	  S3_PREFIX=proxmox-images \
    scripts/l1/appliance-capture.sh truenas "$*"'

l1-haos-template: ## Prepare a Proxmox VM template suitable for HAOS installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/appliance-template.sh haos'

l1-truenas-template: ## Prepare a Proxmox VM template suitable for TrueNAS installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/appliance-template.sh truenas'

l1-ubuntu-template: ## Prepare a Proxmox VM template suitable for Ubuntu installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/ubuntu-template.sh'

l2-apply-%: ## Apply Terraform resources for an OS/persona pair
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l2/terraform.sh "$(TF_DIR)/$*" apply'

l2-destroy-%: ## Destroy Terraform resources for an OS/persona pair
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l2/terraform.sh "$(TF_DIR)/$*" destroy'

l3-homeassistant: ## Restore a HA host from an S3 backup
	@$(RUN) bash -lc 'scripts/l3/haos.sh'

l3-converge-%: ## Converge a group of hosts (capabilities)
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/converge.sh "$*" l3'

l3-reboot-%: ## Reboot a group of hosts
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l3/reboot.sh "$*"'

l3-shutdown-%: ## Shut down a group of hosts
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l3/shutdown.sh "$*"'

l3-truenas-%: ## Attach disks to a TrueNAS host
	@$(RUN) bash -lc 'set -euo pipefail; \
    : "$${PVE_SSH_IP:?Set PVE_SSH_IP}"; \
    scripts/l3/proxmox-disks.sh \
      "$${PVE_SSH_IP}" \
      "$*" \
      "infra/os/truenas/personas/nas/spec/terraform.json";'

l4-converge-%: ## Converge a group of hosts (workloads)
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/converge.sh "$*" l4'

l4-converge-gatus: ## Converge the entire Gatus stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_gatus_all scripts/converge.sh "flagg" l4'

l4-converge-gatus-config: ## Converge just the Gatus config file
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_gatus scripts/converge.sh "flagg" l4'

l4-converge-traefik: ## Converge the entire Gatus stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_traefik scripts/converge.sh "flagg" l4'

l4-converge-pihole: ## Converge the entire Pi-Hole stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_pihole_all scripts/converge.sh "flagg" l4'

l4-converge-pihole-dns: ## Converge just Pi-Hole DNS names
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_pihole scripts/converge.sh "flagg" l4'

l4-converge-authentik-prod: ## Converge Authentik production deployment
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_authentik scripts/converge.sh "flagg" l4'

l4-converge-authentik-tinker: ## Converge Authentik test/recovery deployment
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_authentik scripts/converge.sh "barlow" l4'

l4-converge-immich-prod: ## Converge Immich production deployment
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_immich scripts/converge.sh "misery" l4'

l4-converge-immich-tinker: ## Converge Immich test/recovery deployment
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_immich scripts/converge.sh "barlow" l4'

l4-converge-homepage: ## Converge the entire Gatus stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_homepage_all scripts/converge.sh "carrie" l4'

l4-converge-homepage-config: ## Converge just the Gatus config file
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_homepage scripts/converge.sh "carrie" l4'

l4-converge-vaultwarden: ## Converge the entire Vaultwarden stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_vaultwarden scripts/converge.sh "carrie" l4'

l4-converge-twingate: ## Converge the entire Twingate stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_twingate scripts/converge.sh "ubuntu_docker_twingate" l4'

l4-converge-observability: ## Converge the entire Prometheus/Grafana/Alertmanager stack
	@$(RUN) bash -lc 'set -euo pipefail; \
	  TAGS=step_docker_observability scripts/converge.sh "flagg" l4'
