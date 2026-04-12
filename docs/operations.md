# Operations

## Overview

All operations in this repository are driven through the `Justfile`.

Commands wrap underlying tools:

- Terraform (VM lifecycle)
- NixOS (system convergence)
- Ansible (Linux convergence)
- Appliance-specific scripts

The goal is consistent, repeatable workflows.

---

## Common Workflows

### Create a NixOS VM

```bash
just nixos-vm-template
just terraform <host> apply 1
just nixos-switch <host>
```

---

### Update a NixOS Host

```bash
just nixos-switch <host>
```

---

### Rebuild a NixOS Host

```bash
just terraform <host> destroy 1
just terraform <host> apply 1
just nixos-switch <host>
```

---

### Create an Appliance VM (HAOS / TrueNAS)

```bash
haos-boot-disk-capture <vmid>
haos-vm-template
just terraform <host> apply 1
```

(TrueNAS follows the same pattern with `truenas-*` commands)

---

### Rebuild an Appliance VM

```bash
just terraform <host> destroy 1
just terraform <host> apply 1
```

---

### Create a Linux VM

```bash
just arch-iso
just arch-vm-template
just terraform <host> apply 1
just linux-converge "" "<host>"
```

---

## Command Reference

### NixOS

- `just nixos-vm-template` — build/update base template
- `just nixos-switch <host>` — converge host

---

### Terraform

```bash
just terraform <host> apply 1
just terraform <host> destroy 1
```

- `1` = apply
- `0` = dry run

---

### Appliances

- `haos-boot-disk-capture <vmid>`
- `haos-vm-template`
- `truenas-boot-disk-capture <vmid>`
- `truenas-vm-template`
- `truenas-attach-disks <vmid>`

---

### Linux / Ansible

- `just arch-iso`
- `just arch-vm-template`
- `just ubuntu-vm-template`
- `just linux-converge "" "<host>"`

---

## Dry Runs and Safety

- Terraform supports dry runs via `0`
- Prefer dry runs when:
  - creating new hosts
  - making destructive changes

---

## How Commands Fit Together

Typical flow:

- Template → Terraform → Converge

Differences by system:

- NixOS → converged via Nix
- Appliances → no convergence step
- Linux → converged via Ansible

---

## Debugging / Recovery

- Re-run the failing command
- Use dry run where possible
- Check underlying tool:
  - Terraform for VM issues
  - NixOS for system issues
  - Ansible for Linux hosts

---

# Miscellaneous Operations

## Proxmox VE Updates

To apply minor version updates on Proxmox:

```bash
apt update
apt full-upgrade
```

Reboot if required.

---

## TrueNAS

### Run Prometheus Node Exporter

Compose file:

[`appliance/truenas/misc/node-exporter.compose.yaml`](../appliance/truenas/misc/node-exporter.compose.yaml)

Deploy using Docker Compose on the TrueNAS host.

---

### Media Sync Script

Script location:

[`appliance/truenas/misc/media-sync.sh`](../appliance/truenas/misc/media-sync.sh)

This is a custom script used to synchronize media data. It is specific to this environment and not intended to be generic.

---

## Restore a Postgres DB Dump

```bash
docker run --rm   --network authentik_default   -v "/path/to/backups:/backups:ro"   -e PGPASSWORD='YOUR_DB_PASSWORD'   postgres:16   pg_restore     -h <postgres_service_name_or_container_name>     -U <db_user>     -d <db_name>     --clean --if-exists     --no-owner --no-privileges     --exit-on-error     /backups/authentik.dump
```

---

## Run Node Exporter on Asustor NAS

Cleanup existing container:

```bash
sudo docker rm node_exporter
```

Run Node Exporter:

```bash
sudo docker run -d --name node_exporter -p 9100:9100 --restart unless-stopped prom/node-exporter
```
