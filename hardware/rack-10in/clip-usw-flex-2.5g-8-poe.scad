// Rear retaining clips for the USW-Flex-2.5G-8-PoE mount
// (mount-usw-flex-2.5g-8-poe.scad).
//
// The switch's rounded face pokes forward through the faceplate window, so it
// sits further forward than the mount allows for, and its back stops short of
// the mount's bumps. A clip drops straight down over each bump from above: a
// pocket under it fits over the bump, a spine hangs down behind the rear edge
// of the bottom wall, and a finger at the front stands up behind the switch.
// Pushing the switch back presses the pocket against the bump's square face
// and the spine against the wall, so the clip can't slide or tip back. Lift
// the clips out to remove the switch.
//
// gap is the distance from the switch's back to the bumps' square faces, with
// the switch pushed fully forward. Without a measurement, print one clip of
// each size, use the largest that drops in, then print a pair of that size.
// Each clip has its gap engraved on its side.
//
// Print: on its side, no supports.
// Material: PETG.

include <rack10.scad>

gaps = [2, 3, 4, 5];                 // one clip per entry, in mm
fit = 0.3;                           // between the finger and the switch
clearance = 0.2;                     // around the bump and the wall's rear edge

finger_height = 10;                  // above the mount's floor
finger_thickness = 3;
jaw_thickness = 3;                   // over the floor, around the bump pocket
spine_thickness = 2.5;
side = 5;                            // width beside the bump, each side
label_depth = 0.6;

// Mount values; keep these in step with mount-usw-flex-2.5g-8-poe.scad
switch_height = 33.5;
switch_depth = 99.4;
mount_clearance = 0.3;
depth_clearance = 0.5;
lip_thickness = 1.6;
top_wall = 2;
bump_width = 10;
bump_height = 1.2;
ramp_length = 8;

// Derived as in the mount, measured from the panel's front face (depth) and
// bottom edge (height)
floor_y = rack_panel_height(1) - top_wall - bump_height - (switch_height + 2 * mount_clearance);
catch_z = lip_thickness + switch_depth + depth_clearance;
sleeve_end = catch_z + ramp_length;

width = bump_width + 2 * (clearance + side);
spine_z = sleeve_end + clearance;
top = floor_y + finger_height;

for (gap = gaps)
  assert(gap - fit - clearance >= 1.2, str("gap ", gap, " leaves too little clip in front of the bump"));

// One clip, laid on its side: X is depth into the mount, Y is height in the
// mount, Z is across the mount
module clip(gap) {
  front = catch_z - gap + fit;
  gusset = finger_height - jaw_thickness;

  difference() {
    linear_extrude(width)
      polygon([
        [front, floor_y],
        [front, top - 1],
        [front + 1, top],
        [front + finger_thickness, top],
        [min(front + finger_thickness + gusset, spine_z), floor_y + jaw_thickness],
        [spine_z + spine_thickness, floor_y + jaw_thickness],
        [spine_z + spine_thickness, 0],
        [spine_z, 0],
        [spine_z, floor_y],
      ]);

    // Pocket over the bump, open underneath
    translate([catch_z - clearance, floor_y - 1, side])
      cube([spine_z - catch_z + clearance, bump_height + clearance + 1, bump_width + 2 * clearance]);

    // Gap label, engraved in the face beside the gusset
    translate([front + finger_thickness + 0.5, floor_y + jaw_thickness + 0.4, width - label_depth])
      linear_extrude(label_depth + 1)
        text(str(gap), size = 3, halign = "left", valign = "bottom");
  }
}

for (i = [0 : len(gaps) - 1])
  translate([-(catch_z - gaps[i] + fit), i * (top + 4), 0])
    clip(gaps[i]);
