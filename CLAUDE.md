# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A GitOps homelab: NixOS hosts (primary), appliance VMs (Home Assistant, TrueNAS) and legacy Arch/Ubuntu VMs, all driven from a TOML inventory, plus 3D-printed rack hardware as OpenSCAD source. The `Justfile` is the entry point for every workflow; `just --list` shows the recipes. Detailed docs live in `docs/` (`nixos.md`, `appliances.md`, `linux.md`, `hardware.md`, `operations.md`).

## Commands

```bash
just all-inventory-build              # validate inventory TOML against the schema and render .build/inventory/
just all-terraform <host> apply 0     # Terraform dry run; 1 applies (also: destroy)
just nixos-check <host>               # check a host's flake config without touching the host
just nixos-test <host>                # remote build + temporary activation
just nixos-switch <host>              # remote build + permanent switch
just linux-converge "<tags>" "<host>" # Ansible converge of legacy Linux hosts
just hw-render [path] [yes]           # render OpenSCAD to STL (and PNG with "yes") under hardware/build/
```

- Most recipes run under `doppler run --` for secrets. Set `DOPPLER=0` to run without Doppler; in CI (`CI=true`) Doppler is skipped unless `FORCE_DOPPLER=1`.
- Recipes that need host data depend on `all-inventory-build`, which needs `uv` (it runs `uv run --with jsonschema`).
- There is no test suite or linter; validation is the inventory schema check, `nixos-check`, Terraform dry runs and, for hardware, a clean render.

## Architecture

**Inventory is the source of truth.** Each host is `inventory/hosts/<host>.toml`, validated against `inventory/schemas/host.schema.json`. `shared/scripts/render-inventory.py` renders tool-specific JSON into `.build/inventory/{terraform,ansible,proxmox}/` (gitignored). Tools consume that derived state rather than owning host config.

The repo separates three questions:
- Inventory: what is this host?
- Terraform (`shared/terraform/`, Proxmox): does the VM exist?
- NixOS / Ansible: is the OS configured correctly?

**NixOS** (`nixos/`):
- `flake.nix` defines every host with `mkHost "<name>" { }`. `mkHost` reads the host's inventory TOML directly and passes values such as `hostName`, `hostInterface`, `hostIp4Address`, `hostIp4Gateway`, `hostDns` and `nixosVersion` to modules as `specialArgs`. Per-host overrides (e.g. `deneb` on nixpkgs-unstable) go in the `mkHost` argument set.
- A new host needs an inventory TOML, a `mkHost` entry and `nixos/hosts/<host>/{default.nix,hardware-configuration.nix}`. For bare metal, `converge.sh` fetches the hardware config from the host; for VMs it comes from `nixos/template/`. A switch can therefore change files that need committing.
- `modules/` are reusable building blocks, including the `bare-metal` / `virtual-machine` bases and custom `homelab.*` options under `modules/homelab-modules/`. `profiles/` are service bundles that hosts import. Host `default.nix` files compose profiles and modules.
- Builds are remote: `nixos/scripts/converge.sh` reads the target IP from `.build/inventory/terraform/<host>.json` and builds on the target host.
- Secrets use sops-nix with an age key; `.sops.yaml` encrypts `*.yaml` and `*.env` files. Edit them with `just nixos-sops-secret <file>`.

**Appliances** (`appliance/`) follow a different lifecycle: capture the boot disk to S3, turn it into a Proxmox template, then provision with Terraform. They have minimal post-provisioning convergence.

## Hardware (OpenSCAD)

- **Tooling:** use the OpenSCAD development snapshot (`brew install --cask openscad@snapshot`) with `--backend=manifold`. `hardware/scripts/render.sh` puts `hardware/lib` on `OPENSCADPATH`. Every `.scad` outside `lib/`, `reference/` and `build/` is a printable model, and the render output mirrors its path under the gitignored `hardware/build/`.
- **Shared library:** `lib/rack10.scad` holds the rack geometry. `rack_panel(u) { 2D cutouts }` builds a panel from cutouts drawn as seen from the front. `rack_front() { ... }` mirrors 3D geometry so it can also be modelled as seen from the front. Panels are modelled front face down at Z=0, with the rear toward +Z and Y up the panel. Fit-critical constants live in `lib/`, so a fix there reaches every part; validate changes to `rack10.scad` by printing `rack-10in/panel-skeleton.scad`. `lib/vents.scad` has the hex and diamond vent patterns, and `lib/keystone.scad` the keystone openings and housings.
- **Device libraries:** a device library such as `lib/zimaboard2.scad` is shared by a fit-test mock-up and the final part, so fit changes made on the mock-up carry over. It reads `floor_thickness`, so the including file must set that variable *before* the `include` line, because OpenSCAD evaluates top-level variables in order.
- **Part conventions:**
  - Units are mm.
  - Every part has a header comment recording print orientation, supports and material.
  - Tunable values are top-level variables.
  - Files are named `<kind>-<variant>.scad`.
  - Cut text uses the stencil font in `hardware/fonts/`, with bridges at least ~1.2 mm wide.
- **Printing:** the printer is a Bambu Lab P2S; the rack is a DeskPi RackMate T2 (10"). PETG is the default material for rack parts; PLA is for test prints only. 1U panels use only the top and bottom screw-hole pairs. Parts print face down without supports, so keep overhangs at 45° or steeper. Avoid tall, thin columns that stand on their own in the print, because they wobble and fail.
- **Reference models:** third-party models in `hardware/reference/` are gitignored, because their licences usually forbid redistribution. Record each one's source and licence in `hardware/reference/README.md`. They're for measurement only; parts are rebuilt from scratch.
