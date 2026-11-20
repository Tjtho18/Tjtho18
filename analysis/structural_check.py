"""Hand calculations for the strap zones and screws of bracket.scad.

Strap routing assumed (the only routing possible with the plate screwed to a desk):
the strap passes out through a lip slot, wraps around the lip tip and back under the
charger, so the strip of lip between the slot and the tip (the "tip ligament") carries
both strap legs, about 2T. It is treated as a beam spanning the slot length, with its ends
held by the gussets (fixed-fixed), loaded uniformly.
"""
import math, sys

def check(Ls, lip_t, slot_gap, slot_off, slot_len, T, label):
    tip_lig = Ls - slot_off - slot_gap      # depth of tip ligament (in the lip plane)
    root_lig = slot_off
    w = 2 * T / slot_len                    # N/mm, both strap legs over the slot length
    M_ff = w * slot_len**2 / 12             # fixed-fixed, max at supports
    M_ss = w * slot_len**2 / 8              # simply supported (gussets not counted)
    # strap pull is roughly 45 deg to the lip plane: in-plane and out-of-plane components
    Fc = math.cos(math.radians(45))
    Z_in = lip_t * tip_lig**2 / 6           # bending in the lip plane
    Z_out = tip_lig * lip_t**2 / 6          # bending out of the lip plane
    s_ff = Fc * M_ff / Z_in + Fc * M_ff / Z_out
    s_ss = Fc * M_ss / Z_in + Fc * M_ss / Z_out
    print(f"{label}: tip ligament {tip_lig:.1f} x {lip_t:.1f} mm, root ligament {root_lig:.1f} mm")
    print(f"   T = {T:>4.0f} N per strap -> peak bending stress {s_ff:5.1f} MPa (gussets fixing ends), "
          f"{s_ss:5.1f} MPa (no end fixity)")
    return s_ff

if __name__ == "__main__":
    for T in (30, 60, 120):
        check(12, 4, 4, 4, 27.4, T, "current  (Ls 12, slot centered)")
        check(16, 4, 4, 4, 27.4, T, "proposed (Ls 16, slot 4 mm from root)")
        print()
