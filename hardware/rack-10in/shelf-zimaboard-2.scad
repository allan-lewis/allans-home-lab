// 1U shelf for a ZimaBoard 2 with a PCIe NVMe adapter card, with the board's
// network ports facing the rear and all cabling inside the rack.
//
// The board and card sit at the left, held by the retention in
// lib/zimaboard2.scad (fit-tested with shelf-zimaboard-2-mockup.scad). The
// faceplate has a framed honeycomb vent field on the left, in front of the
// board, two keystone ports on the right at the positions of ports 11 and 12
// on panel-keystone.scad, and the name cut through it between them, where the
// board doesn't block it.
//
// The floor is solid behind the faceplate, where the load is highest, at the
// rear, and in strips under each rail and along the edges. The rails stand on
// those strips and stiffen them. Between them the floor is a lattice of large
// diamonds, whose crossed struts brace it like a truss. Every edge is at 45
// degrees, so it prints face down without bridging, and every strut runs
// between the strips, so no tall, thin column stands free in the print to
// wobble. The right edge has no rail of its own, so a low rib stands on it.
//
// Print: front face down, no supports.
// Material: PETG.

floor_thickness = 6;                 // set before the include, which uses it
include <zimaboard2.scad>
include <keystone.scad>
use <vents.scad>
use <../fonts/BigShouldersStencil-Variable.ttf>

u = 1;

floor_band = 12;                     // solid floor behind the faceplate and at the rear
window_margin = 4;                   // solid floor beside each rail and along the edges
floor_diamond = 25;                  // diamond width and height, point to point
floor_web = 4;                       // strut width
edge_rib_height = 4;                 // right edge rib, above the floor; stays below the keystone jacks

// Keystone ports, numbered as on panel-keystone.scad: 12 ports at 18 mm pitch,
// counted from the left seen from the front
ports = [11, 12];
opening_bottom = 13.8;               // Y of the openings' bottom edge

// Name, in the vanity panel's font and letter size, centered on the ports'
// height and ending vent_gap before them
label = "zimaboard 2";
font = "Big Shoulders Stencil:style=Bold";
text_inset = 0.3;                    // shrink letters on every edge, widening the stencil bridges

// Vents from the left edge of port 1's opening on the keystone panel to
// vent_gap before the name, as tall as the "2". Hexagons match
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

// The name's left edge, and the visible height of its "2", after text_inset
label_metrics = textmetrics(label, font = font, size = 10, halign = "left", valign = "center");
two_metrics = textmetrics("2", font = font, size = 10);
text_x = port_x(ports[0]) - KEYSTONE_OPENING[0] / 2 - vent_gap + text_inset - label_metrics.size[0] * text_scale;
two_bottom = text_y + (label_metrics.offset[1] + two_metrics.position[1]) * text_scale + text_inset;
two_height = two_metrics.size[1] * text_scale - 2 * text_inset;

// Diamond fields in the floor, as [left, right] seen from the front: under
// the board, under the card, and right of the card's fence
edge_rib_x = rack_ear_width() + PANEL_REAR_WIDTH - rail_wall;
window_z0 = PANEL_THICKNESS + floor_band;
window_z1 = floor_end - floor_band;
window_xs = [
  [pocket_x + window_margin, pocket_right - window_margin],
  [pocket_right + rail_wall + window_margin, support_x - window_margin],
  [fence_x + rail_wall + window_margin, edge_rib_x - window_margin],
];

// Diamonds on a staggered grid filling a size = [w, h] field anchored at the
// origin. Rows stay whole at the field's front and rear ends, where a cut
// diamond would leave a flat bridge in the print; at the sides they run into
// the strips, cut to triangles with 45 degree tops, so every strut ends on a
// strip, except on a side marked solid = [left, right], where cut diamonds are
// left out. Slivers narrower than min_feature are left solid.
module floor_lattice(size, solid = [false, false], d = floor_diamond, web = floor_web, min_feature = 2) {
  pitch = d + web * sqrt(2);         // center spacing along a row; rows are pitch / 2 apart
  rows = floor((size[1] - d) / (pitch / 2)) + 1;
  y0 = (size[1] - d - (rows - 1) * pitch / 2) / 2 + d / 2;
  n = ceil(size[0] / pitch) + 1;

  offset(delta = min_feature / 2) offset(delta = -min_feature / 2)
    intersection() {
      square(size);
      for (j = [0 : rows - 1], i = [-n : n])
        let (x = size[0] / 2 + (i + (j % 2) / 2) * pitch)
          if (!(solid[0] && x < d / 2) && !(solid[1] && x > size[0] - d / 2))
            translate([x, y0 + j * pitch / 2])
              rotate(45) square(d / sqrt(2), center = true);
    }
}

vent_x0 = port_x(1) - KEYSTONE_OPENING[0] / 2;
vent_x1 = text_x + text_inset - vent_gap;

difference() {
  union() {
    rack_panel(u) {
      translate([text_x - text_left, text_y])
        offset(delta = -text_inset)
          scale(text_scale)
            text(label, font = font, size = 10, halign = "left", valign = "center");

      translate([vent_x0, two_bottom])
        hex_vents([vent_x1 - vent_x0, two_height], vent_d, vent_web);
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
              for (k = [0 : len(window_xs) - 1])
                let (w = window_xs[k])
                  translate([w[0], window_z0])
                    floor_lattice([w[1] - w[0], window_z1 - window_z0],
                                  solid = [k == 0, k == len(window_xs) - 1]);
            }
      rail(edge_rib_x, PANEL_THICKNESS, floor_end, edge_rib_height);
      board_retention();
      card_retention();
    }
  }

  rack_front()
    for (x = port_xs)
      translate([x, opening_bottom, 0]) keystone_opening();
}
