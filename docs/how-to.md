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

### Stable Manifest Behavior

By default, L1 tasks that upload ISOs and templates update the stable manifest reference to point at the newly built artifact manifest.

To disable this behavior, set:

    UPDATE_STABLE=no

Any value other than `yes` will prevent the stable manifest from being updated.

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

## Building an Ubuntu VM Template (L1)

The `l1-ubuntu-template` target builds a reusable Ubuntu VM template for Proxmox. It downloads an upstream Ubuntu cloud image, prepares it for cloud-init–based provisioning, uploads it to Proxmox, and records the result in versioned build metadata.

### Usage

```bash
make l1-ubuntu-template
```

### What `l1-ubuntu-template` Does

Running `l1-ubuntu-template` performs the following steps:

- Downloads the specified Ubuntu cloud image
- Uploads the image to the configured Proxmox storage
- Creates or updates a VM template configured for cloud-init
- Applies template-level settings required for automated provisioning
- Generates a GitHub-versioned manifest describing the build outputs
- Optionally updates a stable manifest reference for downstream consumers

The resulting template is intended to be consumed by L2 when provisioning Ubuntu-based hosts.

### Outputs

- A cloud-init–ready Ubuntu VM template in Proxmox
- A versioned build manifest committed to the repository
- A `stable` manifest reference pointing at the latest approved build (optional)

### When to Run

Run `l1-ubuntu-template`:

- When introducing a new Ubuntu base image
- After changing template or cloud-init configuration
- When intentionally promoting a new template version to stable
- Before provisioning new Ubuntu hosts in L2

This target produces image and metadata artifacts only and does not provision or modify running hosts.

## Building an Arch VM Template (L1)

The `l1-arch-template` target builds a reusable Arch Linux VM template on Proxmox using Packer. It produces a fully bootstrapped, cloud-init–ready template suitable for automated provisioning in later layers.

### Usage

```bash
make l1-arch-template
```

### What `l1-arch-template` Does

Running `l1-arch-template` performs the following steps:

- Uses Packer to create a new Arch Linux VM on Proxmox
- Performs a fully automated Arch installation
- Installs required base packages, guest tooling, and cloud-init support
- Applies template-level configuration appropriate for all future hosts
- Converts the VM into a Proxmox template
- Generates a GitHub-versioned manifest describing the build outputs
- Optionally updates a stable manifest reference for downstream consumers

The resulting template is designed to be consumed by L2 when provisioning Arch-based hosts.

### Outputs

- A cloud-init–ready Arch Linux VM template in Proxmox
- A versioned build manifest committed to the repository
- An optional stable manifest reference pointing at the approved template

### When to Run

Run `l1-arch-template`:

- When bootstrapping or updating the Arch base template
- After modifying Packer build logic or provisioning steps
- When intentionally promoting a new Arch template version
- Before provisioning new Arch hosts in L2

This target produces image and metadata artifacts only and does not provision or modify running hosts.

## Provisioning and Destroying Infrastructure (L2)

The `l2-apply-%` and `l2-destroy-%` targets manage Terraform resources for a specific OS/persona pair. The `%` portion is the Terraform workspace directory name (for example, `ubuntu_devops`), which maps to a directory under `terraform/l2/` and determines which Terraform configuration is operated on.

### Usage

Apply (defaults to plan mode):

```bash
make l2-apply-ubuntu_devops
```

Apply (perform real changes):

```bash
APPLY=1 make l2-apply-ubuntu_devops
```

Destroy (defaults to plan mode):

```bash
make l2-destroy-ubuntu_devops
```

Destroy (perform real changes):

```bash
APPLY=1 make l2-destroy-ubuntu_devops
```

### What These Targets Do

- `l2-apply-%` runs the equivalent of `terraform apply` against `terraform/l2/<name>`
- `l2-destroy-%` runs the equivalent of `terraform destroy` against `terraform/l2/<name>`

Both targets route through `scripts/l2/terraform.sh`, which selects the Terraform directory based on the provided suffix (e.g. `ubuntu_devops`).

### Safety Default: Plan Mode

By default, both targets run in a non-destructive plan mode and will not modify infrastructure.

To apply changes (including creating or destroying resources), you must set:

```bash
APPLY=1
```

## Converging Hosts (L3 and L4)

The `l3-converge-%` and `l4-converge-%` targets run Ansible convergence against a specific group of hosts. The `%` portion must map to a valid Ansible inventory group, and convergence is limited to the hosts in that group.

### Usage

Converge host capabilities (L3):

```bash
make l3-converge-ubuntu_devops
```

Converge workloads (L4):

```bash
make l4-converge-ubuntu_devops
```

### What These Targets Do

- `l3-converge-%` applies **L3 convergence**, configuring operating system state and host capabilities
- `l4-converge-%` applies **L4 convergence**, deploying and managing application workloads

Both targets route through a shared convergence script, which selects the appropriate Ansible playbooks based on the requested layer.

### Inventory Group Requirement

The suffix provided to the target (for example, `ubuntu_devops`) must correspond to an existing Ansible inventory group. Only hosts in that group will be targeted during convergence.

### Additional Execution Controls

The following variables may be used to further limit or scope execution:

- `TAGS`  
  Restricts Ansible execution to specific tags.

```bash
TAGS=backup make l3-converge-ubuntu_devops
```

- `LIMIT`  
  Restricts execution to a subset of hosts or groups.

```bash
LIMIT=host1 make l4-converge-ubuntu_devops
```

These controls may be combined as needed to safely iterate on changes.

### When to Run

Run L3 convergence when refining OS configuration or host capabilities.  
Run L4 convergence when deploying, updating, or validating application workloads.

Both targets are safe to re-run and are designed to support incremental iteration.
