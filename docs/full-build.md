# Full Build/Converge Process

This section deatils how to install build artifacts and VMs on a Proxmox VE server.

## Prerequisites

Before running any layer of the orchestration stack, certain prerequisites must be satisfied locally. These ensure the tooling can authenticate to infrastructure providers and target the correct environment.

### Proxmox VE Server

A Proxmox VE server running at least version `9.1.1` must be installed and accessible.

At times the Proxmox installer might hang or get stuck on a white screen.  To resolve this, at the Proxmox installer boot menu:

1. Highlight “Install Proxmox VE”
1. Press `e` to edit boot parameters
1. Find the line that starts with `linux`
1. Append this to the end of the line:

```
nomodeset
```

### Proxmox Access Token

### Required Environment Variables

The following environment variables **must be set** for infrastructure-related operations (particularly L1 and L2):

- `PVE_ACCESS_HOST`  
  Proxmox API endpoint (e.g. `proxmox.hosts.allanshomelab.com`)

- `PM_TOKEN_ID`  
  Proxmox API token ID (e.g. `gitops@pve!gitops`)

- `PM_TOKEN_SECRET`  
  Proxmox API token secret

- `PVE_NODE`  
  Target Proxmox node name (e.g. `polaris`)

- `PVE_STORAGE_VM`  
  Proxmox storage identifier for VM disks (e.g. `local-lvm`)

These variables are validated early in the workflow and execution will fail if any are missing.