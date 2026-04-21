# Allan's Home Lab

## Overview

A GitOps-driven homelab centered on NixOS host management, with supporting workflows for appliance and legacy VMs — all driven from a unified TOML inventory.

---

## Documentation

- **[NixOS](docs/nixos.md)**  
  End-to-end management of NixOS hosts, including VM and bare metal workflows, rebuild strategies, and secrets handling.

- **[Appliances](docs/appliances.md)**  
  Managing Home Assistant and TrueNAS VMs using disk capture, templates, and Terraform-driven lifecycle.

- **[Linux VMs](docs/linux.md)**  
  Arch and Ubuntu virtual machines provisioned with Terraform and configured using Ansible.

- **[Operations](docs/operations.md)**  
  Command reference and common workflows for running and maintaining the homelab.

---

## What This Project Does

This project provides a structured system for managing homelab infrastructure with a strong emphasis on reproducibility and rebuildability.

Core capabilities:

- NixOS remote build and deployment (bare metal and virtual machines)
- Appliance VM lifecycle management using Proxmox and Terraform
- Legacy Linux VM management using Ansible (non-production use)
- Inventory-driven configuration generation (TOML → tool-specific configs)

---

## Core Model

This project is built around two core ideas: separation of concerns and inventory-driven design.

### Separation of Concerns

Infrastructure is intentionally split into distinct areas:

- Infrastructure: virtual machines, disks, networking
- System: operating system configuration (primarily NixOS)
- Workloads: applications and services running on hosts

Each area has a clear responsibility and avoids overlap. This keeps systems easier to reason about and rebuild.

### Inventory-Driven Design

All host definitions live in the [`inventory/`](inventory/) directory as TOML files.

- The inventory is the single source of truth
- Tool-specific configurations (Terraform, Ansible, NixOS inputs) are generated from it
- No tool owns configuration — they consume derived state

This ensures consistency across systems and prevents configuration drift between tools.

---

## Primary Focus: NixOS Host Management

The primary focus of this project is managing hosts using NixOS.

Hosts are defined in the inventory and rendered into NixOS configurations, which are then built and deployed remotely.

This applies to:

- Bare metal systems
- Proxmox virtual machines

Key characteristics of this approach:

- Declarative system configuration
- Remote builds and deployments
- Rebuild-first workflows instead of manual mutation
- Minimal per-host drift over time

The goal is to make rebuilding a host straightforward, predictable, and preferred over debugging configuration drift.

For more details, see:

- [`nixos/`](nixos/)
- [`docs/nixos.md`](docs/nixos.md)

---

## Appliance VM Management (Proxmox + Terraform)

Appliance VMs are managed separately from NixOS hosts and live under the [`appliance/`](appliance/) directory.

These include systems such as:

- Home Assistant
- TrueNAS
- Other specialized, non-NixOS workloads

Typical workflow:

- Export or capture boot disks from existing systems
- Convert disks into reusable templates
- Use Terraform with Proxmox to instantiate and manage VMs

This approach treats appliances as reproducible infrastructure while respecting their need to run outside the NixOS model.

For more details, see:

- [`docs/appliances.md`](docs/appliances.md)

---

## Legacy Linux VM Management (Ansible)

Legacy Linux hosts (primarily Arch and Ubuntu) are managed under the [`linux/`](linux/) directory using Ansible.

These systems are retained for:

- Experimentation
- Compatibility testing
- Non-critical workloads

This is no longer the primary approach for managing infrastructure. NixOS has replaced it for most production use cases.

For more details, see:

- [`docs/legacy.md`](docs/legacy.md)

---

## Operations & Tooling

The project is operated through a combination of:

- The [`Justfile`](Justfile) as the primary interface
- Supporting scripts located alongside the features they support
- Tool-specific workflows (NixOS rebuilds, Terraform applies, Ansible runs)

A typical flow looks like:

1. Update inventory
2. Generate or render configuration
3. Apply changes using the appropriate tool

Commands are intentionally routed through the Justfile to keep workflows consistent.

For more details, see:

- [`docs/operations.md`](docs/operations.md)

---

## Repository Structure

The repository is organized around the core areas of responsibility:

- [`inventory/`](inventory/) — Source of truth (TOML host definitions)
- [`nixos/`](nixos/) — NixOS configurations and modules
- [`appliance/`](appliance/) — Appliance VM workflows and definitions
- [`linux/`](linux/) — Legacy Ansible-based systems
- [`shared/`](shared/) — Cross-cutting logic and templates
- [`docs/`](docs/) — Detailed documentation
- [`Justfile`](Justfile) — Operational entry point

---

## Documentation

The README provides a high-level overview.

For more detailed information:

- NixOS → [`docs/nixos.md`](docs/nixos.md)
- Appliances → [`docs/appliances.md`](docs/appliances.md)
- Legacy → [`docs/legacy.md`](docs/legacy.md)
- Operations → [`docs/operations.md`](docs/operations.md)
- Notes → [`docs/notes.md`](docs/notes.md)

Start here for context, then move into the relevant section based on what you are trying to do.

---

## Design Principles

- Git is the source of truth
- Inventory drives all configuration
- Rebuild over mutation
- Clear separation of concerns

The system is designed to make infrastructure predictable, repeatable, and easy to rebuild.
