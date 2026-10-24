// Rear-loading mount for the Ubiquiti USW-Flex-2.5G-8-PoE.
//
// The switch slides in from the rear of the rack until its face stops against
// lips at the left and right ends of the faceplate window; the window is full
// height so no port labels are covered. The switch sits high in the panel so
// the space below it makes a thick, stiff bottom wall that carries its weight.
// Power cable routing for the front DC jack is still to be designed.
//
// Print: front face down, no supports.
// Material: PETG.

include <rack10.scad>

u = 1;

// Switch: 212.9 x 99.4 x 33.5 mm (techspecs.ui.com)
switch_size = [212.9, 33.5, 99.4];   // width, height, depth
clearance = 0.3;                     // per side

lip = 4;                             // how far the side lips overlap the switch face
lip_thickness = 1.6;                 // switch face sits this far behind the panel front
top_wall = 2;                        // the bottom wall takes the rest of the panel height
sleeve_depth = 25;                   // behind the faceplate; test print length

h = rack_panel_height(u);
cavity = [switch_size[0] + 2 * clearance, switch_size[1] + 2 * clearance];
cavity_x = (PANEL_WIDTH - cavity[0]) / 2;
cavity_y = h - top_wall - cavity[1];

assert(cavity_x >= rack_ear_width() + 1.2, "sleeve side walls too thin to print");

// Front opening: the switch face minus the side lips
module window() {
  translate([cavity_x + clearance + lip, cavity_y])
    square([switch_size[0] - 2 * lip, cavity[1]]);
}

// Sleeve behind the faceplate: side walls fill the width that clears the rails
module sleeve() {
  translate([rack_ear_width(), 0, PANEL_THICKNESS])
    difference() {
      cube([PANEL_REAR_WIDTH, h, sleeve_depth]);
      translate([cavity_x - rack_ear_width(), cavity_y, -1])
        cube([cavity[0], cavity[1], sleeve_depth + 2]);
    }
}

difference() {
  union() {
    rack_panel(u) window();
    sleeve();
  }

  // Pocket for the switch nose, leaving the lips at the front
  translate([cavity_x, cavity_y, lip_thickness])
    cube([cavity[0], cavity[1], PANEL_THICKNESS]);
}
