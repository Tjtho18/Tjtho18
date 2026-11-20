// Under-desk bracket for Lenovo Legion Slim 140W charger (GX21M50625, 122 x 62 x 26.5 mm)
// Prints desk-side down (z = 0 is the desk face), no supports. PETG or ASA.
//
// Strap-zone design:
//  - Each strap slot is centered between the center vent and the lip end, so the
//    solid ligament is equal on both sides of the slot (see `lig`).
//  - Slots are stadium-shaped (full-radius ends): no sharp corners to start cracks
//    or chafe the strap.
//  - No openings between a slot and the lip end.
//  - Lips are thicker than the plate, and triangular gussets on the desk side brace
//    each lip root on both sides of every slot. The gussets sit on the print bed,
//    so they need no supports, and they bear against the desk once mounted.

// ---- Charger / plate ----
brick_l = 122;  brick_w = 62;
side_clr = 2;               // clearance per long side
t = 4;                      // plate thickness
end_clr = 0;                // extra plate length past each charger end
L   = brick_l + 2*end_clr;  // plate length (122)
Wp  = brick_w + 2*side_clr; // flat plate width (66)

// ---- Side lips ----
Ls    = 12;  ang = 45;      // lip width, angle away from desk
lip_t = 4;                  // lip thickness

// ---- Center lip vent (oval) ----
vent_d = 5;  vent_x = 8;    // two d=vent_d circles at ±vent_x, hulled
vent_end = vent_x + vent_d/2;

// ---- Strap slots (1" straps) ----
strap_w   = 25.4;           // strap width
strap_clr = 2;              // total extra slot length (1 mm per side)
slot_gap  = 4;              // slot width (strap thickness room)
slot_len  = strap_w + strap_clr;
strap_x   = (vent_end + L/2) / 2;          // slot center: equal ligaments both sides
lig       = strap_x - slot_len/2 - vent_end; // solid lip each side of a slot

// ---- Lip gussets (desk side) ----
gusset_t = 3;               // thickness along x
// one gusset hugging each end of each slot, plus one at each lip end
gusset_x = [ for (sx = [-1, 1]) for (x = [strap_x - slot_len/2 - gusset_t/2,
                                          strap_x + slot_len/2 + gusset_t/2,
                                          L/2 - gusset_t/2]) sx*x ];

// ---- Screw holes (#8 flat head, 82° countersink) ----
screw_d = 4.5; head_d = 9; cs_angle = 82;
cs_h    = (head_d - screw_d) / 2 / tan(cs_angle/2);
hole_x  = 40;               // under the charger, inboard of the rib ends

// ---- Cooling ribs ----
rib_h = 3;  rib_w = 3;  rib_len = 110;
rib_y = [-24, -8, 8, 24];
hole_y = (rib_y[2] + rib_y[3]) / 2;   // centered in the channel between ribs 3 and 4 (and mirror)

assert(lig >= 8, "strap ligament too thin");
assert(slot_gap <= Ls - 6, "slot leaves < 3 mm of lip on either side");
assert(t - cs_h >= 1, "countersink leaves < 1 mm of straight bore");
assert(rib_y[3] - rib_y[2] - rib_w >= head_d + 2, "screw head doesn't fit between ribs");
assert(hole_x + head_d/2 <= rib_len/2, "screw head past rib ends");

$fn = 48;

module stadium(len, w, h) {   // slot with full-radius ends, centered in x/y, z from 0..h
  hull() for (sx = [-1, 1]) translate([sx*(len - w)/2, 0, 0]) cylinder(d=w, h=h);
}

module lip() {
  translate([0, Wp/2, 0]) rotate([ang, 0, 0])
  difference() {
    translate([-L/2, 0, 0]) cube([L, Ls, lip_t]);
    for (sx = [-1, 1])
      translate([sx*strap_x, Ls/2, -1]) stadium(slot_len, slot_gap, lip_t + 2);
    translate([0, Ls/2, -1]) stadium(2*vent_x + vent_d, vent_d, lip_t + 2);
  }
  // gussets: triangle in the y-z plane under the lip, flat on the desk plane
  yt = Wp/2 + (Ls - 1)*cos(ang);
  zt = (Ls - 1)*sin(ang);
  for (x = gusset_x)
    translate([x - gusset_t/2, 0, 0]) rotate([90, 0, 90])
      linear_extrude(gusset_t)
        polygon([[Wp/2 - 1, 0], [yt, 0], [yt, zt + 0.5], [Wp/2 - 1, 0.5]]);
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
      translate([0, 0, -1]) cylinder(d=screw_d, h=t + 2);
      translate([0, 0, t - cs_h])
        cylinder(d1=screw_d, d2=head_d, h=cs_h + 0.01);
    }
}

echo(strap_x = strap_x, ligament_each_side = lig, countersink_depth = cs_h);
