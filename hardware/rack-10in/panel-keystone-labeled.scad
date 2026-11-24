// Labeled keystone patch panel: nine keystone openings in a row, with each
// port's purpose engraved in the front face below it. The 2.5G ports share one
// label, under a line spanning the group. Port geometry is shared with panel-keystone.scad; see
// keystone.scad.
//
// Print: front face down, no supports. The engraving is a shallow recess in
// the first layers, bridged by the layers above it.
// Material: PETG.

include <rack10.scad>
include <keystone.scad>
use <../fonts/BigShouldersStencil-Variable.ttf>

u = 1;
pitch = 20;              // wider than panel-keystone's 18, to give the labels room
opening_bottom = 15.5;   // Y of the openings' bottom edge, raised to fit the labels below
raise = 1;               // extra plate thickness behind the face, between the rails
raise_width = 220;       // panel-keystone proves this clears the rails at this depth

// Labels, port 1 (far left, seen from the front) to port 9. Ports in the
// group are left blank here and share group_label.
labels = ["IoT", "VPN", "1G", "", "", "", "", "", "LAN"];
group = [4, 8];          // first and last port of the group
group_label = "2.5G";

font = "Big Shoulders Stencil:style=Bold";
label_size = 6.5;        // font size; capitals come out about 5 mm tall
label_y = 7.5;           // vertical center of the labels
engrave_depth = 0.6;     // three 0.2 mm layers
line_y = 12.5;           // center of the group line, between the openings and the labels
line_width = 0.8;

// Notch in the top edge for the USW-Flex power cord, which comes forward from
// behind this panel and up into the switch's DC jack in the 1U above. It is
// as wide as a port and sits where panel-keystone.scad has it, above that
// panel's port 11 (18 mm pitch), so it stays under the jack whatever this
// panel's port layout. The openings sit low enough that it clears the housing.
cord_notch = true;
cord_notch_x = PANEL_WIDTH / 2 + (11 - 6.5) * 18;  // center, from the left seen from the front
cord_notch_depth = 6.5;  // from the top edge

// Port 9 sits where panel-keystone.scad has its port 10, one port left of the
// notch, from the left seen from the front
last_port_x = PANEL_WIDTH / 2 + (10 - 6.5) * 18;

h = rack_panel_height(u);
ports = len(labels);

// Port center from the left, seen from the front. The row is anchored on the
// last port rather than centered, so it sits left of the panel's center.
function port_x(n) = last_port_x - (ports - n) * pitch;

xs = [for (n = [1 : ports]) port_x(n)];
housing_half = KEYSTONE_OPENING[0] / 2 + KEYSTONE_WALL;
assert(min(xs) - housing_half >= rack_ear_width() && max(xs) + housing_half <= PANEL_WIDTH - rack_ear_width(),
  "housing does not clear the rails");
assert(!cord_notch || opening_bottom + KEYSTONE_OPENING[1] + KEYSTONE_WALL < h - cord_notch_depth,
  "cord notch cuts into the housing");

difference() {
  union() {
    rack_panel(u);
    translate([(PANEL_WIDTH - raise_width) / 2, 0, PANEL_THICKNESS])
      cube([raise_width, h, raise]);
    rack_front() keystone_housing(xs, opening_bottom, PANEL_THICKNESS + raise);
  }

  rack_front() {
    for (x = xs)
      translate([x, opening_bottom, 0]) keystone_opening();

    translate([0, 0, -1])
      linear_extrude(engrave_depth + 1) {
        for (n = [1 : ports])
          translate([port_x(n), label_y])
            text(labels[n - 1], font = font, size = label_size, halign = "center", valign = "center");

        x0 = port_x(group[0]) - KEYSTONE_OPENING[0] / 2;
        x1 = port_x(group[1]) + KEYSTONE_OPENING[0] / 2;
        translate([x0, line_y - line_width / 2]) square([x1 - x0, line_width]);
        translate([(x0 + x1) / 2, label_y])
          text(group_label, font = font, size = label_size, halign = "center", valign = "center");
      }

    if (cord_notch)
      translate([cord_notch_x - KEYSTONE_OPENING[0] / 2, h - cord_notch_depth, -1])
        cube([KEYSTONE_OPENING[0], cord_notch_depth + 1, KEYSTONE_DEPTH + 2]);
  }
}
