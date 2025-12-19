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
  l1-ubuntu-template \
  l2-apply-% \
  l2-destroy-%
#   l2-arch-devops-apply \
#   l2-arch-devops-destroy \
#   l2-arch-tinker-apply \
#   l2-arch-tinker-destroy \
#   l2-ubuntu-docker-apply \
#   l2-ubuntu-openvpn-apply \
#   l2-ubuntu-openvpn-destroy \
#   l2-ubuntu-tinker-apply \
#   l2-ubuntu-tinker-destroy \
#   l3-arch-devops-converge \
#   l3-arch-tinker-converge \
#   l3-ubuntu-core-converge \
#   l3-ubuntu-docker-converge \
#   l3-ubuntu-openvpn-converge \
#   l3-ubuntu-tinker-converge

help: ## Show a list of all targets
	@awk 'BEGIN{FS=":.*##"; printf "\nTargets:\n"} /^[a-zA-Z0-9_\-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

## ---- GLOBAL TARGETS
clean: ## Remove all non-versioned build artifacts and temporary files
	@$(RUN) bash -lc 'scripts/clean.sh'

## ---- L0 TARGETS FOR ALL OS/PERSONA
l0-runway: ## Runway checks (OS/persona independent)
	@$(RUN) bash -lc 'scripts/l0/runway.sh'

## ---- L1 TARGETS FOR ALL PERSONAS FOR A SINGLE OS
l1-arch-iso: ## Put a custom, bootable Arch ISO onto Proxmox
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/arch-iso.sh'

l1-arch-template: ## Prepare a Proxmox VM template suitable for Arch installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/arch-template.sh packer/l1/arch'

l1-ubuntu-template: ## Prepare a Proxmox VM template suitable for Ubuntu installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/ubuntu-template.sh'

# ## ---- L2 TARGETS PER OS/PERSONA
l2-apply-%: ## Ex: make l2-apply-arch_devops
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l2/terraform.sh "$(TF_DIR)/$*" apply'

l2-destroy-%: ## Ex: make l2-destroy-ubuntu_docker
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l2/terraform.sh "$(TF_DIR)/$*" destroy'

# ## ---- L3 TARGETS PER OS/PERSONA
# # Usage examples:
# #   make l3-<os>-<persona>-converge                          	# all hosts, all tags
# #   make l3-<os>-<persona>-converge L3_LIMIT=host1          	# single host
# #   make l3-<os>-<persona>-converge L3_LIMIT='host1:host2'  # Ansible limit expression
# #   make l3-<os>-<persona>-converge L3_TAGS=base             	# only "base" tag
# #   make l3-<os>-<persona>-converge L3_TAGS=base,desktop     	# multiple tags
#
# l3-arch-devops-converge: ## Converge Arch DevOps hosts (L3 via Ansible)
# 	@$(RUN) bash -lc 'set -euo pipefail; \
# 	  scripts/l3-converge.sh arch arch_devops'
#
# l3-arch-tinker-converge: ## Converge Arch Tinker hosts (L3 via Ansible)
# 	@$(RUN) bash -lc 'set -euo pipefail; \
# 	  scripts/l3-converge.sh arch arch_tinker'
#
# l3-ubuntu-core-converge: ## Converge Ubuntu core hosts (L3 via Ansible)
# 	@$(RUN) bash -lc 'set -euo pipefail; \
# 	  scripts/l3-converge.sh ubuntu ubuntu_core'
#
# l3-ubuntu-docker-converge: ## Converge Ubuntu Docker hosts (L3 via Ansible)
# 	@$(RUN) bash -lc 'set -euo pipefail; \
# 	  scripts/l3-converge.sh ubuntu ubuntu_misc'
#
# l3-ubuntu-openvpn-converge: ## Converge Ubuntu OpenVPN hosts (L3 via Ansible)
# 	@$(RUN) bash -lc 'set -euo pipefail; \
# 	  scripts/l3-converge.sh ubuntu ubuntu_openvpn'
#
# l3-ubuntu-tinker-converge: ## Converge Ubuntu Tinker hosts (L3 via Ansible)
# 	@$(RUN) bash -lc 'set -euo pipefail; \
# 	  scripts/l3-converge.sh ubuntu ubuntu_tinker'
