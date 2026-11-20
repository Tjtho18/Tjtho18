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


def section(P):
    """Area, centroid and section moduli of a polygon (local y = depth in lip plane, z = thickness)."""
    n = len(P); A = cx = cz = 0.0
    for i in range(n):
        (x0, y0), (x1, y1) = P[i], P[(i + 1) % n]
        c = x0 * y1 - x1 * y0; A += c; cx += (x0 + x1) * c; cz += (y0 + y1) * c
    A /= 2; cx /= 6 * A; cz /= 6 * A
    Iz = Iy = 0.0
    for i in range(n):
        (x0, y0), (x1, y1) = P[i], P[(i + 1) % n]
        x0 -= cx; x1 -= cx; y0 -= cz; y1 -= cz; c = x0 * y1 - x1 * y0
        Iz += (y0 * y0 + y0 * y1 + y1 * y1) * c; Iy += (x0 * x0 + x0 * x1 + x1 * x1) * c
    xs = [p[0] for p in P]; zs = [p[1] for p in P]
    return A, (Iy / 12) / max(cx - min(xs), max(xs) - cx), (Iz / 12) / max(cz - min(zs), max(zs) - cz)


def current_design(Ls=16, lip_t=5, slot_off=4, slot_gap=4, slot_len=27.4, c=1.0, cu=0.3):
    y0 = slot_off + slot_gap
    P = [(y0 + cu, 0), (Ls - c, 0), (Ls, c), (Ls, lip_t - c), (Ls - c, lip_t), (y0 + c, lip_t), (y0, lip_t - c), (y0, cu)]
    A, Zin, Zout = section(P)
    print(f"As built (chamfered tip strip {Ls - y0} x {lip_t} mm): area {A:.1f} mm^2, Z {Zin:.1f} / {Zout:.1f} mm^3")
    for T in (30, 60, 130):
        M = 2 * T / slot_len * slot_len**2 / 12
        s = math.cos(math.radians(45)) * M * (1 / Zin + 1 / Zout)
        print(f"   T = {T:>4.0f} N -> {s:5.1f} MPa (gussets fixing ends), {1.5 * s:5.1f} MPa (no end fixity)")
    print("   Compare: printed ASA tensile 37-44 MPa XY (data sheets); less when warm.")


if __name__ == "__main__":
    print()
    current_design()
