// Branded panel: a framed honeycomb vent field centered on the panel, with a
// solid block in its middle that has the site name cut through it. The stencil font
// keeps letter centers (a, o, e, b) attached to the panel.
//
// Print: front face down, no supports.
// Material: PETG.

include <rack10.scad>
use <vents.scad>
use <../fonts/BigShouldersStencil-Variable.ttf>

u = 1;
label = "allanshomelab.com";
font = "Big Shoulders Stencil:style=Bold";
text_width = 130;     // text is scaled to exactly this width (about 14 mm tall)
text_inset = 0.3;     // shrink letters on every edge, widening the stencil bridges
block = [135, 18];    // solid inner frame around the text, ~2 mm clear of the letters
margin = 3.5;         // outer frame around the vent field, inside the ears and top/bottom edges
vent_web = 1.5;

h = rack_panel_height(u);
ear = rack_ear_width();
field = [PANEL_REAR_WIDTH - 2 * margin, h - 2 * margin];

// Size the hexagons so the second row out from the centerline lands midway
// between the inner and outer frames: one full row there, with clipped rows
// against each frame. Row spacing is (d + web) * sqrt(3) / 2.
band_mid = (block[1] + field[1]) / 4;
vent_d = band_mid / sqrt(3) - vent_web;
assert(vent_d / sqrt(3) < (field[1] - block[1]) / 4, "hexagons too tall for a full row between the frames");

rack_panel(u) {
  translate([ear + margin, margin])
    hex_vents(field, vent_d, vent_web, keepout = [[
      (field[0] - block[0]) / 2, (field[1] - block[1]) / 2, block[0], block[1]
    ]]);

  translate([PANEL_WIDTH / 2, h / 2])
    offset(delta = -text_inset)
      resize([text_width, 0], auto = true)
        text(label, font = font, size = 10, halign = "center", valign = "center");
}
