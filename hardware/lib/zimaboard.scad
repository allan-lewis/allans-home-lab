// Retention for an original ZimaBoard and two 2.5" drives on a 1U shelf,
// shared by rack-10in/shelf-zimaboard.scad and its fit-test mock-ups, so fit
// changes made on the mock-ups carry over.
//
// The board sits at the left of the shelf with its SATA end toward the front
// and its network and power ports toward the rear. It sits an inch further
// back than the ZimaBoard 2 does on its shelf, leaving room ahead of it for
// SATA cables. Stops at its front corners leave the SATA ports between them
// clear, and a low lip at the rear holds it front to back; the lip stays below
// the lowest port opening. Side rails run along the front and rear quarters of
// the board only, so the PCIe slot, which sticks out of the right side
// somewhere in the middle half, needs no exact position.
//
// To the board's right, clear of the PCIe slot, a cage holds two 2.5" drives
// stacked one above the other, connectors toward the front. Each drive slides
// in from the rear along grooves in the cage's side walls until it stops
// against their closed front ends.
//
// Board dimensions are rough ruler measurements, believed slightly long, so no
// clearance is added; IceWhale's 3D model of this board is distorted and not
// usable for measurement. See hardware/reference.
//
// The including file sets floor_thickness before including this one.
// Positions are as seen from the front, in the panel's X/Y space with Z from
// the front face; place the modules with rack_front().

include <rack10.scad>

// ZimaBoard, with its SATA end toward the front and its network ports toward
// the rear
board_size = [74.6, 34.9, 138.1];    // width (2 15/16"), height (IceWhale spec; fits the ZimaBoard 2 shelf), length (5 7/16")
board_port_bottom = 6.35;            // lowest port opening, above the board's bottom (1/4")

clearance = 0;                       // per side; the measurements already run long
rail_height = 6;                     // above the floor
rail_wall = 2;
rail_fraction = 0.25;                // side rails cover this much of the board's length at each end
corner_stop = 8;                     // width of each front corner stop, in from the board's side
lip_height = 2;                      // rear lip; must stay below the ports
sata_access = 25.4;                  // added room ahead of the board, beyond the ZimaBoard 2 shelf's 4 mm stop

// 2.5" drives (SFF-8201), lying flat with their connectors toward the front
ssd_size = [69.85, 7, 100];          // width, thickness, length; 7 mm drives
ssd_clearance = 0.25;                // per side, across the width
ssd_play = 0.4;                      // added to the thickness in each groove
pcie_clearance = 15;                 // from the board's right side to the cage, for the PCIe slot
groove_depth = 2.5;                  // how far the walls reach over each drive's edge
cage_wall = 2;                       // wall behind the grooves
ledge = 2;                           // wall between the grooves and above the top one
ssd_grip = 10;                       // drives stick out this far past the cage's rear

pocket = [board_size[0] + 2 * clearance, board_size[2] + 2 * clearance];  // width, length
pocket_x = rack_ear_width() + rail_wall;   // board at the far left
pocket_z = PANEL_THICKNESS + 4 + sata_access;
pocket_right = pocket_x + pocket[0];
lip_z = pocket_z + pocket[1];
floor_end = lip_z + 0.6 + lip_height;
rail_length = rail_fraction * pocket[1];

// Drive cage: left and right outer faces, the drives' front ends, and the
// walls' height above the floor
slot_width = ssd_size[0] + 2 * ssd_clearance;
slot_height = ssd_size[1] + ssd_play;
cage_x0 = pocket_right + pcie_clearance;
cage_x1 = cage_x0 + slot_width + 2 * cage_wall;
cage_side = cage_wall + groove_depth;
ssd_z = pocket_z;                    // drive connectors in line with the board's SATA end
cage_height = 2 * slot_height + 2 * ledge;
cage_z0 = ssd_z - cage_height;       // the walls ramp up to full height at the drives' front ends
cage_z1 = ssd_z + ssd_size[2] - ssd_grip;

assert(floor_thickness + board_size[1] + 1 <= rack_panel_height(1) + PANEL_GAP / 2, "board would reach into the next U");
assert(lip_height < board_port_bottom, "rear lip would block the ports");
assert(cage_z0 >= PANEL_THICKNESS, "drive cage would run into the faceplate");
assert(floor_thickness + cage_height < rack_panel_height(1), "drive cage taller than the panel");

// Wall along Z on the floor, from z0 to z1 and height above the floor. A wall
// that starts away from the faceplate rises at 45 degrees, so it prints face
// down without supports.
module rail(x, z0, z1, height = rail_height, ramp = false, width = rail_wall) {
  top = floor_thickness + height;
  translate([x, 0, 0])
    rotate([90, 0, 90])
      linear_extrude(width)
        polygon([
          [floor_thickness - 0.01, z0],
          [top, ramp ? z0 + height : z0],
          [top, z1],
          [floor_thickness - 0.01, z1],
        ]);
}

module board_retention() {
  for (x = [pocket_x - rail_wall, pocket_right]) {
    // Front rails, ramping up to full height at the board's front end
    rail(x, pocket_z - rail_height, pocket_z + rail_length, ramp = true);
    rail(x, lip_z - rail_length, lip_z, ramp = true);
  }

  // Front corner stops: the same ramp, with a square face against the board
  for (x = [pocket_x - rail_wall, pocket_right - corner_stop])
    rail(x, pocket_z - rail_height, pocket_z, ramp = true, width = rail_wall + corner_stop);

  // Rear lip: a square face toward the board, sloping away to the rear
  translate([pocket_x - rail_wall, 0, 0])
    rotate([90, 0, 90])
      linear_extrude(pocket[0] + 2 * rail_wall)
        polygon([
          [floor_thickness - 0.01, lip_z],
          [floor_thickness + lip_height, lip_z],
          [floor_thickness + lip_height, lip_z + 0.6],
          [floor_thickness - 0.01, floor_end],
        ]);
}

// The drive cage's side walls, each with its grooves on the side facing the
// drives
module drive_cage() {
  for (side = [[cage_x0, cage_x0 + cage_wall], [cage_x1 - cage_side, cage_x1 - cage_side - 1]])
    difference() {
      rail(side[0], cage_z0, cage_z1, cage_height, ramp = true, width = cage_side);
      for (i = [0, 1])
        translate([side[1], floor_thickness + i * (slot_height + ledge), ssd_z])
          cube([groove_depth + 1, slot_height, cage_z1 - ssd_z + 1]);
    }
}
