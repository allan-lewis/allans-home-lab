// Blank panel: a 2U plate with panel-vent.scad's 1U vent field running
// across its middle. Only the outermost mounting holes are used.
//
// Print: front face down, no supports.
// Material: PETG.

include <rack10.scad>
use <vents.scad>

u = 2;
margin = 3.5;         // as on panel-vent.scad, so the field matches its 1U one
vent_d = 6.44;        // as on panel-vanity.scad
vent_web = 1.5;

h = rack_panel_height(u);
field = [PANEL_REAR_WIDTH - 2 * margin, rack_panel_height(1) - 2 * margin];
hole_ys = rack_hole_ys(u);

rack_panel(u, hole_ys = [min(hole_ys), max(hole_ys)])
  translate([rack_ear_width() + margin, (h - field[1]) / 2])
    hex_vents(field, vent_d, vent_web);
