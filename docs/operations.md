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
just haos-boot-disk-capture <vmid>
just haos-vm-template
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

(Ubuntu commands follow the same pattern minus the ISO step)

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

- `just haos-boot-disk-capture <vmid>`
- `just haos-vm-template`
- `just truenas-boot-disk-capture <vmid>`
- `just truenas-vm-template`
- `just truenas-attach-disks <vmid>`

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
- Appliances → minimal convergence steps (e.g. TrueNAS disks)
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

## Run Node Exporter on Asustor NAS

This can be slightly picky across host reboots/upgrades.  The commands below will reliably get things back to a good state.

Cleanup existing container:

```bash
sudo docker rm node_exporter
```

Run Node Exporter:

```bash
sudo docker run -d --name node_exporter -p 9100:9100 --restart unless-stopped prom/node-exporter
```

---

## Restore a Postgres DB Dump

### Authentik

```bash
docker exec -i authentik-postgresql-1 pg_restore \
  -U authentik \
  -d authentik \
  --clean --if-exists \
  --no-owner --no-privileges \
  --exit-on-error \
  < /var/lib/postgres-db-dumps/authentik-20260507-050020.dump
```

### Immich

```bash
docker exec -i immich_postgres pg_restore \
  -U postgres \
  -d immich \
  --clean --if-exists \
  --no-owner --no-privileges \
  --exit-on-error \
  < /var/lib/postgres-db-dumps/immich-xxx.dump
```