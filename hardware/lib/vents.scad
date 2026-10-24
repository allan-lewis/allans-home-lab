// Vent hole patterns, as 2D shapes for use as panel cutouts.

// Diamonds on a staggered grid, filling a size = [w, h] rectangle anchored at
// the origin. Only whole diamonds that fit are kept, and the pattern is
// centered in the rectangle.
//   d    diamond width and height, point to point
//   web  solid material between neighboring diamonds
module diamond_vents(size, d = 7, web = 2) {
  pitch = d + web * sqrt(2);         // center spacing along a row
  r = d / 2;

  cols = floor(size[0] / pitch) + 1;
  rows = floor(size[1] / (pitch / 2)) + 1;
  centers = [
    for (j = [0 : rows - 1], i = [0 : cols - 1])
      let (x = r + i * pitch + (j % 2) * pitch / 2, y = r + j * pitch / 2)
      if (x + r <= size[0] && y + r <= size[1]) [x, y]
  ];

  // Shift so the pattern's extents are centered in the rectangle
  xs = [for (c = centers) c[0]];
  ys = [for (c = centers) c[1]];
  offset = [
    (size[0] - (max(xs) + r) - (min(xs) - r)) / 2,
    (size[1] - (max(ys) + r) - (min(ys) - r)) / 2,
  ];

  for (c = centers)
    translate(c + offset) rotate(45) square(d / sqrt(2), center = true);
}

// Pointy-top hexagons in a honeycomb, clipped to a size = [w, h] rectangle
// anchored at the origin so its edges read as a solid frame. The grid is
// centered on the rectangle, so centered layouts stay symmetric.
//   d            hexagon width, flat to flat
//   web          solid material between neighboring hexagons
//   keepout      [x, y, w, h] rectangles to leave solid, also clipping the hexagons
//   min_feature  partial hexagons narrower than this are dropped, since they print poorly
module hex_vents(size, d = 6, web = 1.5, keepout = [], min_feature = 1) {
  pitch = d + web;                   // center spacing along a row
  row = pitch * sqrt(3) / 2;         // spacing between rows
  c = size / 2;
  nx = ceil(size[0] / pitch / 2) + 1;
  ny = ceil(size[1] / row / 2) + 1;

  offset(delta = min_feature / 2) offset(delta = -min_feature / 2)
    difference() {
      intersection() {
        square(size);
        for (j = [-ny : ny], i = [-nx : nx])
          translate([c[0] + (i + (abs(j) % 2) / 2) * pitch, c[1] + j * row])
            rotate(90) circle(r = d / sqrt(3), $fn = 6);
      }
      for (k = keepout) translate([k[0], k[1]]) square([k[2], k[3]]);
    }
}
