// Keystone jack openings and the housing that holds them, measured from a
// reference panel known to fit the jacks in use (Amazon B0F1F4LCNL).
//
// Y and Z follow rack10.scad: Y up the panel, Z from the front face (Z=0)
// toward the rear. Depths here are from the front face, since the jack's
// latch fit depends on them.

KEYSTONE_OPENING = [14.85, 19.5];      // width, height
KEYSTONE_CHAMFER = 3.1;                // 45 degree chamfer on the top front edge of the opening
KEYSTONE_WALL = 2;                     // housing wall around the openings
KEYSTONE_LATCH_Z = [5.95, 8.4];        // depth range of the latch windows in the housing top and bottom
KEYSTONE_LATCH_WIDTH = 12.2;
KEYSTONE_DEPTH = 10;                   // back of the housing

// One opening, centered on X with its bottom edge at Y=0, cut through the full depth
module keystone_opening() {
  w = KEYSTONE_OPENING[0];
  h = KEYSTONE_OPENING[1];
  c = KEYSTONE_CHAMFER;
  d = KEYSTONE_DEPTH;
  // Side profile (Y, Z) extruded across the width
  translate([-w / 2, 0, 0])
    rotate([90, 0, 90])
      linear_extrude(w)
        polygon([[0, -1], [0, d + 1], [h, d + 1], [h, c], [h - c, 0], [h - c, -1]]);
}

// Housing behind a row of openings, from base_z back to KEYSTONE_DEPTH.
// xs are the opening centers and y is the openings' bottom edge. Openings
// are not cut here; subtract keystone_opening() at each center.
module keystone_housing(xs, y, base_z) {
  w = KEYSTONE_OPENING[0];
  h = KEYSTONE_OPENING[1];
  x0 = min(xs) - w / 2 - KEYSTONE_WALL;
  x1 = max(xs) + w / 2 + KEYSTONE_WALL;
  y0 = y - KEYSTONE_WALL;
  y1 = y + h + KEYSTONE_WALL;

  difference() {
    union() {
      // 45 degree chamfer where the housing meets the plate
      hull() {
        translate([x0 - 1, y0 - 1, base_z]) cube([x1 - x0 + 2, y1 - y0 + 2, 0.01]);
        translate([x0, y0, base_z]) cube([x1 - x0, y1 - y0, 1]);
      }
      translate([x0, y0, base_z]) cube([x1 - x0, y1 - y0, KEYSTONE_DEPTH - base_z]);
    }

    // Windows in the top and bottom walls for the jack's latch and hook
    for (x = xs)
      translate([x - KEYSTONE_LATCH_WIDTH / 2, y0 - 1, KEYSTONE_LATCH_Z[0]])
        cube([KEYSTONE_LATCH_WIDTH, y1 - y0 + 2, KEYSTONE_LATCH_Z[1] - KEYSTONE_LATCH_Z[0]]);
  }
}
