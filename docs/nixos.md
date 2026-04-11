# NixOS

## Quick Start : Create a NixOS VM

This walkthrough shows the full lifecycle of creating and converging a NixOS VM using the `todash` host as an example.

It assumes:
- Proxmox is reachable
- Required credentials are already in place
- You are running commands from the repo root

---

### 1. Create a NixOS VM Template

Build and register a reusable NixOS template in Proxmox:

```bash
just nixos-vm-template
```

This produces the base image used for all NixOS VMs and records its details in a JSON manifest for later use.

---

### 2. Define the Host in Inventory

Hosts are defined in [`inventory/hosts/`](../inventory/hosts/) as TOML.

Example: [`inventory/hosts/todash.toml`](../inventory/hosts/todash.toml)

```toml
name = "todash"
hostname = "todash"

platform = "nixos"
variant = "nixos"

[management]
provisioner = "terraform"
converger = "nixos"

[runtime]
kind = "vm"
hypervisor = "proxmox"
node = "maturin"
```

This file is the source of truth for:
- VM provisioning (Terraform)
- NixOS configuration inputs
- Host-level metadata

---

### 3. Add Host to the NixOS Flake

Each host must be registered in the main flake.

Example: [`nixos/flake.nix`](../nixos/flake.nix)

```nix
  {
    nixosConfigurations = {
      cujo = mkHost ./hosts/cujo;
      flagg = mkHost ./hosts/flagg;
      langolier = mkHost ./hosts/langolier;
      roland = mkHost ./hosts/roland;
      todash = mkHost ./hosts/todash;
    };
  };
```

This wires the host into the NixOS build system.

---

### 4. Create the VM (Terraform)

Provision the VM in Proxmox:

```bash
just terraform todash apply 1
```

- Use `0` instead of `1` for a dry run
- This step creates the VM from the template defined earlier

---

### 5. Converge the Host (NixOS)

Build and deploy the system configuration:

```bash
just nixos-switch todash
```

This performs a remote build and switches the host to the desired state.

This uses remote builds — artifacts are built on the target host, not locally.

---

### 6. Validate the Host

Confirm the system is up and exporting metrics:

```
http://<ip>:9100/metrics
```

If this endpoint responds, the host is:
- reachable
- successfully converged
- running baseline services

Node Exporter is enabled by default via shared modules.

---

### Summary

This flow represents the standard lifecycle for NixOS VM management:

1. Build template  
2. Define host  
3. Register in flake  
4. Provision VM  
5. Deploy configuration  
6. Validate  

---

## Mental Model

NixOS management in this repo follows a consistent pattern:

1. Define the host in [`inventory/hosts/`](../inventory/hosts/)
2. Expose the host through [`nixos/flake.nix`](../nixos/flake.nix)
3. Provision the machine if it does not already exist
4. Run a remote NixOS build and switch the host to the declared state

The important distinction is that this repo separates **host definition**, **host existence**, and **host convergence**.

- Inventory answers: *what is this host?*
- Terraform answers: *does this VM exist in Proxmox?*
- NixOS answers: *is the operating system configured correctly?*

That separation keeps VM creation, OS convergence, and later rebuilds from collapsing into one opaque workflow.

Remote builds are the default. In normal operation, the target host performs the build and applies the resulting system. That keeps the operator machine simple and makes the workflow consistent whether the target is a VM or bare metal.

---

## VM Lifecycle

### Create a New VM

Creating a new NixOS VM usually means working through the same sequence shown in the quick start:

1. Build or refresh the NixOS VM template
2. Add a new host entry in [`inventory/hosts/`](../inventory/hosts/)
3. Register the host in [`nixos/flake.nix`](../nixos/flake.nix)
4. Provision the VM with Terraform
5. Converge it with `just nixos-switch <host>`

In practice, this means:

- Terraform handles the VM shell: CPU, memory, disks, networking, and template selection
- NixOS handles the system state after the machine exists
- Inventory provides the host-specific inputs both sides consume

For most new hosts, the first successful `nixos-switch` is the moment the machine becomes meaningfully usable. Before that, it exists, but it is not yet converged into the expected system state.

### Update an Existing VM

Most day-to-day NixOS work falls into this category.

Typical changes include:

- adding or removing packages
- changing services
- updating shared modules
- adjusting host-level options
- modifying inventory-backed values used by host configuration

These changes usually do **not** require reprovisioning the VM. The normal workflow is simply:

```bash
just nixos-switch <host>
```

This is the preferred path whenever the machine already exists and only the desired system state has changed.

As a rule of thumb:

- If the change is **inside the OS**, use `nixos-switch`
- If the change is **about the VM itself** (resources, disks, base template, low-level VM shape), Terraform may also need to be involved

### Rebuild a VM

There are two kinds of rebuilds in practice.

#### Soft rebuild

A soft rebuild keeps the existing VM and reapplies the NixOS configuration:

```bash
just nixos-switch <host>
```

This is appropriate when:

- the host exists
- disks are intact
- you are correcting configuration drift
- you are iterating on modules or services

#### Full rebuild

A full rebuild destroys and recreates the VM, then converges it again.

The exact Terraform command depends on what you are doing operationally, but the high-level flow is:

1. Destroy or replace the existing VM
2. Recreate it from the current template
3. Re-run `just nixos-switch <host>`

Use this when:

- the base image or template changed materially
- the VM definition changed in a way that is cleaner to recreate than mutate
- the host has accumulated enough drift or damage that starting clean is faster
- you want to validate that the host really is reproducible from declared state

The project is intentionally biased toward rebuildability. If a host can be recreated cleanly from inventory, Terraform, and NixOS config, that is a success condition, not a disaster recovery edge case.

---

## Bare Metal Hosts

Bare metal hosts follow the same overall model as VMs, but require an initial bootstrap step before the repo can take over management.

### Initial Bring-Up

The preferred way to bootstrap a bare metal host is to generate a custom NixOS install ISO using the provided Just command:

```bash
just nixos-iso <hostname> <disk> <iface> <ip>
```

Example:

```bash
just nixos-iso roland /dev/nvme0n1 eth0 192.168.86.100/24
```

This command:

- Builds a custom NixOS ISO tailored for the target host
- Embeds host-specific configuration (hostname, networking, disk target)
- Writes the ISO to a USB device for installation

Once the ISO is created:

1. Boot the target machine from the USB device
2. Allow the installer to run without manual intervention

The system will:

- Partition and format the target disk
- Install NixOS
- Apply initial configuration
- Reboot into a ready-to-use system

After installation completes, the host will be:

- reachable on the configured IP address
- accessible via SSH
- configured with a `lab` operator user
- provisioned with known SSH keys

At this point, the system is in a minimal but functional state and ready to be managed by the repo.

---

### Converting to a Managed Host

Once the host is reachable and booted, the remaining steps align closely with the VM workflow:

1. Define the host in [`inventory/hosts/`](../inventory/hosts/)
2. Register the host in [`nixos/flake.nix`](../nixos/flake.nix)
3. Ensure the host-specific configuration exists under [`nixos/hosts/`](../nixos/hosts/)
4. Run:

```bash
just nixos-switch <host>
```

This step transitions the machine from a bootstrap-installed system to a fully managed NixOS host.

From this point forward:

- The host is treated the same as any VM
- Configuration changes are applied via `nixos-switch`
- The system is expected to converge to the declared state in the repo

The bootstrap ISO is only responsible for getting the machine to a known starting point. All long-term configuration and lifecycle management is handled through the standard NixOS workflow.

---

### Rebuild Considerations

Bare metal rebuilds follow the same general pattern as VM rebuilds, but require additional care due to physical hardware.

Things to verify when rebuilding:

- Disk identifiers (e.g. `/dev/nvme0n1`) are still correct
- Network interface names have not changed
- Bootloader configuration matches the target disk
- `hardware-configuration.nix` reflects the current system

If any of these drift from reality, rebuilds can fail in ways that look like NixOS issues but are actually hardware mismatches.

When in doubt, regenerate the hardware configuration and revalidate the assumptions before re-running `nixos-switch`.

---

## Inventory → NixOS Mapping

One of the more important ideas in this repo is that host intent starts in inventory, not in scattered tool-specific files.

Hosts are defined in TOML under [`inventory/hosts/`](../inventory/hosts/). Those definitions are then used to generate or drive the inputs needed by the downstream tools.

For NixOS, that means inventory is not the entire system configuration by itself. Instead, it provides the host metadata and declared intent that the NixOS side consumes.

Typical examples of inventory-owned data include:

- host identity
- platform / variant
- whether the host is a VM or bare metal system
- which provisioning path it uses
- which hypervisor or node it belongs to

The NixOS side then combines that host-level data with:

- host-specific files under [`nixos/hosts/`](../nixos/hosts/)
- shared modules
- shared profiles
- flake wiring in [`nixos/flake.nix`](../nixos/flake.nix)

A useful mental model is:

**inventory defines the host**,  
**the flake exposes the host**,  
**the host modules implement the host**.

That split makes it easier to reason about where a given value should live and helps prevent the same concept from being hand-maintained in multiple tools.

---

## Secrets Handling

Secrets in this project are managed using `sops-nix`, with encrypted files stored directly in the repository and decrypted at runtime on the target host.

### Where Secrets Live

All encrypted secret files are located under:

- [`nixos/secrets/`](../nixos/secrets/)

These files are committed to the repo in encrypted form and are safe to version control.

---

### Editing and Managing Secrets

The SOPS private key used for encryption and decryption is stored in Doppler.

In practice, this means most secret management operations are performed using `doppler run` to inject the key at runtime.

A typical command to create or edit a secret file looks like:

```bash
doppler run -- sops nixos/secrets/secret.yaml
```

This ensures:
- the private key is not stored locally on disk
- secrets can be safely edited without manual key management
- the workflow remains consistent across environments

---

### How Secrets Are Used

Secrets are decrypted and materialized on the host via `sops-nix` during system activation.

They are not stored in the Nix store. Instead, they are written to controlled locations on the filesystem with explicit ownership and permissions.

Common destination patterns:

- `/run/secrets` — runtime-only, ephemeral secrets
- `/var/lib/homelab-secrets` — durable, host-local secrets

---

### Things to Verify When Debugging

If a secret is not working as expected, check:

- the correct SOPS file is referenced
- the secret is defined in [`nixos/secrets/`](../nixos/secrets/)
- the destination path on the host is correct
- file ownership and permissions are correct
- the consuming service is pointing to the correct path

---

### Design Notes

Secrets are intentionally kept separate from normal system configuration.

- NixOS defines *how* secrets are used
- SOPS defines *what* the secret values are
- Doppler provides secure access to the decryption key

This separation keeps sensitive data out of the Nix store while still allowing secrets to be managed declaratively.

---

## Operational Patterns

There are a few recurring patterns that are worth making explicit.

### `nixos-switch` Is the Primary Day-to-Day Command

For an already-existing host, most normal changes are applied with:

```bash
just nixos-switch <host>
```

That is the common path for service changes, module changes, package changes, and most host configuration updates.

### Terraform and NixOS Serve Different Purposes

It is useful to keep these roles separate in your head:

- Terraform creates or mutates the VM as infrastructure
- NixOS converges the operating system running inside it

If something changed about the VM definition itself, Terraform may be involved. If something changed about the operating system, NixOS is the main tool.

### Favor Repeatable Commands Over Manual Repair

This repo is designed around repeatability. If something drifts, the preferred response is usually to re-run the declared workflow rather than hand-edit the machine until it seems fine.

That does not mean manual debugging never happens. It means the end state should still be brought back under declarative control.

---

## Troubleshooting

When a NixOS host does not behave as expected, the first step is to identify which layer is failing:

- provisioning
- connectivity
- build
- activation
- runtime service behavior

A few checks go a long way.

### Terraform / Provisioning Problems

If the VM does not exist or does not look correct in Proxmox, start with the Terraform path first. NixOS cannot converge a host that was never created correctly.

### Connectivity Problems

Before chasing Nix config, confirm that the host is reachable over the network and that SSH access works. Many apparent “NixOS problems” are actually basic connectivity problems.

### Build or Switch Problems

If `just nixos-switch <host>` fails, read the build output carefully and determine whether the failure is happening during:

- evaluation
- build
- activation

Those stages usually imply different fixes.

### Service Problems After a Successful Switch

If the build and switch succeeded but the service is still broken, check standard systemd and journald outputs on the target host:

```bash
systemctl status <service>
journalctl -u <service> -e --no-pager
```

For system-wide investigation:

```bash
journalctl -xe --no-pager
```

### Metrics Validation

Because Node Exporter is enabled by default, `http://<ip>:9100/metrics` is a useful quick validation step after convergence. It is not the only check, but it is a good baseline signal that the machine is up and core services are running.

---

## Gotchas / Notes

A few recurring sharp edges are worth calling out explicitly.

### Dirty Git Tree Warnings

It is common to see warnings about a dirty git tree during flake evaluation. That is usually informational, but it is still a reminder that you are building from a working tree state, not a clean committed revision.

### Remote Sudo Warnings

Depending on the exact host and NixOS version, you may see warnings around remote sudo usage or deprecated flags. Treat those as signals to clean up workflow details over time, but not necessarily as the root cause of the current problem.

### Hardware Configuration Drift

For bare metal especially, stale hardware config can cause confusing failures. If disks, interfaces, or boot targets changed, revisit the generated hardware configuration before assuming the problem is elsewhere.

### Successful Provisioning Is Not Successful Convergence

A VM existing in Proxmox only means the infrastructure step worked. It does not mean the system is configured. The host is not “done” until `nixos-switch` succeeds and the machine validates cleanly.
