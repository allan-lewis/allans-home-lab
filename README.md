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

