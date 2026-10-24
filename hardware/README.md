# Hardware

3D-printable parts for the homelab, maintained as parametric OpenSCAD source.

See [`docs/hardware.md`](../docs/hardware.md) for the full workflow.

## Layout

```
hardware/
├── lib/          # Shared OpenSCAD modules (rack standard, keystone, vents)
├── rack-10in/    # Parts for the DeskPi RackMate T2 (10" rack)
├── reference/    # Third-party source models, kept for measurement only
├── scripts/      # Render tooling
├── vendor/       # Third-party OpenSCAD libraries
└── build/        # Render output (gitignored)
```

## Quick Start

```bash
brew install --cask openscad@snapshot
just hw-render                       # render everything
just hw-render rack-10in yes         # render one directory, with PNG previews
```
