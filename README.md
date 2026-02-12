# Allan's Home Lab

## Overview

Allan's Home Lab is a layered, GitOps-driven infrastructure
system for managing a (mostly) Proxmox-based home lab. It provides a structured
model for building, instantiating, converging, and rebuilding virtual
machines and their workloads using a clear separation of
responsibilities across infrastructure layers.

The project combines:

-   **Proxmox VE** for virtualization\
-   **Terraform** for VM lifecycle management\
-   **Ansible** for operating system convergence\
-   **Docker Compose** for workload orchestration\
-   **Just** as the operational interface\
-   **Git** as the single source of truth

The system is designed around one central idea:

> Infrastructure should be reproducible, inspectable, and rebuildable
> from declarative intent.

------------------------------------------------------------------------

### What This Project Is

This repository defines:

-   A structured L0--L4 infrastructure layering model\
-   A persona-driven approach to defining infrastructure intent\
-   A repeatable process for creating OS templates and VMs\
-   A clean separation between system configuration (L3) and workloads
    (L4)\
-   A capture-and-restore model that treats rebuildability as a primary
    goal

It is not a collection of ad-hoc scripts. It is an opinionated
infrastructure system designed to make rebuilding a host safer than
manually mutating it.

------------------------------------------------------------------------

### Why This Exists

Most homelabs evolve organically:

-   Manual VM creation\
-   Drift between machines\
-   Snowflake configurations\
-   "I think I installed that at some point"\
-   Backups that are an afterthought

This project exists to eliminate that entropy.

It enforces:

-   Clear responsibility boundaries between layers\
-   Declarative intent stored in Git\
-   Idempotent convergence of system state\
-   Rebuild-first thinking over mutation-first thinking\
-   Predictable operational workflows

The goal is not just automation --- it is **controlled evolution of
infrastructure**.

------------------------------------------------------------------------

### Who This Is For

This project is intended for:

-   Experienced homelabbers comfortable with Proxmox\
-   Users familiar with Terraform and Ansible\
-   Engineers who value reproducibility and structured infrastructure\
-   People who prefer rebuilding over debugging snowflakes\
-   Anyone interested in treating their homelab like real infrastructure

It assumes familiarity with:

-   Linux administration\
-   SSH-based workflows\
-   Declarative infrastructure concepts\
-   Version-controlled configuration

This is not a beginner-oriented homelab starter kit.

------------------------------------------------------------------------

### What This Project Is Not

This project is intentionally not:

-   A Kubernetes-first platform\
-   A highly available multi-site architecture\
-   A turnkey "click to deploy" system\
-   A UI-driven infrastructure solution\
-   A generic infrastructure framework intended to fit all environments

It is:

-   Optimized for a single-operator homelab\
-   Focused on reproducibility over convenience\
-   Opinionated about layering and separation of concerns\
-   Designed to scale within a home lab, not a production enterprise

The constraints are deliberate. The architecture is shaped by clarity,
not maximal flexibility.

## Core Design Philosophy

Allan's Home Lab is built around a small number of strongly enforced
principles. These principles shape how infrastructure is defined, how
changes are introduced, and how systems are rebuilt over time.

------------------------------------------------------------------------

### Layered Infrastructure

The system is organized into explicit layers (L0--L4), each with a
narrowly defined responsibility.

-   L0 validates and prepares the hypervisor environment.
-   L1 produces reusable OS templates.
-   L2 instantiates virtual machines from those templates.
-   L3 converges the operating system to a known-good state.
-   L4 deploys and manages application workloads.

Each layer exists to prevent responsibility overlap. A layer should only
do one class of work, and it should do that work well. This separation
reduces hidden coupling and makes rebuild workflows predictable.

------------------------------------------------------------------------

### Git as the Source of Truth

All durable infrastructure intent lives in Git.

Specifications for personas, resource definitions, OS configuration, and
workload definitions are version-controlled. The running system is
expected to reflect what is defined in the repository.

Drift is treated as a problem to be corrected by convergence, not as
something to be manually patched in production.

------------------------------------------------------------------------

### Rebuild Over Mutation

The system favors rebuilding over in-place mutation.

When something is unclear, broken, or outdated, the preferred approach
is to recreate it from declarative intent rather than to surgically
modify it. Templates can be re-generated. VMs can be destroyed and
recreated. OS state can be re-converged.

Rebuildability is considered a design feature, not a disaster recovery
fallback.

------------------------------------------------------------------------

### Idempotent Convergence

Every convergence step should be safe to run repeatedly.

Ansible roles, Terraform modules, and supporting scripts are written
with idempotency in mind. Running a convergence operation twice should
produce the same result as running it once.

This property enables:

-   Safe iteration
-   Predictable automation
-   Reduced fear of running commands
-   Simplified recovery workflows

------------------------------------------------------------------------

### Clear System vs Workload Boundary

A strict boundary exists between system configuration (L3) and
application workloads (L4).

L3 is responsible for the operating system itself: - Users - Packages -
Services required for the base host - Filesystem layout - System-level
configuration

L4 is responsible for workloads that run on top of the host: - Docker
Compose stacks - Monitoring services - Media services - Identity
providers - Reverse proxies

This separation ensures that:

-   The base host remains reusable and portable.
-   Workloads can evolve independently of the underlying OS.
-   Rebuilding a host does not require redefining application logic.
-   System-level changes do not accidentally couple to application
    concerns.

The boundary is intentional. It keeps infrastructure modular and
reinforces the rebuild-first model.

------------------------------------------------------------------------

### Backups and Capture as First-Class Concerns

Backup and image capture are not afterthoughts.

Templates can be promoted. Boot disks can be captured. Persistent data
can be synchronized or replicated. The system is designed with the
expectation that machines will be replaced and data will need to be
restored.

Infrastructure is treated as disposable. Data is treated as durable.

