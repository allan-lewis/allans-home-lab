// Cable raceway module for one of the rack's rear rails. Cables run up and
// down the rail through a few of these, spaced out along it.
//
// A base plate screws to the rail through one U's top and bottom holes, in
// the same 7 x 10 mm slots as a 1U panel's ear. Lay the cables over it, then
// push the three-sided cover straight on: a catch along the foot of each
// cover wall rides over the plate's edge and drops into a groove cut into it.
// The groove and catches stop short of the screw holes, so the cover can't
// slide along the rail. Pull the cover straight off to open it; the catches'
// 45 degree faces let go under a firm pull.
//
// The cover's outside width matches the rail, so nothing reaches past it into
// the rack. The screw heads sit inside the channel, under the cables.
//
// Both parts are in one file, laid out for printing together.
// Print: base front face down, cover roof down; no supports.
// Material: PETG.

include <rack10.scad>

inside_depth = 16;                   // from the plate's rear face to the cover's roof
wall = 2;                            // cover walls; these flex as the cover snaps on
roof = 2;
lip = 1.2;                           // how far each catch reaches in past the plate's edge
lead = 1;                            // height of each catch's lead-in ramp; steeper than 45 degrees to fit the plate
lip_flat = 0.2;                      // flat tip of each catch
chamfer = 0.6;                       // on the plate's rear edges, to start the catches over them
clearance = 0.2;
hole_margin = 2;                     // between a screw slot and the ends of the catches

width = rack_ear_width();            // across the rail; the cover's outside width
length = rack_panel_height(1);
hole_ys = rack_hole_ys(1);
hole_r = PANEL_HOLE_D / 2;
plate_w = width - 2 * (wall + clearance);
plate_t = PANEL_THICKNESS;
cover_h = plate_t + inside_depth + roof;

reach = lip + clearance;             // catch's protrusion from the cover wall
catch_top = clearance + lead + lip_flat + reach;
catch_y0 = hole_ys[0] + hole_r + hole_margin;
catch_y1 = hole_ys[1] - hole_r - hole_margin;

assert(catch_top + 2 * clearance < plate_t - 0.8,"groove leaves too little plate edge for the catches to ride over");
assert(hole_r + PANEL_HOLE_SLOT / 2 < plate_w / 2 - 1, "screw slots too long for the plate");
assert(catch_y1 - catch_y0 > 10, "too little length between the screw holes for the catches");

// Extrudes a 2D profile, X across the rail and Y rearward from it, into
// installed space (Z rearward) between y0 and y1 along the rail
module along_rail(y0, y1) {
  translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

// One catch, on the right wall (s = 1) or left wall (s = -1): a lead-in ramp,
// a short flat tip and a 45 degree retaining face
module catch_2d(s) {
  x_wall = plate_w / 2 + clearance;
  x_tip = x_wall - reach;
  scale([s, 1])
    polygon([
      [x_wall + wall / 2, clearance],
      [x_wall, clearance],
      [x_tip, clearance + lead],
      [x_tip, clearance + lead + lip_flat],
      [x_wall, catch_top],
      [x_wall + wall / 2, catch_top],
    ]);
}

module base() {
  difference() {
    along_rail(0, length)
      polygon([
        [-plate_w / 2, 0],
        [plate_w / 2, 0],
        [plate_w / 2, plate_t - chamfer],
        [plate_w / 2 - chamfer, plate_t],
        [-plate_w / 2 + chamfer, plate_t],
        [-plate_w / 2, plate_t - chamfer],
      ]);
    // Grooves for the catches, open to the rail face
    along_rail(catch_y0 - clearance, catch_y1 + clearance)
      for (s = [-1, 1])
        hull() {
          offset(delta = clearance) catch_2d(s);
          translate([0, -2]) offset(delta = clearance) catch_2d(s);
        }
    for (y = hole_ys)
      translate([0, y, -1])
        hull()
          for (dx = [-PANEL_HOLE_SLOT / 2, PANEL_HOLE_SLOT / 2])
            translate([dx, 0, 0]) cylinder(r = hole_r, h = plate_t + 2, $fn = 48);
  }
}

module cover() {
  along_rail(0, length)
    difference() {
      translate([-width / 2, 0]) square([width, cover_h]);
      translate([-(plate_w / 2 + clearance), -1]) square([plate_w + 2 * clearance, plate_t + inside_depth + 1]);
    }
  along_rail(catch_y0, catch_y1)
    for (s = [-1, 1]) catch_2d(s);
}

base();
translate([width + 8, 0, cover_h]) rotate([0, 180, 0]) cover();
