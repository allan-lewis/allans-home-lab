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
}
