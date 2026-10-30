// Hook for a coiled loop of network cable, screwed to one of the rack's rear
// rails through the same top and bottom hole pair and 7 x 10 mm slots as a
// 1U panel's ear.
//
// A plate the width of a panel ear sits flat on the rail. Below the screws, a
// curved band leaves the plate, runs rearward under the coil and curls up and
// back toward the plate, so the coil sits in a round-bottomed J and can't pop
// off. The coil passes in through the gap between the band's tip and the
// plate. The hook hangs below the bottom screw, leaving both screw heads clear
// and straight driver access to each.
//
// The slots are horizontal on the rail. As printed they stand upright, so
// their tops come to a 45 degree point instead of a round, which would sag.
//
// Print: on its side, no supports.
// Material: PETG.

include <rack10.scad>

coil_width = 38.1;                   // inside the J, front to back (1.5")
opening = 25.4;                      // between the tip and the plate, to pass the coil in (1")
band = 6;                            // thickness of the curved band
fillet = 6;                          // where the band meets the plate
round = 1;                           // outside corners; under half the plate's thickness
head_clearance = 6;                  // screw head radius allowance around each hole

width = rack_ear_width();            // across the rail
hole_ys = rack_hole_ys(1);
hole_r = PANEL_HOLE_D / 2;

// The J: a ring around the coil from the plate, down under it and up its far
// side, ending in a rounded tip placed to leave the opening
r_in = coil_width / 2;
r_out = r_in + band;
r_mid = r_in + band / 2;
cx = PANEL_THICKNESS + r_in;         // the coil's space touches the plate
tip_angle = acos((opening + band / 2 + PANEL_THICKNESS - cx) / r_mid);
tip_rise = r_mid * sin(tip_angle) + band / 2;  // tip's top above the ring's center
cy = hole_ys[0] - head_clearance - tip_rise;   // tip stays clear of the bottom screw head
plate_bottom = cy - r_out;
plate_top = rack_panel_height(1);

assert(opening < coil_width, "opening as wide as the hook; nothing to hold the coil");
assert(round < PANEL_THICKNESS / 2, "corner rounding would eat through the plate");

// Side profile: X rearward from the rail, Y up from the bottom of the U
module profile() {
  offset(r = round) offset(delta = -round)
    offset(r = -fillet) offset(r = fillet)
      union() {
        translate([0, plate_bottom]) square([PANEL_THICKNESS, plate_top - plate_bottom]);
        // Band from the plate (180 degrees) clockwise around to the tip,
        // trimmed to stay off the rail
        intersection() {
          translate([cx, cy])
            polygon(concat(
              [for (a = [-180 : 5 : tip_angle]) r_out * [cos(a), sin(a)]],
              [r_out * [cos(tip_angle), sin(tip_angle)], r_in * [cos(tip_angle), sin(tip_angle)]],
              [for (a = [tip_angle : -5 : -180]) r_in * [cos(a), sin(a)]]
            ));
          translate([0, plate_bottom]) square([cx + r_out, 2 * r_out]);
        }
        translate([cx, cy] + r_mid * [cos(tip_angle), sin(tip_angle)]) circle(d = band, $fn = 32);
      }
}

// A 7 x 10 mm slot, long across the rail, with a pointed top as printed
module slot_2d() {
  hull()
    for (dz = [-PANEL_HOLE_SLOT / 2, PANEL_HOLE_SLOT / 2]) {
      translate([dz, 0]) circle(r = hole_r, $fn = 48);
      // 45 degree point on the upper end, which faces up in the print
      if (dz < 0) translate([dz - hole_r * sqrt(2), 0]) circle(r = 0.01, $fn = 4);
    }
}

difference() {
  linear_extrude(width) profile();
  for (y = hole_ys)
    translate([-1, y, width / 2])
      rotate([0, 90, 0])
        linear_extrude(PANEL_THICKNESS + 2) slot_2d();
}
