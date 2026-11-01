// Rear-loading mount for the Ubiquiti USW-Flex-2.5G-8-PoE.
//
// The switch slides in from the rear of the rack until its face stops against
// lips at the left and right ends of the faceplate window; the window is full
// height so no port labels are covered. The switch sits high in the panel so
// the space below it makes a thick, stiff bottom wall that carries its weight.
// The top is open between solid strips along each side, and the bottom has
// large hexagonal openings, so the switch's vents stay clear.
//
// Two bumps on the bottom wall's rear band hold the switch in. There is a
// little headroom above the switch behind the faceplate, so their ramps lift
// it as it slides in and it drops in front of them, where their square faces
// stop it being pushed back. To remove the switch, lift its rear edge over the
// bumps and slide it out.
//
// The power cord comes up through a notch in the keystone panel below and
// into the switch's DC jack at the front; see panel-keystone.scad.
//
// Print: front face down, no supports.
// Material: PETG.

include <rack10.scad>
include <vents.scad>

u = 1;

// Switch: 212.9 x 99.4 x 33.5 mm (techspecs.ui.com)
switch_size = [212.9, 33.5, 99.4];   // width, height, depth
clearance = 0.3;                     // per side
depth_clearance = 0.5;               // between the switch's back and the bumps

lip = 4;                             // how far the side lips overlap the switch face
lip_thickness = 1.6;                 // switch face sits this far behind the panel front
top_wall = 2;                        // the bottom wall takes the rest of the panel height

// Retaining bumps
bumps = 2;
bump_spacing = 100;                  // center to center
bump_width = 10;
bump_height = 1.2;                   // also the headroom above the switch behind the faceplate
ramp_length = 8;

// Openings in the top and bottom walls. The bottom's hexagons are sized after
// the reference mount (see hardware/reference), whose large openings leave the
// switch's vents clear.
vent_front = 10;                     // solid band behind the faceplate, where the load is highest
top_strip = 30;                      // solid top over each end of the switch; open between, through to the rear
vent_margin = 4;                     // solid border inside the side walls, on the bottom
bottom_hex = 14;                     // hexagon width, flat to flat
bottom_web = 4;

h = rack_panel_height(u);
cavity = [switch_size[0] + 2 * clearance, switch_size[1] + 2 * clearance];
cavity_x = (PANEL_WIDTH - cavity[0]) / 2;
cavity_y = h - top_wall - bump_height - cavity[1];

catch_z = lip_thickness + switch_size[2] + depth_clearance;
sleeve_end = catch_z + ramp_length;

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
      cube([PANEL_REAR_WIDTH, h, sleeve_end - PANEL_THICKNESS]);
      translate([cavity_x - rack_ear_width(), cavity_y, -1])
        cube([cavity[0], cavity[1] + bump_height, sleeve_end]);
    }
}

// Bumps on the cavity floor behind the switch
module bumps() {
  for (i = [0 : bumps - 1])
    translate([PANEL_WIDTH / 2 + (i - (bumps - 1) / 2) * bump_spacing - bump_width / 2, 0, 0])
      // Side profile (Y, Z): a square face toward the switch, ramp toward the rear
      rotate([90, 0, 90])
        linear_extrude(bump_width)
          polygon([
            [cavity_y - 0.01, catch_z],
            [cavity_y + bump_height, catch_z],
            [cavity_y + bump_height, catch_z + 0.6],
            [cavity_y - 0.01, sleeve_end],
          ]);
}

// Cuts 2D children, drawn in X/Z from the cavity's front left corner behind
// the solid band, through a wall spanning y0..y1
module wall_cut(y0, y1) {
  translate([cavity_x, y1 + 1, PANEL_THICKNESS + vent_front])
    rotate([90, 0, 0])
      linear_extrude(y1 - y0 + 2) children();
}

open_length = sleeve_end - PANEL_THICKNESS - vent_front;
// The bottom stops short of the bumps, leaving a solid band across the rear
bottom_area = [cavity[0] - 2 * vent_margin, catch_z - bottom_web - PANEL_THICKNESS - vent_front];

difference() {
  union() {
    rack_panel(u) window();
    sleeve();
  }

  // Pocket for the switch nose, leaving the lips at the front
  translate([cavity_x, cavity_y, lip_thickness])
    cube([cavity[0], cavity[1], PANEL_THICKNESS]);

  wall_cut(0, cavity_y)
    translate([vent_margin, 0]) hex_vents(bottom_area, d = bottom_hex, web = bottom_web);
  wall_cut(h - top_wall, h)
    translate([top_strip, 0]) square([cavity[0] - 2 * top_strip, open_length + 1]);
}

bumps();
