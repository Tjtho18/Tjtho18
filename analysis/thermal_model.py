"""Steady-state thermal model: Lenovo Legion Slim 140W adapter hung under a desk bracket.

The adapter is treated as an isothermal box (122 x 62 x 26.5 mm, emissivity 0.9).
Heat leaves by natural convection + radiation from each face:

  bottom (122x62, facing down)  hot plate facing down      Nu = 0.52 Ra^(1/5)       (Incropera 9.32, L = A/P)
  4 sides (vertical, 26.5 tall) Churchill-Chu, laminar     Nu = 0.68 + 0.670 Ra^(1/4) / [1+(0.492/Pr)^(9/16)]^(4/9)
  top (122x62, facing the plate across a gap S):
      convection across a horizontal air layer heated from below (Hollands et al.)
          Nu = 1 + 1.44 [1 - 1708/Ra]+ + [(Ra/5830)^(1/3) - 1]+     (ends treated as closed: conservative)
      + radiation between parallel grey plates, 1/(1/e1 + 1/e2 - 1)
      + conduction through the ribs
      in series with the plate (PETG/ASA) and the desk (particleboard) to room air on the desk top.
  or, for comparison, "free air": top face as a hot plate facing up, Nu = 0.54 Ra^(1/4).

All correlations are standard textbook natural-convection relations; see analysis/README.md.
"""
import math

SIGMA = 5.670e-8
G = 9.81

# adapter
LB, WB, HB = 0.122, 0.062, 0.0265
EPS = 0.90

# bracket / desk
K_PLASTIC = 0.20      # W/m-K, PETG/ASA (typical)
K_DESK = 0.12         # W/m-K, particleboard
DESK_T = 0.020        # m
H_DESK_TOP = 9.0      # W/m2-K, convection + radiation off the desk top
RIB_W, RIB_N, RIB_LEN = 0.003, 4, 0.110


def air(T):
    """Dry air at 1 atm, linear between 300 K and 350 K (Incropera Table A.4)."""
    f = (T - 300.0) / 50.0
    k = 0.0263 + f * (0.0300 - 0.0263)
    nu = 15.89e-6 + f * (20.92e-6 - 15.89e-6)
    alpha = 22.5e-6 + f * (29.9e-6 - 22.5e-6)
    return k, nu, alpha, nu / alpha


def ra(dT, L, Tf):
    k, nu, a, pr = air(Tf)
    return G * (1.0 / Tf) * dT * L**3 / (nu * a), k, pr


def h_rad(Ts, Ta, eps=EPS):
    return eps * SIGMA * (Ts**2 + Ta**2) * (Ts + Ta)


def h_down(Ts, Ta):
    L = (LB * WB) / (2 * (LB + WB))
    R, k, _ = ra(Ts - Ta, L, (Ts + Ta) / 2)
    return 0.52 * R**0.2 * k / L


def h_up(Ts, Ta):
    L = (LB * WB) / (2 * (LB + WB))
    R, k, _ = ra(Ts - Ta, L, (Ts + Ta) / 2)
    return (0.54 * R**0.25 if R < 1e7 else 0.15 * R ** (1 / 3)) * k / L


def h_vert(Ts, Ta):
    R, k, pr = ra(Ts - Ta, HB, (Ts + Ta) / 2)
    nu = 0.68 + 0.670 * R**0.25 / (1 + (0.492 / pr) ** (9 / 16)) ** (4 / 9)
    return nu * k / HB


def g_gap(Ts, Tp, S):
    """Conductance (W/K) from adapter top face to plate across the gap."""
    A = LB * WB
    dT = max(Ts - Tp, 1e-3)
    R, k, _ = ra(dT, S, (Ts + Tp) / 2)
    nu = 1 + 1.44 * max(0.0, 1 - 1708 / R) + max(0.0, (R / 5830) ** (1 / 3) - 1)
    h_conv = nu * k / S
    hr = SIGMA * (Ts**2 + Tp**2) * (Ts + Tp) / (1 / EPS + 1 / EPS - 1)
    g_ribs = K_PLASTIC * RIB_N * RIB_W * RIB_LEN / S
    rib_frac = RIB_N * RIB_W * RIB_LEN / A
    return (h_conv + hr) * A * (1 - rib_frac) + g_ribs, nu


def g_plate_to_room():
    """Plate -> desk -> room. Plate conduction, desk conduction (45 deg spread), desk top film."""
    t_plate = 0.004
    Ap = 0.122 * 0.066
    r_plate = t_plate / (K_PLASTIC * Ap)
    a1, b1 = 0.122, 0.066
    a2, b2 = a1 + 2 * DESK_T, b1 + 2 * DESK_T
    A_mean = math.sqrt(a1 * b1 * a2 * b2)
    r_desk = DESK_T / (K_DESK * A_mean)
    r_top = 1 / (H_DESK_TOP * a2 * b2)
    return 1 / (r_plate + r_desk + r_top)


def solve(Q, Ta_C, mode, S=0.003):
    """Return adapter surface temperature (C) and heat split for dissipation Q (W)."""
    Ta = Ta_C + 273.15
    A_bot = LB * WB
    A_side = 2 * (LB + WB) * HB
    A_top = LB * WB

    def balance(Ts):
        q_bot = (h_down(Ts, Ta) + h_rad(Ts, Ta)) * A_bot * (Ts - Ta)
        q_side = (h_vert(Ts, Ta) + h_rad(Ts, Ta)) * A_side * (Ts - Ta)
        if mode == "free":
            q_top = (h_up(Ts, Ta) + h_rad(Ts, Ta)) * A_top * (Ts - Ta)
        elif mode == "insulated":
            q_top = 0.0
        else:  # mounted with gap S: top -> gap -> plate -> desk -> room (series)
            gp = g_plate_to_room()
            lo, hi = Ta, Ts
            for _ in range(60):
                Tp = (lo + hi) / 2
                gg, _ = g_gap(Ts, Tp, S)
                if gg * (Ts - Tp) > gp * (Tp - Ta):
                    lo = Tp
                else:
                    hi = Tp
            q_top = gp * (Tp - Ta)
        return q_bot + q_side + q_top, (q_bot, q_side, q_top)

    lo, hi = Ta + 0.01, Ta + 200
    for _ in range(80):
        mid = (lo + hi) / 2
        if balance(mid)[0] < Q:
            lo = mid
        else:
            hi = mid
    Ts = (lo + hi) / 2
    return Ts - 273.15, balance(Ts)[1]


if __name__ == "__main__":
    import sys
    Ta = float(sys.argv[1]) if len(sys.argv) > 1 else 30.0
    print(f"Ambient under desk: {Ta:.0f} C")
    print(f"{'loss W':>7} {'free air':>9} {'gap 3mm':>8} {'gap 6mm':>8} {'gap 10mm':>9} {'top blocked':>12}")
    for Q in (5, 8, 10, 12):
        row = [solve(Q, Ta, "free")[0]]
        row += [solve(Q, Ta, "mounted", S)[0] for S in (0.003, 0.006, 0.010)]
        row += [solve(Q, Ta, "insulated")[0]]
        print(f"{Q:>7} " + " ".join(f"{v:>8.1f}C" for v in row))
    print()
    print("Gap layer Nusselt number at Ts-Tp = 20 K (Nu = 1 means pure conduction, no convection):")
    for S in (0.003, 0.006, 0.010, 0.015, 0.020):
        _, nu = g_gap(Ta + 273.15 + 40, Ta + 273.15 + 20, S)
        print(f"  S = {S*1000:4.0f} mm  Nu = {nu:.2f}")
    T, (qb, qs, qt) = solve(10, Ta, "mounted", 0.003)
    print(f"\nHeat split at 10 W, 3 mm gap: bottom {qb:.1f} W, sides {qs:.1f} W, top-to-desk {qt:.1f} W (Ts = {T:.1f} C)")


def solve_on_edge(Q, Ta_C, S=0.003):
    """Alternative layout: adapter stands on its long 26.5 mm edge, big faces vertical.

    Top (122 x 26.5) faces the plate across gap S (same series path, scaled by area);
    bottom (122 x 26.5) faces down; the two 122 x 62 faces and two 62 x 26.5 ends are vertical (L = 62 mm).
    """
    Ta = Ta_C + 273.15
    Hv = WB
    A_top = A_bot = LB * HB
    A_vert = 2 * LB * WB + 2 * WB * HB

    def hv(Ts):
        R, k, pr = ra(Ts - Ta, Hv, (Ts + Ta) / 2)
        return (0.68 + 0.670 * R**0.25 / (1 + (0.492 / pr) ** (9 / 16)) ** (4 / 9)) * k / Hv

    def hd(Ts):
        L = A_bot / (2 * (LB + HB))
        R, k, _ = ra(Ts - Ta, L, (Ts + Ta) / 2)
        return 0.52 * R**0.2 * k / L

    def total(Ts):
        q = (hd(Ts) + h_rad(Ts, Ta)) * A_bot * (Ts - Ta)
        q += (hv(Ts) + h_rad(Ts, Ta)) * A_vert * (Ts - Ta)
        hr_gap = SIGMA * (Ts**2 + Ta**2) * (Ts + Ta) / (2 / EPS - 1)
        g_top = 1 / (1 / ((0.0279 / S + hr_gap) * A_top) + 1 / (g_plate_to_room() * A_top / (LB * WB)))
        return q + g_top * (Ts - Ta)

    lo, hi = Ta, Ta + 200
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if total(mid) < Q else (lo, mid)
    return (lo + hi) / 2 - 273.15
