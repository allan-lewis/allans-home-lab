// Quick fit-test skeleton of the ZimaBoard shelf (shelf-zimaboard.scad): the
// board retention from lib/zimaboard.scad on a thin open floor with no
// faceplate or drive cage. Check the board's fit between its rails, corner
// stops and rear lip, and that the rear lip clears the ports.
//
// Print: floor down, no supports.
// Material: PLA is fine; it's a test print.

floor_thickness = 2;                 // set before the include, which uses it
include <zimaboard.scad>

frame = 8;                           // floor strip width around the opening

// Floor outline, seen from the front, in X/Z: an open frame under the board,
// from just ahead of the corner stops
module floor_outline() {
  z0 = pocket_z - rail_height;
  difference() {
    translate([pocket_x - rail_wall, z0])
      square([pocket[0] + 2 * rail_wall, floor_end - z0]);
    translate([pocket_x + frame, pocket_z + frame])
      square([pocket[0] - 2 * frame, pocket[1] - 2 * frame]);
  }
}

// Modeled in panel space, then laid on its floor
rotate([90, 0, 0])
  rack_front() {
    // Floor: the outline, drawn in X/Z, extruded up from Y=0
    translate([0, floor_thickness, 0]) rotate([90, 0, 0]) linear_extrude(floor_thickness) floor_outline();
    board_retention();
  }
