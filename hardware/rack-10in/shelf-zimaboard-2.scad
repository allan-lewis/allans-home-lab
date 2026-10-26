// 1U shelf for a ZimaBoard 2 with a PCIe NVMe adapter card, with the board's
// network ports facing the rear and all cabling inside the rack.
//
// The board and card sit at the left, held by the retention in
// lib/zimaboard2.scad (fit-tested with shelf-zimaboard-2-mockup.scad). The
// faceplate has the name cut through it on the left, two keystone ports on the
// right at the positions of ports 11 and 12 on panel-keystone.scad, and a
// framed honeycomb vent field between them.
//
// The floor is solid behind the faceplate, where the load is highest, at the
// rear, and in strips under each rail and along the edges. The rails stand on
// those strips and stiffen them, so large windows between them save print time
// without losing much stiffness. The windows have pointed rear ends, so they
// print face down without bridging.
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

// Keystone ports, numbered as on panel-keystone.scad: 12 ports at 18 mm pitch,
// counted from the left seen from the front
ports = [11, 12];
opening_bottom = 13.8;               // Y of the openings' bottom edge

// Name, in the vanity panel's font and letter size, starting at the left edge
// of port 1's opening on the keystone panel and centered on the ports' height
label = "zimaboard 2";
font = "Big Shoulders Stencil:style=Bold";
text_inset = 0.3;                    // shrink letters on every edge, widening the stencil bridges

// Vents between the name and the ports, as tall as the "2" and spaced clear of
// both. Hexagons match panel-vanity.scad.
vent_gap = 8;
vent_d = 6.44;
vent_web = 1.5;

function port_x(n) = PANEL_WIDTH / 2 + (n - 1 - (12 - 1) / 2) * 18;
port_xs = [for (n = ports) port_x(n)];

// panel-vanity.scad scales its label to 130 mm wide
text_scale = 130 / textmetrics("allanshomelab.com", font = font, size = 10).size[0];
text_left = textmetrics(label, font = font, size = 10, halign = "left").position[0] * text_scale;
text_x = port_x(1) - KEYSTONE_OPENING[0] / 2;
text_y = opening_bottom + KEYSTONE_OPENING[1] / 2;

// The visible extents of the name and of its "2", after text_inset
label_metrics = textmetrics(label, font = font, size = 10, halign = "left", valign = "center");
two_metrics = textmetrics("2", font = font, size = 10);
text_right = text_x + label_metrics.size[0] * text_scale - text_inset;
two_bottom = text_y + (label_metrics.offset[1] + two_metrics.position[1]) * text_scale + text_inset;
two_height = two_metrics.size[1] * text_scale - 2 * text_inset;

// Floor windows, as [left, right] seen from the front: under the board, under
// the card, and right of the card's fence
window_z0 = PANEL_THICKNESS + floor_band;
window_z1 = floor_end - floor_band;  // tip of the pointed rear end
window_xs = [
  [pocket_x + window_margin, pocket_right - window_margin],
  [pocket_right + rail_wall + window_margin, support_x - window_margin],
  [fence_x + rail_wall + window_margin, rack_ear_width() + PANEL_REAR_WIDTH - window_margin],
];

for (w = window_xs)
  assert(window_z1 - (w[1] - w[0]) / 2 > window_z0, "floor window too wide for its pointed end");

vent_x0 = text_right + vent_gap;
vent_x1 = port_x(ports[0]) - KEYSTONE_OPENING[0] / 2 - vent_gap;

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
              for (w = window_xs)
                polygon([
                  [w[0], window_z0],
                  [w[1], window_z0],
                  [w[1], window_z1 - (w[1] - w[0]) / 2],
                  [(w[0] + w[1]) / 2, window_z1],
                  [w[0], window_z1 - (w[1] - w[0]) / 2],
                ]);
            }
      board_retention();
      card_retention();
    }
  }

  rack_front()
    for (x = port_xs)
      translate([x, opening_bottom, 0]) keystone_opening();
}
