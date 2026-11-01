// Keystone patch panel: a row of keystone jack openings in a housing behind
// the plate. Port geometry matches a reference panel known to fit the jacks
// in use; see keystone.scad.
//
// Print: front face down, no supports.
// Material: PETG.

include <rack10.scad>
include <keystone.scad>

u = 1;
ports = 12;
pitch = 18;
opening_bottom = 13.8;   // Y of the openings' bottom edge
raise = 1;               // extra plate thickness behind the face, between the rails
raise_width = 220;       // the reference panel proves this clears the rails at this depth

// Notch in the top edge for the USW-Flex power cord, which comes forward from
// behind this panel and up into the switch's DC jack in the 1U above. It is
// as wide as a port and lines up with one, near the jack.
cord_notch = true;
cord_notch_port = 11;    // counted from the left, seen from the front
cord_notch_depth = 6.5;  // from the top edge

h = rack_panel_height(u);
xs = [for (i = [0 : ports - 1]) PANEL_WIDTH / 2 + (i - (ports - 1) / 2) * pitch];

difference() {
  union() {
    rack_panel(u);
    translate([(PANEL_WIDTH - raise_width) / 2, 0, PANEL_THICKNESS])
      cube([raise_width, h, raise]);
    keystone_housing(xs, opening_bottom, PANEL_THICKNESS + raise);
  }

  for (x = xs)
    translate([x, opening_bottom, 0]) keystone_opening();

  // xs is symmetric, so it also gives port centers as seen from the front
  if (cord_notch)
    rack_front()
      translate([xs[cord_notch_port - 1] - KEYSTONE_OPENING[0] / 2, h - cord_notch_depth, -1])
        cube([KEYSTONE_OPENING[0], cord_notch_depth + 1, KEYSTONE_DEPTH + 2]);
}
