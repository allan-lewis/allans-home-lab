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

Detail steps for creating user/token/permissions for PVEAdmin.

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

## Sanity Checks

### Runway

Run L0 runway checks to ensure that variables above have been configured correctly and that the Proxmox host is in a state where it can be used to deploy VMs.

```bash
make l0-runway
```

## Ubuntu DevOps VM

While any of the make commands can be run from anywhere, including local Mac/Linux hosts, getting a dedicated Ubuntu server to a state where it can be used as a central dev ops box is a good general practice.

### Create Ubuntu VM Template

Run this L1 command to download a stable Linux ISO and create a VM template from it.

```bash
make l1-ubuntu-template
```

### Build Ubuntu DevOps VM

Run the L2 command to create a VM using the template prodcued earlier.

```bash
make l2-apply-ubuntu_devops APPLY=1
```

### Converge Ubuntu DevOps VM

Run L3 convergence to get the DevOps host's "personality" in place.

```bash
make l3-converge-ubuntu_devops
```

Then run L4 convergence to get the host operationally ready.

```bash
make l4-converge-ubuntu_devops
```

At this point the Ubuntu DevOps host can be used to manage remaining steps from the `/home/lab/src/allans-home-lab` folder.

## Arch VMs

### Create Custom Bootable Arch ISO

The following L1 command will create a bootable Arch ISO and customize it for use with cloud init.

```bash
make l1-arch-iso
```

### Create Arch VM Template

Run a Packer build that uses the ISO created above to create a Proxmox VM template that can be used to build Arch VMs.

```bash
make l1-arch-template
```

### Create Arch VMs

Run the following to build Arch hosts for both the dev ops and sandbox/tinker personas.

```bash
make l2-apply-arch_devops APPLY=1
```
```bash
make l2-apply-arch_tinker APPLY=1
```

### Converge Arch VMs

Convergence can be done Arch-wide.

```bash
make l3-converge-arch
```

```bash
make l4-converge-arch
``` 
## Ubuntu VMs

### Build & Converge Ubuntu Tinker VM(s)

Run the following to build/converge Ubuntu sanbox/tinker host(s).

```bash
make l2-apply-ubuntu_tinker APPLY=1
```

```bash
make l3-converge-ubuntu_tinker
```

```bash
make l4-converge-ubuntu_tinker
```

### Create Ubuntu Docker VMs

Do an L2 apply action that creates all VMs that will run Docker containers.

```bash
make l2-apply-ubuntu_docker APPLY=1
```

### Build & Converge Ubuntu Docker VMs

Hosts can either be converged as a group or individually.

Group converge:

```bash
make l3-converge-ubuntu_docker
```

```bash
make l4-converge-ubuntu_docker
```

Misery (media):

```bash
make l3-converge-misery
```

```bash
make l4-converge-misery
```

Patricia (media acquisition):

```bash
make l3-converge-patricia
```

```bash
make l4-converge-patricia
```

Carrie (misc):

```bash
make l3-converge-carrie
```

```bash
make l4-converge-carrie
```

### Build & Converge Ubuntu OpenVPN VM

Run the following to create and configure the OpenVPN gateway.

```bash
make l2-apply-ubuntu_openvpn APPLY=1
```

```bash
make l3-converge-ubuntu_openvpn
```

```bash
make l4-converge-ubuntu_openvpn
```

### Converge Bare Metal Ubuntu Host

Use Ansible to converge the bare metal host (where L2 obviously doesn't apply).

```bash
make l3-converge-flagg
```

```bash
make l4-converge-flagg
```
