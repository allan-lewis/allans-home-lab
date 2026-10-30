// Dimension test print: the outline, ears, mounting holes and rear ribs of a
// full panel, with the center replaced by an open frame to save filament.
// Print one, fit it in the rack, and fold any corrections back into rack10.scad.
//
// Print: front face down, no supports.
// Material: any (test print).

include <rack10.scad>

u = 1;
frame = 6;            // width of the perimeter frame
struts = 5;           // vertical struts across the open center
strut_width = 4;

h = rack_panel_height(u);
ear = rack_ear_width();

rack_panel(u)
  // Open center, leaving a frame, solid ears and struts
  for (i = [0 : struts]) {
    x0 = ear + i * PANEL_REAR_WIDTH / (struts + 1) + (i == 0 ? 0 : strut_width / 2);
    x1 = ear + (i + 1) * PANEL_REAR_WIDTH / (struts + 1) - (i == struts ? 0 : strut_width / 2);
    translate([x0, frame]) square([x1 - x0, h - 2 * frame]);
  }
