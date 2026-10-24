// 10" rack panels for the DeskPi RackMate T2.
//
// Dimensions are measured from a reference panel known to fit the T2, with the
// EIA-310 hole pattern used for vertical hole placement. Verified on the T2 by
// printing rack-10in/panel-skeleton.scad (2026-10-24).
//
// Panels are modeled as printed: front face down on Z=0, rear toward +Z, with
// X across the panel and Y up it from a bottom corner. Seen from the front,
// that puts X=0 on the right; rack_panel() takes 2D cutouts drawn as seen from
// the front and mirrors them, so text and asymmetric layouts come out right.

RACK_U = 44.45;                        // one rack unit
RACK_HOLE_OFFSETS = [6.35, 22.225, 38.1]; // EIA-310 hole centers within one U, from the bottom of the U

PANEL_WIDTH = 252;
PANEL_GAP = 0.45;                      // panel height = u * RACK_U - PANEL_GAP
PANEL_THICKNESS = 4;
PANEL_CORNER_R = 4;
PANEL_REAR_WIDTH = 216;                // max width of anything behind the plate, so it clears the rails

PANEL_HOLE_INSET = 7.8;                // hole center from the left/right edge
PANEL_HOLE_D = 7;
PANEL_HOLE_SLOT = 3;                   // extra horizontal length; 7 x 10 mm slots
PANEL_HOLES = [0, 2];                  // which holes of each U to use; [0, 2] = top and bottom

PANEL_RIB_DEPTH = 6;                   // rear stiffening ribs, measured from the front face
PANEL_RIB_THICKNESS = 2;

function rack_panel_height(u) = u * RACK_U - PANEL_GAP;

// Width of each ear: the strip of panel that sits on a rail
function rack_ear_width() = (PANEL_WIDTH - PANEL_REAR_WIDTH) / 2;

function rack_hole_xs() = [PANEL_HOLE_INSET, PANEL_WIDTH - PANEL_HOLE_INSET];

function rack_hole_ys(u, holes = PANEL_HOLES) = [
  for (i = [0 : u - 1]) for (h = holes) i * RACK_U + RACK_HOLE_OFFSETS[h] - PANEL_GAP / 2
];

// 2D panel outline with rounded corners
module rack_panel_outline(u, r = PANEL_CORNER_R) {
  h = rack_panel_height(u);
  hull()
    for (x = [r, PANEL_WIDTH - r], y = [r, h - r])
      translate([x, y]) circle(r = r, $fn = 48);
}

// Mounting holes, to be subtracted from a panel
module rack_holes(u, holes = PANEL_HOLES, d = PANEL_HOLE_D, slot = PANEL_HOLE_SLOT) {
  for (x = rack_hole_xs(), y = rack_hole_ys(u, holes))
    translate([x, y, -1])
      hull()
        for (dx = [-slot / 2, slot / 2])
          translate([dx, 0, 0]) cylinder(d = d, h = PANEL_THICKNESS + 2, $fn = 48);
}

// Ribs along the top and bottom rear edges, within the width that clears the rails
module rack_ribs(u, depth = PANEL_RIB_DEPTH, t = PANEL_RIB_THICKNESS) {
  for (y = [0, rack_panel_height(u) - t])
    translate([rack_ear_width(), y, 0]) cube([PANEL_REAR_WIDTH, t, depth]);
}

// A complete panel: plate, mounting holes and ribs. Children are 2D cutouts
// drawn as seen from the front, in the same X/Y space as the panel.
module rack_panel(u = 1) {
  difference() {
    union() {
      linear_extrude(PANEL_THICKNESS)
        difference() {
          rack_panel_outline(u);
          translate([PANEL_WIDTH, 0]) mirror([1, 0]) children();
        }
      rack_ribs(u);
    }
    rack_holes(u);
  }
}
