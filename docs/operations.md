# Operations Reference

This document describes how to operate Allan's Home Lab on a day-to-day
basis.

It focuses on:

-   What commands exist
-   When to run them
-   How layers interact operationally
-   Common execution patterns

It does not deeply explain persona architecture or lifecycle theory. For
that, see `docs/personas.md`.

This page assumes you have read the main README and understand the
L0--L4 layered model.

------------------------------------------------------------------------

# Operational Model

## Using Just as the Entry Point

All operational workflows are executed through the Justfile.

Terraform, Ansible, and supporting scripts are not typically invoked
directly. Instead, they are wrapped in Just recipes that:

-   Enforce consistent environment configuration
-   Reduce command complexity
-   Provide predictable entry points
-   Maintain alignment with the layered model

Using Just as the single operational interface reduces cognitive
overhead and prevents ad-hoc execution paths from developing over time.

------------------------------------------------------------------------

## Layer-Oriented Execution

Operations are organized by infrastructure layer:

-   **L0** --- Environment validation
-   **L1** --- Template creation
-   **L2** --- VM instantiation
-   **L3** --- OS convergence
-   **L4** --- Workload convergence

Each layer has a defined responsibility. When running commands:

-   Avoid skipping layers unless intentional.
-   Avoid mixing responsibilities across layers.
-   Prefer full layer execution over partial mutation.

The expected pattern is progressive:

1.  Validate environment (L0)
2.  Build or update templates (L1, when required)
3.  Apply infrastructure changes (L2)
4.  Converge system state (L3)
5.  Converge workloads (L4)

Higher layers assume lower layers are already correct.

------------------------------------------------------------------------

# Prerequisites

Before running any layer of the orchestration stack, certain
prerequisites must be satisfied locally. These ensure the tooling can
authenticate to infrastructure providers and target the correct
environment.

------------------------------------------------------------------------

## Required Environment Variables

The following environment variables must be set for
infrastructure-related operations (particularly L1 and L2):

-   `PVE_ACCESS_HOST`\
    Proxmox API endpoint (e.g. `pve.example.com`)

-   `PM_TOKEN_ID`\
    Proxmox API token ID (e.g. `gitops@pve!gitops`)

-   `PM_TOKEN_SECRET`\
    Proxmox API token secret

-   `PVE_NODE`\
    Target Proxmox node name (e.g. `polaris`)

-   `PVE_STORAGE_VM`\
    Proxmox storage identifier for VM disks (e.g. `local-lvm`)

These variables are validated early in the workflow and execution will
fail if any are missing.

------------------------------------------------------------------------

## Secrets Management (Doppler)

By default, all Just commands are executed through Doppler to populate
required environment variables.

A call such as:

``` bash
just <target>
```

will execute with Doppler injecting environment variables automatically.

This is the recommended and supported execution model.

### Skipping Doppler

To bypass Doppler injection, set:

``` bash
DOPPLER=0 just <target>
```

This disables the automatic Doppler wrapper and runs the target with
whatever environment variables are already present in your shell.

This is useful for:

-   CI environments
-   Custom secret injection mechanisms
-   Debugging scenarios

Additional mechanisms exist to control Doppler behavior. Refer to the
Justfile for the authoritative implementation details.

------------------------------------------------------------------------

## Stable Manifest Behavior

By default, L1 tasks that upload ISOs and templates update the stable
manifest reference to point at the newly built artifact manifest.

To disable this behavior, set:

``` bash
UPDATE_STABLE=no
```

Any value other than `yes` will prevent the stable manifest from being
updated.

This allows controlled promotion of templates without automatically
advancing the stable reference.

