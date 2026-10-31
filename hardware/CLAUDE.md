# Hardware reference

Quick reference for the rack parts, on top of the Hardware section in the root `CLAUDE.md`. The `.scad` sources are authoritative; recheck them before relying on a number here.

## 10" rack and 1U panel

Verified on the DeskPi RackMate T2 by printing `rack-10in/panel-skeleton.scad` (2026-10-24).

- **1U panel:** 252 wide x 44.0 tall (44.45 less a 0.45 gap) x 4 thick, corner radius 4.
- **Rear width:** 216. Anything behind the plate must fit in it to clear the rails. Ears are 18 each, so the usable X range is 18 to 234.
- **Mounting:** 7 x 10 mm horizontal slots, centers 7.8 from each side, at Y 6.125 and 37.875.
- **Rear ribs:** along the top and bottom edges, 2 thick, reaching 6 from the front face.
- **Keystones:** `port_x(n) = 126 + (n - 6.5) * 18` for ports 1-12, openings 14.85 x 19.5, bottom edge at Y 13.8, housing depth 10. Parts define `port_x` themselves; it isn't in `lib/keystone.scad`. Housings cover about X 17.6-54.4 for ports 1-2 and from 197.6 for ports 11-12.

## Reusable modules

- `lib/rack10.scad`: `rack_panel(u)`, `rack_front()`, `rack_holes`, `rack_ribs`, `rack_panel_outline`, `rack_ear_width()`, `rack_hole_xs()`, `rack_hole_ys(u)`, `rack_panel_height(u)`.
- `lib/vents.scad`: `hex_vents(size, d, web, keepout, min_feature)` for faceplates, `diamond_lattice(size, d, web, solid, min_feature)` for shelf floors, `diamond_vents(size, d, web)`.
- `lib/keystone.scad`: `keystone_opening()`, `keystone_housing(xs, y, base_z)`.
- `lib/zimaboard.scad`: `rail(x, z0, z1, height, ramp, width)`, `board_retention()`, `drive_cage()`.
- `lib/zimaboard2.scad`: retention for the ZimaBoard 2 and its PCIe NVMe card.

## Where to start a new part

- **Shelf:** `rack-10in/shelf-zimaboard.scad`. The faceplate has hex vents, a stencil name and keystones 11-12; the floor is 6 thick with diamond windows.
- **Faceplate text:** Big Shoulders Stencil Bold, scaled so "allanshomelab.com" would be 130 wide, inset 0.3 to widen the bridges, with vents as tall as the letters.
- **Plain panel:** `panel-keystone`, `panel-vanity` or `panel-vent`.
- **Rail-mounted accessory with no panel:** `hook-cable-loop.scad`, an 18-wide plate with teardrop-topped slots that prints on its side.

`just hw-render rack-10in/<part>.scad [yes]` takes a path relative to `hardware/`.

## Device dimensions

- **2.5" drive cage:** 69.85 wide + 0.25 per side; 7 thick + 0.4; grooves 2.5 deep; walls and ledges 2.
- **Original ZimaBoard:** 74.6 x 34.9 x 138.1, with no clearance added because the ruler measurements run long. IceWhale's GLB is distorted, so use it for connector locations only.
- **ZimaBoard 2:** 77 x 30.8 x 140, with 0.3 clearance per side.

## Print lessons

- **Shelf floors:** use the diamond lattice with 25 mm diamonds and 4 mm struts, solid out to the first whole diamond at the outer edges. It printed well on the ZimaBoard 2 shelf; hexes were slow and the earlier 60 degree windows printed badly.
- **Ramps:** features starting away from the faceplate need 45 degree ramps (`rail(..., ramp = true)`).
- **Corner rounding:** keep it under half the thinnest feature, or `offset` erases that feature.
- **Two boards on one shelf:** two original ZimaBoards side by side collide with keystones 2 and 11.

## Parts status (as of 2026-10-31)

- **Confirmed in print:** ZimaBoard 2 shelf with the diamond floor; original ZimaBoard fit mock-up; SSD cage prototype.
- **No print result yet:** `shelf-zimaboard.scad`; `hook-cable-loop.scad`.
- **Shelved:** the USW-Flex-2.5G-8-PoE mount is good enough as-is, so leave it and its clips alone unless asked. The rear bumps sit several mm behind the switch, and the drop-in clips (2-5 mm) didn't fit.
- **Cabling for the original ZimaBoard:** its power/SATA adapter is proprietary, so extend on the drive side with male-to-female SATA extenders, not female-to-female.
