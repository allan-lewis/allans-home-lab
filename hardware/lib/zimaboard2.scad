// Retention for a ZimaBoard 2 and its PCIe NVMe adapter card on a 1U shelf,
// shared by rack-10in/shelf-zimaboard-2.scad and its fit-test mock-up, so fit
// changes made on the mock-up carry over.
//
// The board sits on the floor between low rails that hold it snugly side to
// side, with its network ports toward the rear. A stop behind the faceplate
// and a low lip at the rear hold it front to back; the lip stays below the
// lowest port opening. The rail on the right is cut away around the PCIe slot.
//
// The card plugs into the board's side and lies flat to its right. Fit the
// card to the board first, then lower them in together: a rail under the card
// carries its weight, and a fence just past its far edge stops it working out
// of the slot.
//
// Board dimensions are measured from IceWhale's official 3D model; card
// dimensions are estimated from product photos, so fence_gap may need
// adjusting. See hardware/reference.
//
// The including file sets floor_thickness before including this one.
// Positions are as seen from the front, in the panel's X/Y space with Z from
// the front face; place the modules with rack_front().

include <rack10.scad>

// ZimaBoard 2, with its SATA end toward the front and its network ports
// toward the rear
board_size = [77, 30.8, 140];        // width, height over the RJ45 jacks, length
board_port_bottom = 7.4;             // lowest port opening, above the board's bottom
// PCIe slot on the right side, seen from the front
slot_protrusion = 6;
slot_y = [1.5, 12.6];                // above the board's bottom
slot_z = [54.1, 93.9];               // from the board's front end

// PCIe to NVMe & NGFF SSD adapter (KB-SA0162), estimated to about +/-1.5 mm
card_reach = 67.5;                   // from the slot's outer face to the card's far edge
card_z = [19.2, 135.2];              // from the board's front end, with the edge connector centered on the slot
card_thickness = 1.6;

clearance = 0.3;                     // per side
rail_height = 6;                     // above the floor
rail_wall = 2;
front_stop = 4;                      // depth of the stop between the faceplate and the board
lip_height = 2;                      // rear lip; must stay below the ports
slot_gap = 2;                        // rail cut back this far past each end of the slot

card_support_inset = 8;              // support rail center, in from the card's far edge
card_support_drop = 0.2;             // support sits this far below the card, so it doesn't lever it in the slot
fence_gap = 1.5;                     // between the card's far edge and the fence, at the estimated reach
fence_above = 3;                     // fence height above the card's top face
card_end_margin = 6;                 // support and fence stop this far in from the card's ends

pocket = [board_size[0] + 2 * clearance, board_size[2] + 2 * clearance];  // width, length
pocket_x = rack_ear_width() + rail_wall;   // board at the far left, card to its right
pocket_z = PANEL_THICKNESS + front_stop;
lip_z = pocket_z + pocket[1];
floor_end = lip_z + 0.6 + lip_height;

board_x = pocket_x + clearance;
board_z = pocket_z + clearance;
pocket_right = pocket_x + pocket[0];

card_bottom = floor_thickness + (slot_y[0] + slot_y[1] - card_thickness) / 2;
card_edge_x = board_x + board_size[0] + slot_protrusion + card_reach;
card_z0 = board_z + card_z[0] + card_end_margin;
card_z1 = board_z + card_z[1] - card_end_margin;
support_x = card_edge_x - card_support_inset - rail_wall / 2;
fence_x = card_edge_x + fence_gap;

assert(floor_thickness + board_size[1] + 1 <= rack_panel_height(1) + PANEL_GAP / 2, "board would reach into the next U");
assert(lip_height < board_port_bottom, "rear lip would block the ports");
assert(fence_x + rail_wall <= rack_ear_width() + PANEL_REAR_WIDTH, "card fence past the rails");

// Wall along Z on the floor, from z0 to z1 and height above the floor. A wall
// that starts away from the faceplate rises at 45 degrees, so it prints face
// down without supports.
module rail(x, z0, z1, height = rail_height, ramp = false) {
  top = floor_thickness + height;
  translate([x, 0, 0])
    rotate([90, 0, 90])
      linear_extrude(rail_wall)
        polygon([
          [floor_thickness - 0.01, z0],
          [top, ramp ? z0 + height : z0],
          [top, z1],
          [floor_thickness - 0.01, z1],
        ]);
}

module board_retention() {
  // Front stop
  translate([pocket_x - rail_wall, floor_thickness - 0.01, PANEL_THICKNESS])
    cube([pocket[0] + 2 * rail_wall, rail_height + 0.01, front_stop]);

  rail(pocket_x - rail_wall, pocket_z, lip_z);
  rail(pocket_right, pocket_z, board_z + slot_z[0] - slot_gap);
  rail(pocket_right, board_z + slot_z[1] + slot_gap, lip_z, ramp = true);

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

module card_retention() {
  rail(support_x, card_z0, card_z1, card_bottom - card_support_drop - floor_thickness, ramp = true);
  rail(fence_x, card_z0, card_z1, card_bottom + card_thickness + fence_above - floor_thickness, ramp = true);
}
