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
doppler run -- make <target>
```

Will be executed like this:

```bash
doppler run -- make <target>
```
