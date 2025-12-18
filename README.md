# Allan's Home Lab

## Project Overview

This repository implements a **layered, GitOps-style homelab orchestration stack** designed to reliably build, provision, converge, and operate infrastructure from bare metal up to fully configured services.

### Core Goals

- **Reproducibility**  
  Any machine, VM, or service can be rebuilt entirely from source.

- **Separation of concerns**  
  Image building, infrastructure provisioning, OS configuration, and runtime orchestration are clearly isolated.

- **Incremental trust**  
  Each layer validates its assumptions before allowing the next layer to proceed.

- **Local ↔ CI parity**  
  The same workflows can be run from a laptop, an operations VM, or a self-hosted CI runner.

- **Human-operable**  
  Every layer can be run manually, inspected, and debugged without relying on hidden or implicit behavior.

### Layered Architecture

The system is structured into **five layers (L0–L4)**, with each layer has a narrow, well-defined set of responsibilities.

## L0 – Runway / Environment Validation

**Purpose:**  
Ensure the execution environment is safe, correctly configured, and capable of running the rest of the orchestration stack.

L0 acts as a *runway check* before any infrastructure is built or modified. Its job is to fail fast and loudly if prerequisites are missing or if the execution context is incorrect.

### Responsibilities

L0 is responsible for validating and establishing the baseline execution context, including:

- Verifying required tooling is installed and available (e.g. Packer, Terraform, Ansible, jq)
- Ensuring credentials, tokens, and secrets are present and readable
- Confirming access to target systems (e.g. Proxmox API, SSH connectivity)
- Validating environment variables and configuration inputs
- Establishing shared defaults used by downstream layers
- Preventing accidental execution against the wrong environment or target

### What L0 Does *Not* Do

L0 does **not**:

- Build images
- Create or destroy infrastructure
- Modify hosts or services
- Apply configuration to remote systems

No persistent changes are made during L0 execution.

### Outputs

L0 produces no infrastructure artifacts. Its only outputs are:

- Verified assumptions about the execution environment
- Exported or normalized environment variables for downstream layers
- Early failure if any prerequisite or safety check is not satisfied

### Why L0 Exists

By enforcing correctness and safety up front, L0 prevents:

- Partially executed runs due to missing tools or credentials
- Accidental changes to the wrong environment
- Time-consuming failures deep into provisioning or convergence steps

If L0 succeeds, downstream layers can proceed with a high degree of confidence.

