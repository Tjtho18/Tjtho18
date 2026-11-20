// Turntable animation: charger lowers onto the bracket ribs while the view rotates.
// Frames are rendered by render.sh, which sets T (0..1) and the camera per frame.
T = 0;
brick_l = 122; brick_w = 62; brick_h = 26.5;
rest_z  = 6;          // top of cooling ribs (t + rib_h)
drop_h  = 45;         // starting height above rest
drop_end = 0.35;      // fraction of the loop when the charger lands

// ease-out drop
p = min(T / drop_end, 1);
z = rest_z + drop_h * pow(1 - p, 3);

color([0.95, 0.45, 0.10]) import("../bracket.stl");

color([0.15, 0.15, 0.17])
  translate([-brick_l/2, -brick_w/2, z])
    minkowski() {
      translate([3, 3, 1]) cube([brick_l-6, brick_w-6, brick_h-2]);
      sphere(r=3, $fn=16);
    }
// logo-ish label strip on top of charger
color([0.55, 0.55, 0.6])
  translate([-20, -4, z + brick_h - 0.2]) cube([40, 8, 0.4]);
