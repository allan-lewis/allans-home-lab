// 1U shelf for an original ZimaBoard with no drives: shelf-zimaboard.scad
// without the drive cage. The board's network ports face the rear, with all
// cabling inside the rack.
//
// The board sits at the left with the retention in lib/zimaboard.scad,
// fit-tested with shelf-zimaboard-mockup.scad. With no drives to cable, it sits
// at the ZimaBoard 2 shelf's 4 mm from the faceplate, without the room
// shelf-zimaboard.scad leaves for SATA cables. The floor to its right is open
// for the PCIe slot and any cabling.
//
// The faceplate matches shelf-zimaboard-2.scad: a framed honeycomb vent field
// on the left, two keystone ports on the right at the positions of ports 11
// and 12 on panel-keystone.scad, and the name between them.
//
// The floor is solid behind the faceplate, at the rear, and in strips under each rail and along the edges. Between them it is a
// diamond lattice, as on shelf-zimaboard-2.scad. The right edge has no rail of
// its own, so a low rib stands on it.
//
// Print: front face down, no supports.
// Material: PETG.

floor_thickness = 6;                 // set before the include, which uses it
include <zimaboard.scad>
sata_access = 0;                     // overrides the library's value, so it goes after the include
include <keystone.scad>
use <vents.scad>
use <../fonts/BigShouldersStencil-Variable.ttf>

u = 1;

floor_band = 12;                     // solid floor behind the faceplate and at the rear
window_margin = 4;                   // solid floor beside each rail and wall and along the edges
floor_diamond = 25;                  // diamond width and height, point to point
floor_web = 4;                       // strut width
edge_rib_height = 4;                 // right edge rib, above the floor; stays below the keystone jacks

// Keystone ports, numbered as on panel-keystone.scad: 12 ports at 18 mm pitch,
// counted from the left seen from the front
ports = [11, 12];
opening_bottom = 13.8;               // Y of the openings' bottom edge

// Name, in the vanity panel's font and letter size, centered on the ports'
// height and ending vent_gap before them
label = "zimaboard";
font = "Big Shoulders Stencil:style=Bold";
text_inset = 0.3;                    // shrink letters on every edge, widening the stencil bridges

// Vents from the left edge of port 1's opening on the keystone panel to
// vent_gap before the name, as tall as its letters. Hexagons match
// panel-vanity.scad.
vent_gap = 8;                        // between the vents and the name, and the name and the ports
vent_d = 6.44;
vent_web = 1.5;

function port_x(n) = PANEL_WIDTH / 2 + (n - 1 - (12 - 1) / 2) * 18;
port_xs = [for (n = ports) port_x(n)];

// panel-vanity.scad scales its label to 130 mm wide
text_scale = 130 / textmetrics("allanshomelab.com", font = font, size = 10).size[0];
text_left = textmetrics(label, font = font, size = 10, halign = "left").position[0] * text_scale;
text_y = opening_bottom + KEYSTONE_OPENING[1] / 2;

// The name's left edge, and the visible bottom and height of its letters,
// after text_inset
label_metrics = textmetrics(label, font = font, size = 10, halign = "left", valign = "center");
text_x = port_x(ports[0]) - KEYSTONE_OPENING[0] / 2 - vent_gap + text_inset - label_metrics.size[0] * text_scale;
letters_bottom = text_y + label_metrics.position[1] * text_scale + text_inset;
letters_height = label_metrics.size[1] * text_scale - 2 * text_inset;

vent_x0 = port_x(1) - KEYSTONE_OPENING[0] / 2;
vent_x1 = text_x + text_inset - vent_gap;

edge_rib_x = rack_ear_width() + PANEL_REAR_WIDTH - rail_wall;

// Diamond fields in the floor, as [left, right, front] seen from the front:
// under the board, and from the board to the right edge.
window_z0 = PANEL_THICKNESS + floor_band;
window_z1 = floor_end - floor_band;
windows = [
  [pocket_x + window_margin, pocket_right - window_margin, window_z0],
  [pocket_right + rail_wall + window_margin, edge_rib_x - window_margin, window_z0],
];

difference() {
  union() {
    rack_panel(u) {
      translate([text_x - text_left, text_y])
        offset(delta = -text_inset)
          scale(text_scale)
            text(label, font = font, size = 10, halign = "left", valign = "center");

      translate([vent_x0, letters_bottom])
        hex_vents([vent_x1 - vent_x0, letters_height], vent_d, vent_web);
    }

    rack_front() {
      keystone_housing(port_xs, opening_bottom, PANEL_THICKNESS);
      // Floor: drawn in X/Z, extruded up from Y=0
      translate([0, floor_thickness, 0])
        rotate([90, 0, 0])
          linear_extrude(floor_thickness)
            difference() {
              translate([rack_ear_width(), PANEL_THICKNESS])
                square([PANEL_REAR_WIDTH, floor_end - PANEL_THICKNESS]);
              // Solid out to the first whole diamonds at the shelf's left and right edges
              for (k = [0 : len(windows) - 1])
                let (w = windows[k])
                  translate([w[0], w[2]])
                    diamond_lattice([w[1] - w[0], window_z1 - w[2]], floor_diamond, floor_web,
                                    solid = [k == 0, k == len(windows) - 1]);
            }
      rail(edge_rib_x, PANEL_THICKNESS, floor_end, edge_rib_height);
      board_retention();
    }
  }

  rack_front()
    for (x = port_xs)
      translate([x, opening_bottom, 0]) keystone_opening();
}
