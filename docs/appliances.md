# Appliances

## Overview

This section covers management of appliance-style virtual machines.

Currently supported:

- Home Assistant OS (HAOS)
- TrueNAS Scale

These systems differ from NixOS hosts:

- The operating system is not managed declaratively
- The system state is tied to a boot disk image
- Lifecycle is driven by disk capture, templates, and VM provisioning

---

## Mental Model

Appliances are image-driven.

The workflow is:

1. Capture a boot disk from a known-good VM
2. Store that disk in S3
3. Create a Proxmox VM template from that disk
4. Use Terraform to create or destroy VMs from that template

Terraform manages the VM lifecycle.

The appliance manages its own internal state.

---

# Home Assistant OS (HAOS)

## Create a HAOS VM

### 1. Capture Boot Disk

Capture a known-good HAOS VM boot disk and upload it to S3:

```bash
haos-boot-disk-capture 101
```

Argument is the Proxmox VM ID.

---

### 2. Create Template

Create a Proxmox VM template from the captured disk:

```bash
haos-vm-template
```

This pulls the disk from S3 and registers a reusable template.

---

### 3. Create VM

Provision the VM using Terraform:

```bash
just terraform <hostname> apply 1
```

- Use `0` instead of `1` for a dry run
- This creates the VM from the HAOS template

---

### 4. Boot and Validate

Once created:

- Access the HAOS web UI
- Complete any first-boot setup if required

---

## Update / Rebuild HAOS

HAOS manages its own updates internally.

If you need to rebuild:

```bash
just terraform <hostname> destroy 1
just terraform <hostname> apply 1
```

This recreates the VM from the current template.

---

## Notes (HAOS)

- No meaningful OS-level management from this repo
- Treat as a black box after provisioning
- All configuration happens via the HA UI

---

# TrueNAS Scale

## Create a TrueNAS VM

### 1. Capture Boot Disk

Capture a known-good TrueNAS boot disk:

```bash
truenas-boot-disk-capture 100
```

---

### 2. Create Template

Create a template from the captured disk:

```bash
truenas-vm-template
```

---

### 3. Create VM

Provision the VM:

```bash
just terraform <hostname> apply 1
```

- Use `0` for a dry run

---

### 4. Attach Data Disks

Attach physical disks for storage pools:

```bash
truenas-attach-disks 101
```

Argument is the VM ID.

Disk definitions are sourced from inventory.

Example:
[`inventory/hosts/pennywise.toml`](../inventory/hosts/pennywise.toml)

From the VM ID, the system:

- resolves the hostname
- loads the corresponding inventory file
- attaches the configured disks

These disks are separate from the boot disk and are used to build storage pools.

---

## Update / Rebuild TrueNAS

Rebuild flow:

```bash
just terraform <hostname> destroy 1
just terraform <hostname> apply 1
```

Then reattach disks:

```bash
truenas-attach-disks <vmid>
```

Important:

- Data lives on attached disks
- Boot disk can be replaced without losing pools
- Pools must be re-imported if necessary

---

## Notes (TrueNAS)

- Disk identity matters — avoid changing device mappings
- Pools depend on consistent disk visibility
- Be careful when modifying disk assignments in Proxmox

---

# Shared Workflow Reference

## Capture Boot Disk

Commands:

```bash
truenas-boot-disk-capture <vmid>
haos-boot-disk-capture <vmid>
```

This:

- extracts the VM boot disk
- uploads it to S3
- prepares it for template creation

---

## Create Template

Commands:

```bash
truenas-vm-template
haos-vm-template
```

This:

- downloads the disk from S3
- registers a Proxmox template
- makes it available to Terraform

---

## Terraform Lifecycle

Create VM:

```bash
just terraform <hostname> apply 1
```

Destroy VM:

```bash
just terraform <hostname> destroy 1
```

- Use `0` for dry runs
- Terraform controls VM lifecycle only
- No OS-level convergence step exists for appliances

---

# Gotchas / Notes

- Template drift requires rebuilding templates, not just VMs
- VM recreation does not update templates automatically
- Disk sizing must match expectations when creating templates
- Proxmox device naming can change — verify mappings
