# How-To Guides

This section contains practical, task-oriented documentation for operating the homelab orchestration stack.

Each guide focuses on **how to accomplish a specific goal** using the L0–L4 model, with concrete commands and examples.

## Prerequisites

Before running any layer of the orchestration stack, certain prerequisites must be satisfied locally. These ensure the tooling can authenticate to infrastructure providers and target the correct environment.

### Required Environment Variables

The following environment variables **must be set** for infrastructure-related operations (particularly L1 and L2):

- `PVE_ACCESS_HOST`  
  Proxmox API endpoint (e.g. `pve.example.com`)

- `PM_TOKEN_ID`  
  Proxmox API token ID (e.g. `gitops@pve!gitops`)

- `PM_TOKEN_SECRET`  
  Proxmox API token secret

- `PVE_NODE`  
  Target Proxmox node name (e.g. `polaris`)

- `PVE_STORAGE_VM`  
  Proxmox storage identifier for VM disks (e.g. `local-lvm`)

These variables are validated early in the workflow and execution will fail if any are missing.

---

### Doppler (Recommended / Happy Path)

By default, the provided `Makefile` prefixes all commands with an invocation of Doppler, providing a clean and easy way to populate environment variables.  This prefixing can be skipped if a different method of providing these values is preferred.

A make call like this:

```bash
make <target>
```

Will be executed like this (by default):

```bash
doppler run -- make <target>
```
## Cleaning the Workspace

The `clean` target removes all locally generated artifacts and temporary files created during normal operation of the stack.

### Usage

```bash
make clean
```

### What `clean` Does

Running `clean` removes local-only state such as:

* Generated artifacts and manifests
* Rendered inventories and intermediate files
* Cached downloads and temporary working directories
* Build output from tooling like Packer, Terraform, and Ansible

The goal is to return the repository to a **fresh checkout–equivalent state**.

### What `clean` Does *Not* Do

The `clean` target does **not**:

* Destroy infrastructure
* Modify remote systems
* Remove secrets or environment configuration

It is safe to run at any time and only affects the local working directory.

## Running L0 Checks

The `l0-runway` target validates that the local execution environment is safe and correctly configured before any other layer is run.

### Usage

```bash
make l0-runway
```

### What `l0-runway` Does

Running `l0-runway` performs early validation such as:

- Required tooling is installed and accessible
- Required environment variables are present
- Credentials and API access are available
- Target configuration is internally consistent

No infrastructure or remote hosts are modified.

### When to Run

Run `l0-runway`:

- Before running any other layer
- After changing environment variables or secrets
- When debugging failures in later layers

If `l0-runway` succeeds, it is safe to proceed to subsequent layers.

## Building an Arch ISO (L1)

The `l1-arch-iso` target builds a custom Arch Linux ISO suitable for automated provisioning. It downloads the latest upstream Arch ISO, applies local customizations, prepares the image for cloud-init–style provisioning, and uploads the resulting artifact to Proxmox.

### Usage

```bash
make l1-arch-iso
```

### What `l1-arch-iso` Does

Running `l1-arch-iso` performs the following steps:

- Downloads the latest official Arch Linux ISO
- Unpacks and customizes the ISO contents
- Applies configuration needed for unattended installs
- Installs required tooling and early-boot configuration
- Prepares the image for cloud-init or equivalent first-boot customization
- Rebuilds the ISO with the applied changes
- Uploads the resulting ISO to the configured Proxmox host and storage

The resulting ISO is intended to be used as an installation source for automated VM builds in later layers.

### Outputs

- A customized, versioned Arch Linux ISO
- An uploaded ISO artifact available in Proxmox storage
- Source-controlled manifest documenting Proxmox coordinates for the ISO (to be used in later stages)
- Updated "stable" Arch ISO manifest link (optional, enabled by default)

### When to Run

Run `l1-arch-iso`:

- When bootstrapping a new environment
- When upstream Arch ISO changes are required
- After modifying ISO customization logic
- Before provisioning new Arch-based hosts in L2

This target only produces image artifacts and does not create or modify any running infrastructure.
