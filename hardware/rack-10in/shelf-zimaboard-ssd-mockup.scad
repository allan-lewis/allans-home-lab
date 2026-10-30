// Quick fit-test skeleton of the ZimaBoard shelf's drive cage
// (shelf-zimaboard.scad): the cage from lib/zimaboard.scad on a thin open
// floor, with no board retention or faceplate. Check that both drives slide
// in from the rear and stop at the grooves' front ends without binding or
// rattling, and that SATA plugs fit onto their connectors between the walls.
//
// Print: floor down, no supports.
// Material: PLA is fine; it's a test print.

floor_thickness = 2;                 // set before the include, which uses it
include <zimaboard.scad>

frame = 8;                           // floor strip width around the opening

// Floor outline, seen from the front, in X/Z: an open frame under the cage
module floor_outline() {
  difference() {
    translate([cage_x0, cage_z0])
      square([cage_x1 - cage_x0, cage_z1 - cage_z0]);
    translate([cage_x0 + cage_side + frame, ssd_z + frame])
      square([cage_x1 - cage_x0 - 2 * (cage_side + frame), cage_z1 - ssd_z - 2 * frame]);
  }
}

// Modeled in panel space, then laid on its floor
rotate([90, 0, 0])
  rack_front() {
    // Floor: the outline, drawn in X/Z, extruded up from Y=0
    translate([0, floor_thickness, 0]) rotate([90, 0, 0]) linear_extrude(floor_thickness) floor_outline();
    drive_cage();
  }
