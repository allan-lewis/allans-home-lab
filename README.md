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

