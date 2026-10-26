// Quick fit-test mock-up of the ZimaBoard 2 shelf (shelf-zimaboard-2.scad):
// the same board and card retention, from lib/zimaboard2.scad, on a thin open
// floor with no faceplate.
//
// Print: floor down, no supports.
// Material: PLA is fine; it's a test print.

floor_thickness = 2;                 // set before the include, which uses it
include <zimaboard2.scad>

frame = 8;                           // floor strip width around each opening

// Floor outline, seen from the front, in X/Z: open frames under the board and
// the card
module floor_outline() {
  difference() {
    translate([pocket_x - rail_wall, PANEL_THICKNESS])
      square([pocket[0] + 2 * rail_wall, floor_end - PANEL_THICKNESS]);
    translate([pocket_x + frame, pocket_z + frame])
      square([pocket[0] - 2 * frame, pocket[1] - 2 * frame]);
  }
  difference() {
    translate([pocket_right, card_z0]) square([fence_x + rail_wall - pocket_right, card_z1 - card_z0]);
    translate([pocket_right + rail_wall + frame, card_z0 + frame])
      square([support_x - frame - pocket_right - rail_wall - frame, card_z1 - card_z0 - 2 * frame]);
  }
}

// Modeled in panel space, then laid on its floor
rotate([90, 0, 0])
  rack_front() {
    // Floor: the outline, drawn in X/Z, extruded up from Y=0
    translate([0, floor_thickness, 0]) rotate([90, 0, 0]) linear_extrude(floor_thickness) floor_outline();
    board_retention();
    card_retention();
  }
