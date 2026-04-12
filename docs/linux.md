# Linux VMs

## Overview

This section covers management of traditional Linux virtual machines.

Currently supported:

- Arch Linux
- Ubuntu

These systems differ from other parts of the repo:

- NixOS hosts are declarative
- Appliances are image-driven
- Linux VMs use a hybrid model:
  - Terraform provisions the VM
  - Ansible converges the operating system

These are primarily used for experimentation and non-production workloads.

---

## Mental Model

Linux VMs follow a simple lifecycle:

1. Define host in [`inventory/hosts/`](../inventory/hosts/)
2. Build ISO or template
3. Provision VM using Terraform
4. Converge system using Ansible

Key distinction:

- Terraform ensures the VM exists
- Ansible ensures the system is configured

Unlike NixOS, convergence is procedural and may require multiple runs or debugging.

---

# Arch Linux

## Create an Arch VM

### 1. Build Custom ISO

```bash
just arch-iso
```

Downloads Arch and creates a custom cloud-init ISO.

---

### 2. Create VM Template

```bash
just arch-vm-template
```

Creates a Proxmox VM template using the custom ISO.

---

### 3. Create VM

```bash
just terraform <hostname> apply 1
```

- Use `0` instead of `1` for a dry run

---

### 4. Converge with Ansible

```bash
just linux-converge "" "<hostname>"
```

Runs Ansible convergence for the host.

---

## Update / Re-Converge Arch

```bash
just linux-converge "" "<hostname>"
```

Used for:

- package changes
- service updates
- configuration changes

---

## Rebuild Arch VM

```bash
just terraform <hostname> destroy 1
just terraform <hostname> apply 1
just linux-converge "" "<hostname>"
```

---

## Notes (Arch)

- Rolling release model
- More prone to drift
- Useful for experimentation

---

# Ubuntu

## Create an Ubuntu VM

### 1. Create VM Template

```bash
just ubuntu-vm-template
```

Creates a Proxmox VM template using a standard Ubuntu ISO.

---

### 2. Create VM

```bash
just terraform <hostname> apply 1
```

- Use `0` for a dry run

---

### 3. Converge with Ansible

```bash
just linux-converge "" "<hostname>"
```

---

## Update / Re-Converge Ubuntu

```bash
just linux-converge "" "<hostname>"
```

---

## Rebuild Ubuntu VM

```bash
just terraform <hostname> destroy 1
just terraform <hostname> apply 1
just linux-converge "" "<hostname>"
```

---

## Notes (Ubuntu)

- More stable than Arch
- Better for predictable environments
- Still subject to drift

---

# Shared Workflow Reference

## Inventory

Defined in:

- [`inventory/hosts/`](../inventory/hosts/)

---

## Template / ISO Creation

- Arch uses `arch-iso`
- Ubuntu uses `ubuntu-vm-template`

---

## Terraform Lifecycle

```bash
just terraform <hostname> apply 1
just terraform <hostname> destroy 1
```

- Use `0` for dry runs

---

## Ansible Convergence

```bash
just linux-converge "" "<hostname>"
```

Responsible for system configuration.

---

# Differences vs Other Systems

## Compared to NixOS

- Imperative vs declarative
- Drift possible
- Less predictable rebuilds

## Compared to Appliances

- Full OS control
- Not image-driven after provisioning

---

# Gotchas / Notes

- Ansible must be idempotent
- Partial failures can leave inconsistent state
- Re-running convergence is common
- Debug via SSH and logs

---

# Intent

Linux VMs are retained for:

- experimentation
- testing traditional workflows

Not the primary production path.
