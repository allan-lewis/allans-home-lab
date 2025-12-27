# Allan's Home Lab

## Documentation

- [How-To Guides](docs/how-to.md)
- [Full Build](docs/full-build.md)
- [Misc](docs/random-notes.md)

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

## L3 – OS Convergence

**Purpose:**  
Converge provisioned hosts into a consistent, policy-compliant operating system state based on OS and persona.

L3 is responsible for transforming a newly provisioned machine into a predictable, trustworthy host. It applies all operating-system-level configuration and enables host capabilities, while remaining intentionally unaware of any specific application workloads.

### Responsibilities

L3 focuses on host-level concerns, including:

- Applying OS-specific baselines (e.g. Ubuntu vs Arch)
- Installing and configuring system packages
- Managing users, groups, and SSH access
- Enforcing security and hardening policies
- Configuring system services and daemons
- Installing monitoring and metrics agents
- Installing backup frameworks (scheduling, logging, rotation)
- Enabling runtime capabilities based on persona (e.g. Docker engine)
- Establishing standardized directory structures and permissions

L3 answers the question: *“What kind of machine is this?”*

### What L3 Does *Not* Do

L3 does **not**:

- Deploy application workloads or services
- Manage application configuration or data
- Define backup targets or application-specific fragments
- Expose user-facing functionality
- Perform runtime orchestration or health validation

Anything that represents a concrete workload or service belongs to L4.

### Personas and Capabilities

Personas are applied at L3 to define **capabilities**, not workloads.  
Examples include:

- A host capable of running Docker Compose workloads
- A Kubernetes node with container runtime and kubelet installed
- A VPN gateway with appropriate kernel and firewall configuration

Personas may enable or disable capabilities selectively, but they do not imply that any application is actually running.

### Outputs

L3 produces fully converged hosts that are:

- Reachable and consistently configured
- Idempotent and safe to re-run
- Equipped with declared runtime capabilities
- Ready for workload deployment

These hosts are consumed directly by L4 for application orchestration.

### Why L3 Exists

By isolating OS convergence and capability enablement into L3, the system:

- Prevents application logic from mutating base system state
- Enables safe host rebuilds without entangling workloads
- Keeps OS policy centralized and auditable
- Establishes a clean contract between infrastructure and applications

If L3 succeeds, downstream layers can assume a stable, well-understood host substrate.

## L4 – Runtime Orchestration & Validation

**Purpose:**  
Deploy, manage, and validate application workloads on converged hosts.

L4 is responsible for everything that turns a capable host into a *useful system*. It applies workload-specific configuration, deploys services, and validates that those services are operating as intended.

Unlike earlier layers, L4 is explicitly **stateful** and **workload-aware**.

### Responsibilities

L4 focuses on runtime and application-level concerns, including:

- Deploying application workloads (e.g. Docker Compose stacks, Kubernetes manifests)
- Managing application configuration and secrets
- Creating and managing application data directories and volumes
- Applying application-specific backup fragments
- Configuring ingress, routing, and service exposure
- Applying workload-aware networking and policy (e.g. VPN routing rules)
- Performing runtime validation and health checks
- Restarting, upgrading, or removing application stacks

L4 answers the question: *“What is this system currently running?”*

### What L4 Does *Not* Do

L4 does **not**:

- Install or configure base operating system packages
- Modify OS-level security or hardening policy
- Install runtime substrates (e.g. Docker engine, container runtime)
- Assume responsibility for host identity or baseline correctness

L4 consumes capabilities established by L3, but must not redefine them.

### Execution Characteristics

- L4 is designed to be **safe to re-run** as applications change
- L4 may be run independently of earlier layers when iterating on workloads
- Failures in L4 should not compromise host integrity

### Outputs

L4 produces:

- Running application services
- User-facing functionality
- Runtime state and data
- Health and observability signals

If L4 succeeds, the system is not just provisioned — it is operational.

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

## Capability vs Workload

A central design principle of this orchestration stack is the strict separation between **capabilities** and **workloads**.

This distinction defines the boundary between **L3** and **L4**, and is critical to maintaining a system that is safe to rebuild, reason about, and evolve over time.

### Capabilities (L3)

Capabilities describe what a host *can do*.

They are properties of the operating system and its substrate, and are expected to be stable, repeatable, and safe to apply broadly.

Examples of capabilities include:

- Operating system baseline configuration
- Users, groups, and SSH access
- Security and hardening policy
- Monitoring and metrics agents
- Backup frameworks (scheduling, logging, execution)
- Container runtimes (e.g. Docker engine)
- Kernel and networking prerequisites (e.g. IP forwarding)
- Persona-based enablement of host features

Capabilities answer the question:  
**“What kind of machine is this?”**

### Workloads (L4)

Workloads describe what a host *is currently running*.

They are inherently stateful, often user-facing, and may change frequently over time.

Examples of workloads include:

- Application services (e.g. Traefik, Pi-hole, Plex)
- Docker Compose or Kubernetes deployments
- Application configuration and secrets
- Application data and volumes
- Backup fragments tied to specific services
- Workload-aware networking and routing policy
- Health checks and runtime validation

Workloads answer the question:  
**“What does this machine do?”**

### Why the Distinction Matters

Keeping capabilities and workloads separate allows the system to:

- Rebuild hosts safely without entangling application state
- Re-run OS convergence without impacting running services
- Iterate on applications independently of infrastructure
- Fail fast when prerequisites are missing
- Maintain a clear mental model as the system grows

A useful rule of thumb:

> If removing it still leaves a healthy operating system, it is a workload.  
> If removing it breaks the host’s ability to function as intended, it is a capability.

This doctrine is enforced throughout the L3/L4 boundary and guides all future role and playbook design.
