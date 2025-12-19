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

## L1 – Image & Template Build

**Purpose:**  
Produce reproducible, versioned operating system images that serve as the immutable foundation for all provisioned hosts.

L1 is responsible for building *golden images* using a controlled, automated process. These images encapsulate everything that is expensive, slow, or error-prone to configure repeatedly on live systems.

### Responsibilities

L1 focuses exclusively on image-level concerns, including:

- Building OS images and VM templates (e.g. via Packer)
- Installing the base operating system
- Configuring bootloaders and early system configuration
- Installing cloud-init, guest agents, and required drivers
- Applying image-wide defaults that are common to all future hosts
- Producing versioned, immutable artifacts suitable for reuse
- Capturing build metadata and manifests for traceability

L1 does **not** include host-specific configuration or workload logic.

### What L1 Does *Not* Do

L1 does **not**:

- Create or manage infrastructure resources
- Assign hostnames, IPs, or roles
- Configure users, services, or security policy
- Deploy applications or runtime workloads
- Perform OS convergence or drift correction

Anything that may vary per host or persona is intentionally deferred to later layers.

### Outputs

L1 produces concrete, reusable artifacts, such as:

- VM templates or bootable ISOs
- Image identifiers or references
- Build manifests and metadata
- “Stable” and/or versioned image pointers for downstream layers

These outputs are consumed directly by L2 during infrastructure provisioning.

### Why L1 Exists

By baking common OS concerns into images, L1:

- Reduces provisioning and convergence time
- Eliminates configuration drift introduced during live setup
- Improves rebuild reliability and repeatability
- Creates a clear audit trail from image build to deployed host

If L1 succeeds, downstream layers can assume a known-good operating system baseline.

## L2 – Infrastructure Provisioning

**Purpose:**  
Declaratively provision infrastructure resources from version-controlled specifications.

L2 is responsible for creating and managing infrastructure based on intent defined in code. It turns image artifacts produced by L1 into running machines and supporting resources, without applying any host-level configuration or workload logic.

### Responsibilities

L2 focuses on infrastructure-level concerns, including:

- Reading host and persona specifications from structured definitions
- Provisioning virtual machines and related resources (e.g. via Terraform)
- Attaching L1-built images or templates to provisioned hosts
- Defining static resource characteristics (CPU, memory, disk, networking)
- Applying metadata such as names, tags, and grouping information
- Managing infrastructure lifecycle (create, update, destroy)
- Producing machine-addressable outputs for downstream layers

L2 answers the question: *“What infrastructure exists?”*

### What L2 Does *Not* Do

L2 does **not**:

- Configure operating systems or install packages
- Manage users, services, or security policy
- Deploy applications or workloads
- Perform OS convergence or drift correction
- Make assumptions about how a host will be used at runtime

All host behavior is intentionally deferred to L3 and beyond.

### Outputs

L2 produces infrastructure state and metadata, such as:

- Running (but minimally configured) hosts
- IP addresses, hostnames, and unique identifiers
- Generated inventories or host lists
- Terraform state and outputs

These outputs are consumed by L3 to perform OS convergence.

### Why L2 Exists

By isolating infrastructure provisioning into its own layer, L2:

- Makes infrastructure changes explicit and reviewable
- Enables safe iteration on host shape without touching OS config
- Allows infrastructure to be rebuilt or destroyed independently
- Cleanly separates “what exists” from “how it behaves”

If L2 succeeds, downstream layers can assume that required infrastructure is present and reachable.

## Layer Dependency Model

The orchestration stack is intentionally **linear**: each layer depends only on the layers below it, and produces outputs consumed by the layers above it.

### Dependency Chain

```
L0  →  L1  →  L2  →  L3  →  L4
```

### What Flows Between Layers

* **L0 → L1:** Verified local tooling, credentials, and target context (safe to proceed)
* **L1 → L2:** Image and template references plus build metadata (e.g. stable template IDs)
* **L2 → L3:** Provisioned hosts and addressing information (inventory, SSH endpoints, host identifiers)
* **L3 → L4:** Converged hosts with required runtime capabilities installed and enabled

### Allowed Execution Patterns

* **Independent iteration**

  * Re-run **L3** repeatedly while refining OS convergence
  * Re-run **L4** repeatedly while iterating on application deployment

* **End-to-end rebuilds**

  * Run **L0 → L4** to go from a clean environment to a fully operational system

### Design Constraints

* A layer may **consume outputs** from lower layers, but must not require higher layers to have run.
* Layers should be **idempotent** where practical and safe to re-run.
* Responsibilities must not leak downward (e.g. L4 must not install OS packages or mutate base system state).

This dependency model keeps failures localized, rebuilds predictable, and each layer understandable in isolation.
