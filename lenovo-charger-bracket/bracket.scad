// Under-desk bracket for Lenovo Legion Slim 140W charger (GX21M50625, 122 x 62 x 26.5 mm)
// Prints desk-side down (z = 0 is the desk face), no supports. Material: ASA (PETG only if the
// charger case measures below ~50 °C under load; see analysis/README.md).
//
// Thermal design: the charger's large top face is its best-cooling face. A 3 mm gap under a
// plate is pure conduction (Ra << 1708) and traps it, so the charger stands on six posts with
// a 12 mm open gap: warm air can rise off that face and escape on all four sides.
//
// Strap-zone design:
//  - Each strap slot is centered between the center vent and the lip end, so the
//    solid ligament is equal on both sides of the slot (see `lig`).
//  - Slots are stadium-shaped (full-radius ends): no sharp corners to start cracks
//    or chafe the strap.
//  - No openings between a slot and the lip end.
//  - The strip between each slot and the lip tip carries both strap legs; it is sized
//    so a 130 N strap (strong 1" hook-and-loop) breaks before the bracket does.
//  - Lips are thicker than the plate, filleted at the root, and triangular gussets on the desk side brace
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
Ls    = 16;  ang = 45;      // lip width, angle away from desk
lip_t = 5;                  // lip thickness
root_r = 3;                 // fillet radius, inside corner where lip meets plate (charger side)
edge_c = 1;                 // chamfer on strap-bearing edges that print cleanly
edge_c_under = 0.3;         // desk-side slot mouth: kept small so its downward ledge (~0.42 mm) is under one line width

// ---- Center lip vent (oval) ----
vent_d = 5;  vent_x = 8;    // two d=vent_d circles at ±vent_x, hulled
vent_end = vent_x + vent_d/2;

// ---- Strap slots (1" straps) ----
strap_w   = 25.4;           // strap width
strap_clr = 2;              // total extra slot length (1 mm per side)
slot_gap  = 4;              // slot width (strap thickness room)
slot_len  = strap_w + strap_clr;
slot_off  = 4;              // slot edge distance from lip root; the rest of the lip is the tip strip
tip_lig   = Ls - slot_off - slot_gap;  // strip between slot and lip tip: carries both strap legs
strap_x   = (vent_end + L/2) / 2;          // slot center: equal ligaments both sides
lig       = strap_x - slot_len/2 - vent_end; // solid lip each side of a slot

// ---- Lip gussets (desk side) ----
gusset_t = 3;               // thickness along x
// one gusset hugging each end of each slot, plus one at each lip end
gusset_x = [ for (sx = [-1, 1]) for (x = [strap_x - slot_len/2 - gusset_t/2,
                                          strap_x + slot_len/2 + gusset_t/2,
                                          L/2 - gusset_t/2]) sx*x ];

// ---- Screw holes (#8) ----
// "counterbore": flat seat for a pan/truss/washer-head screw (recommended: no wedge load on the
// plastic, slower clamp-load loss when warm). "countersink": 82° seat for flat-head screws.
head_style = "counterbore";
screw_d = 4.9;              // #8 = 4.17 mm; FDM holes print ~0.2-0.3 mm small, so 4.9 lands ~4.6-4.7
cb_d = 11;  cb_depth = 1.5;          // fits #8 pan head + #8 washer, or #8 truss head
head_d = 9; cs_angle = 82;           // countersink option
cs_h    = (head_d - screw_d) / 2 / tan(cs_angle/2);
seat_d  = head_style == "counterbore" ? cb_d : head_d;
hole_x  = 36;  hole_y = 16; // under the charger, clear of the posts

// ---- Charger standoff ----
// "posts" (recommended): open gap, air escapes on all sides.
// "ribs": original lengthwise ribs (channels open only at the ends).
standoff = "posts";
gap_h  = 12;                // post height = air gap under the charger
post_d = 10;  post_base = 2; // post diameter; flared base (fillet stand-in) height/width
post_x = [-(brick_l/2 - 10), 0, brick_l/2 - 10];
post_y = [-(brick_w/2 - 9), brick_w/2 - 9];
rib_h = 3;  rib_w = 3;  rib_len = 110;
rib_y = [-24, -8, 8, 24];
stand_h = standoff == "posts" ? gap_h : rib_h;   // charger rests at z = t + stand_h

assert(lig >= 8, "strap ligament too thin");
assert(slot_off >= 4 && tip_lig >= 8, "strap slot edge material too thin (see analysis/structural_check.py)");
assert(head_style != "countersink" || t - cs_h >= 1, "countersink leaves < 1 mm of straight bore");
assert(head_style != "counterbore" || t - cb_depth >= 2.5, "counterbore leaves < 2.5 mm under the head");
assert(standoff != "ribs" || rib_y[3] - rib_y[2] - rib_w >= seat_d + 1, "screw seat doesn't fit between ribs");
assert(standoff != "ribs" || abs(hole_y - (rib_y[2] + rib_y[3])/2) < 0.01, "set hole_y to the channel center for ribs");
assert(standoff != "posts" || min([for (px = post_x, py = post_y)
         norm([hole_x - abs(px), hole_y - abs(py)])]) >= post_d/2 + post_base + seat_d/2 + 1,
       "screw seat too close to a post");
assert(standoff != "posts" || gap_h >= 10, "gap below ~10 mm stays conduction-only (Ra < 1708)");
assert(lip_t*cos(ang) < t, "lip inner face must meet the plate top for the root fillet");

$fn = 48;

module stadium(len, w, h) {   // slot with full-radius ends, centered in x/y, z from 0..h
  hull() for (sx = [-1, 1]) translate([sx*(len - w)/2, 0, 0]) cylinder(d=w, h=h);
}

// Fillet in the 135° inside corner between the plate top and the lip's inner face.
module root_fillet() {
  p0  = [Wp/2 - lip_t*sin(ang), lip_t*cos(ang)];          // inner face, at the lip root
  c   = [p0[0] + (t - p0[1]) / tan(ang), t];              // corner on the plate top
  tl  = root_r * tan((180 - (180 - ang)) / 2);            // tangent length = R*tan(ang/2)
  t1  = [c[0] - tl, t];                                   // tangent point on plate
  t2  = [c[0] + tl*cos(ang), t + tl*sin(ang)];            // tangent point on lip face
  ctr = [t1[0], t + root_r];                              // fillet arc center
  translate([-L/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(L)
    difference() {
      polygon([t1, c - [0, 0.01], t2, ctr]);
      translate(ctr) circle(r=root_r, $fn=64);
    }
}

// Slot through the lip with chamfered mouths so the strap doesn't run over sharp edges.
module strap_slot() {
  translate([0, 0, -1]) stadium(slot_len, slot_gap, lip_t + 2);
  hull() {                                          // inner (charger-side) mouth
    translate([0, 0, lip_t - edge_c]) stadium(slot_len, slot_gap, 0.01);
    translate([0, 0, lip_t]) stadium(slot_len + 2*edge_c, slot_gap + 2*edge_c, 0.01);
  }
  hull() {                                          // outer (desk-side) mouth
    translate([0, 0, edge_c_under]) stadium(slot_len, slot_gap, 0.01);
    translate([0, 0, -0.01]) stadium(slot_len + 2*edge_c_under, slot_gap + 2*edge_c_under, 0.01);
  }
}

module lip() {
  translate([0, Wp/2, 0]) rotate([ang, 0, 0])
  difference() {
    // lip cross-section with the tip edges chamfered (the strap wraps around the tip)
    translate([-L/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(L)
      polygon([[0, 0], [Ls - edge_c, 0], [Ls, edge_c], [Ls, lip_t - edge_c], [Ls - edge_c, lip_t], [0, lip_t]]);
    for (sx = [-1, 1])
      translate([sx*strap_x, slot_off + slot_gap/2, 0]) strap_slot();
    translate([0, slot_off + slot_gap/2, -1]) stadium(2*vent_x + vent_d, vent_d, lip_t + 2);
  }
  root_fillet();
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
    if (standoff == "ribs")
      for (y = rib_y)
        translate([-rib_len/2, y - rib_w/2, t]) cube([rib_len, rib_w, rib_h]);
    else
      for (px = post_x, py = post_y) translate([px, py, t - 0.01]) {
        cylinder(d=post_d, h=gap_h + 0.01);
        cylinder(d1=post_d + 2*post_base, d2=post_d, h=post_base);
      }
    lip();
    mirror([0, 1, 0]) lip();
  }
  for (sx = [-1, 1], sy = [-1, 1])
    translate([sx*hole_x, sy*hole_y, 0]) {
      translate([0, 0, -1]) cylinder(d=screw_d, h=t + 2);
      if (head_style == "countersink")
        translate([0, 0, t - cs_h]) cylinder(d1=screw_d, d2=head_d, h=cs_h + 0.01);
      else
        translate([0, 0, t - cb_depth]) cylinder(d=cb_d, h=cb_depth + 0.01);
    }
}

echo(strap_x = strap_x, ligament_each_side = lig, tip_strip = tip_lig, head_style = head_style,
     standoff = standoff, charger_rests_at = t + stand_h);
