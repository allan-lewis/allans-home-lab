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
  l2-destroy-% \
  l3-converge-% \
  l4-converge-% \
  l4-converge-gatus \
  l4-converge-gatus-config \
  l4-converge-traefik

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

l1-ubuntu-template: ## Prepare a Proxmox VM template suitable for Ubuntu installations
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l1/ubuntu-template.sh'

l2-apply-%: ## Apply Terraform resources for an OS/persona pair
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l2/terraform.sh "$(TF_DIR)/$*" apply'

l2-destroy-%: ## Destroy Terraform resources for an OS/persona pair
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/l2/terraform.sh "$(TF_DIR)/$*" destroy'

l3-converge-%: ## Converge a group of hosts (capabilities)
	@$(RUN) bash -lc 'set -euo pipefail; \
	  scripts/converge.sh "$*" l3'

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
