// Vent panel: one framed honeycomb vent field filling the panel between the
// ears. The vanity panel's field without its center block and text; the
// hexagons match panel-vanity.scad.
//
// Print: front face down, no supports.
// Material: PETG.

include <rack10.scad>
use <vents.scad>

u = 1;
margin = 3.5;         // frame around the vent field, inside the ears and top/bottom edges
vent_d = 6.44;        // as on panel-vanity.scad
vent_web = 1.5;

h = rack_panel_height(u);
field = [PANEL_REAR_WIDTH - 2 * margin, h - 2 * margin];

rack_panel(u)
  translate([rack_ear_width() + margin, margin])
    hex_vents(field, vent_d, vent_web);
