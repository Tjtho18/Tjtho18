"""Scan an ASCII STL for downward-facing surfaces that would need support.

A facet needs support if it faces down more steeply than the overhang limit
(measured from vertical) and isn't sitting on the bed (z = 0).
Usage: python3 analysis/print_check.py bracket.stl [limit_deg=45]
"""
import math, sys

path = sys.argv[1] if len(sys.argv) > 1 else "bracket.stl"
limit = float(sys.argv[2]) if len(sys.argv) > 2 else 45.0
tol = 0.5  # degrees of slack so exact-45° faces count as printable

facets, verts = [], []
for line in open(path):
    w = line.split()
    if w[:1] == ["vertex"]:
        verts.append(tuple(map(float, w[1:4])))
        if len(verts) == 3:
            facets.append(verts); verts = []

def normal_area(a, b, c):
    u = [b[i] - a[i] for i in range(3)]; v = [c[i] - a[i] for i in range(3)]
    n = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
    m = math.sqrt(sum(x*x for x in n))
    return [x/m for x in n] if m else [0, 0, 0], m/2

bad, bed, worst = 0.0, 0.0, []
MIN_AREA = 0.01  # ignore sliver facets from CSG seams
for f in facets:
    n, A = normal_area(*f)
    if n[2] >= 0 or A < MIN_AREA:
        continue
    zmin = min(p[2] for p in f)
    angle_from_vertical = math.degrees(math.asin(-n[2]))  # 0 = vertical wall, 90 = flat ceiling
    if zmin < 1e-3 and max(p[2] for p in f) < 1e-3:
        bed += A; continue
    if angle_from_vertical > limit + tol:
        bad += A
        worst.append((angle_from_vertical, zmin, A, [round(sum(p[i] for p in f)/3, 1) for i in range(3)]))

print(f"{len(facets)} facets; on bed {bed:.0f} mm^2")
print(f"downward faces steeper than {limit:.0f} deg overhang: {bad:.1f} mm^2 in {len(worst)} facets")
for ang, z, A, c in sorted(worst, reverse=True)[:12]:
    print(f"  face tilted {ang:4.1f} deg past vertical, z >= {z:.2f} mm, area {A:.3f} mm^2, near {c}")
