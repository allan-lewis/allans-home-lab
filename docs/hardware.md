# Hardware

## Overview

This section covers 3D-printed parts for the homelab, starting with panels and mounts for the 10" rack.

Parts are treated as code:

- Every model is a parametric OpenSCAD (`.scad`) source file
- Printable files (STL) are build output, never committed
- Variants share a common library instead of copying geometry

Current equipment:

- Printer: Bambu Lab P2S with AMS
- Rack: DeskPi RackMate T2 (10")
- Keystone jacks: [Amazon B0F1F4LCNL](https://www.amazon.com/dp/B0F1F4LCNL)

---

## Mental Model

Models are source; STLs are artifacts.

The workflow is:

1. Edit or add a `.scad` file under `hardware/`
2. Render it to STL with `just hw-render`
3. Slice and print in Bambu Studio
4. Fold any fit adjustments back into the source parameters

Slicer project files (`.3mf` from Bambu Studio) are not committed. Print settings that matter for a part belong in a comment at the top of its `.scad` file.

---

## Layout

| Path | Purpose |
| --- | --- |
| `hardware/lib/` | Shared modules: rack panel base (`rack10.scad`), vent patterns (`vents.scad`), keystone openings (`keystone.scad`) |
| `hardware/fonts/` | Fonts used by parts, committed with their licenses so renders match everywhere |
| `hardware/rack-10in/` | Printable parts for the 10" rack, one `.scad` file per part |
| `hardware/reference/` | Third-party models kept for measurement and comparison only |
| `hardware/scripts/` | Render tooling |
| `hardware/build/` | Render output (gitignored) |

`hardware/lib/` is on `OPENSCADPATH` during renders, so models import it directly:

```openscad
include <rack10.scad>
```

---

## Tooling

### Install OpenSCAD

Use a development snapshot, which includes the Manifold geometry engine and renders far faster than the last stable release:

```bash
brew install --cask openscad@snapshot
```

The render script finds OpenSCAD on `PATH` or in `/Applications`. Set `OPENSCAD` to override the binary.

---

### Render Models

Render every model:

```bash
just hw-render
```

Render one directory or file, relative to `hardware/`:

```bash
just hw-render rack-10in
just hw-render rack-10in/panel-keystone.scad
```

Render with PNG previews alongside the STLs:

```bash
just hw-render rack-10in yes
```

Output mirrors the source tree under `hardware/build/`, e.g. `rack-10in/panel-keystone.scad` → `hardware/build/rack-10in/panel-keystone.stl`.

---

## Conventions

- Units are millimeters
- Parts are modeled in their print orientation, flat face on the Z=0 plane
- Panels are built with `rack_panel(u) { ... }`, whose children are 2D cutouts drawn as seen from the front of the rack. Panels print face down, so the module mirrors cutouts to keep text reading correctly.
- Text cut through a panel uses a stencil font, so the enclosed centers of letters like a, o and e stay attached. Keep stencil bridges at least ~1.2 mm wide (two nozzle widths plus margin).
- Tunable values (counts, sizes, clearances) are top-level variables so they appear in OpenSCAD's Customizer
- Fit-critical values (keystone snap, screw holes) live in `hardware/lib/` so every variant inherits a fix
- Each part's header comment records its print orientation, supports and material
- Files are named `<kind>-<variant>.scad`, e.g. `panel-blank.scad`, `panel-vent.scad`, `mount-<device>.scad`

---

## Materials

Default material: **PETG**, for every part that goes in the rack.

- Use one material and product line (e.g. all Bambu PETG HF) so parts match. The same color differs in shade and gloss between PLA and PETG, and between PETG lines.
- PETG also tolerates the heat near switches and power supplies better than PLA, which softens around 55–60 °C.
- PLA is fine for test prints that check fit or appearance. Reprint final parts in PETG.
- Print PETG on a textured plate, or use glue stick as a release layer on smooth PEI.

---

## Validating Rack Dimensions

`hardware/rack-10in/panel-skeleton.scad` is a low-filament test print with the full outline, ears, mounting holes and rear ribs of a 1U panel, but an open center.

Print it before trusting a change to `hardware/lib/rack10.scad`. If it doesn't fit, correct the constants in `rack10.scad`, not the skeleton, so every panel picks up the fix.

---

## Reference Models

Models downloaded from Printables, MakerWorld, etc. may be placed in `hardware/reference/` for local comparison. The model files themselves are gitignored, since most licenses don't allow redistribution. `hardware/reference/README.md` records each model's source, designer and license.

Reference models are used for measurement only. Parts in this repo are rebuilt from scratch so they can be maintained and varied freely.

To compare against a reference, import it alongside a part in OpenSCAD:

```openscad
%import("../reference/<model>.3mf");
```
