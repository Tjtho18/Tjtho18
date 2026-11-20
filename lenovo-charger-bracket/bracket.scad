// Under-desk bracket for Lenovo Legion Slim 140W charger (122 x 62 x 26.5 mm)
// Prints desk-side down (z = 0 is the desk face), no supports. PETG or ASA.

// ---- Charger / plate ----
brick_l = 122;  brick_w = 62;
side_clr = 2;               // clearance per long side
t = 3;                      // wall / plate thickness
L   = 148;                  // plate length
Wp  = brick_w + 2*side_clr; // flat plate width (66)

// ---- Side lips ----
Ls  = 12;  ang = 45;        // lip width, angle away from desk

// ---- Strap slots (in lips) ----
strap_w = 25.4; strap_clr = 2;   // 1" strap + extra slot length
slot_gap = 4; strap_x = 35;

// ---- Lip vents ----
vent_d = 5;  vent_x = 8;              // center oval: two d=vent_d circles at ±vent_x, hulled
win_x = 60;  win_l = 12;  win_w = 5;  // outer vent windows

// ---- Screw holes (#8 countersunk) ----
screw_d = 4.5; head_d = 9; hole_x = 68; hole_y = 20;

// ---- Cooling ribs ----
rib_h = 3;  rib_w = 3;  rib_len = 110;
rib_y = [-24, -8, 8, 24];

$fn = 48;

module lip() {
  translate([0, Wp/2, 0]) rotate([ang, 0, 0])
  difference() {
    translate([-L/2, 0, 0]) cube([L, Ls, t]);
    for (sx = [-1, 1])
      translate([sx*strap_x, Ls/2, t/2])
        cube([strap_w+strap_clr, slot_gap, t+2], center=true);
    hull() for (sx = [-1, 1])
      translate([sx*vent_x, Ls/2, -1]) cylinder(d=vent_d, h=t+2);
    for (sx = [-1, 1])
      translate([sx*win_x, Ls/2, t/2])
        cube([win_l, win_w, t+2], center=true);
  }
}

difference() {
  union() {
    translate([-L/2, -Wp/2, 0]) cube([L, Wp, t]);
    for (y = rib_y)
      translate([-rib_len/2, y - rib_w/2, t]) cube([rib_len, rib_w, rib_h]);
    lip();
    mirror([0, 1, 0]) lip();
  }
  for (sx = [-1, 1], sy = [-1, 1])
    translate([sx*hole_x, sy*hole_y, 0]) {
      translate([0, 0, -1]) cylinder(d=screw_d, h=t+2);
      translate([0, 0, t - (head_d-screw_d)/2])
        cylinder(d1=screw_d, d2=head_d, h=(head_d-screw_d)/2 + 0.01);
    }
}
