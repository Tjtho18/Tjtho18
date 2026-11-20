# Engineering review: under-desk bracket, Lenovo Legion Slim 140W (GX21M50625)

Charger: 122 x 62 x 26.5 mm (Lenovo product page), about 328 g (retailer listing).
Bracket: `bracket.scad` (all dimensions are parameters). Checks: `print_check.py`, `structural_check.py`, `thermal_model.py`.

Note on sources: this environment blocks most manufacturer sites, so figures come from search-result
snippets of the pages listed at the end, not from reading the full documents. Numbers marked
"analysis" are calculations in this folder.

## 1. Weak points found and what was done

| # | Weak point | Evidence | Fix in the current design |
|---|---|---|---|
| 1 | Strip of lip between strap slot and lip tip carries both legs of the strap (the strap must wrap the lip tip because the plate is screwed to the desk). At 4 x 4 mm it reached 36 MPa at 60 N strap tension, about the tensile strength of printed ASA (37-44 MPa XY). | analysis, `structural_check.py` | Lip widened to 16 mm and thickened to 5 mm; slot moved to 4 mm from the root, so the tip strip is 8 x 5 mm. With the edge chamfers: about 5 MPa at a normal 30 N cinch (7-8x margin on ASA's 37-44 MPa), and 23-34 MPa at 130 N, the rated break load of a strong 1" hook-and-loop strap (23 MPa with the gussets holding the strip ends, 34 MPa if they didn't). So the bracket survives anything the strap can apply, with a thin margin only in that worst case. |
| 2 | Lip root bends across layer lines (printed at 45°, layers horizontal); Z strength is 60-85% of XY. | materials research | 3 mm fillet at the inside corner, 5 mm lip, desk-side gussets on both sides of every slot and at the lip ends. |
| 3 | Sharp slot corners and sharp lip tip: crack starters, strap chafe. | design guides | Stadium (full-radius) slots; 1 mm chamfers on the lip tip and the charger-side slot mouths; 0.3 mm on the desk-side slot mouths (larger would overhang). |
| 4 | Thin bridges between strap slots and outer vent windows (3 mm). | analysis | Outer windows removed; slots centered for equal 11.55 mm ligaments each side. |
| 5 | 82° countersinks wedge the plastic (hoop stress, cracking) and lose clamp load fast at 60 °C. | PlasticsToday, EJOT, Chalmers thesis (see sources) | Flat-bottom counterbores (11 mm x 1.5 mm) for #8 pan-head + washer or truss-head screws. Countersink still available: `head_style = "countersink"`. |
| 6 | 4.5 mm screw holes print 0.2-0.3 mm small, nearly interference on a 4.17 mm #8 screw. | printability research | Holes modelled at 4.9 mm. |
| 7 | 3 mm air gap is conduction-only (Rayleigh number about 36-55, far below the 1708 needed for convection) and the lengthwise channels have no buoyant driving force, so the charger's best-cooling face was trapped. Costs about 7-10 °C vs free air. | `thermal_model.py`, thermal research | Six 10 mm posts give a 12 mm open gap (above the ~10 mm convection threshold) with air free to leave on all four sides. Original ribs still available: `standoff = "ribs"`. |
| 8 | PETG is only 5-9 °C below its heat deflection temperature (68-73 °C at 0.45 MPa) when touching a 60-70 °C case; creep and screw-clamp loss. | filament data sheets | Specify ASA (HDT about 100 °C). PETG only if the case measures below about 50 °C at full load. |
| 9 | Charger falling if a strap releases. | analysis | Two independent straps; each alone holds 3.2 N of charger weight more than 10x over. Use non-elastic straps. |

Not weak points (checked): screw withdrawal in particleboard is about 1 kN per screw against 0.8 N of load
per screw; gussets and posts are well above minimum feature sizes; no surface needs support.

## 2. Thermal analysis

Heat to dissipate (output x (1/efficiency - 1)): about 9-12 W at 140 W for a 92-94% efficient GaN adapter;
19 W at the 88% DOE Level VI floor. Design case: 10-12 W.

Model (`thermal_model.py`): isothermal box, emissivity 0.9, textbook natural-convection correlations
(Churchill-Chu for vertical sides, hot face down 0.52 Ra^1/5, hot face up 0.54 Ra^1/4, Hollands correlation
for the enclosed layer) plus radiation. Case temperature at 30 °C under-desk air:

| Loss | Free air | Old design (3 mm gap, closed sides) | Top face fully blocked |
|---|---|---|---|
| 8 W | 54 °C | 60 °C | 64 °C |
| 10 W | 59 °C | 66 °C | 71 °C |
| 12 W | 64 °C | 72 °C | 77 °C |

The thermal research estimated the same penalty independently (+8-10 K with the top face blocked). The new
12 mm open gap should land between the "free air" and "old design" columns. The model can't
pin it down exactly, so measure it (section 5). Other findings:

- Lying flat on the desk (the usual alternative) is worse than either mounted case.
- Standing the charger on edge gains only about 3 °C over the flat mount in the model, not worth a redesign.
- The plate and desk are insulators (k about 0.13-0.2 W/m-K); they carry only about 1 W. Don't count on them as a heat sink.
- Plate vents do nothing while the plate is flat against the desk.
- Reference points: comparable 140 W GaN bricks measure 57-67 °C case temperature at full load in 25 °C rooms; some throttle near 70-76 °C. IEC 62368-1 brief-touch limit for plastic is 77 °C. Max ambient for laptop adapters is typically 40 °C.
- Keep the charger out of PC exhaust air, and keep its cable ends clear.

## 3. Printing

Overhang scan (`print_check.py bracket.stl 45`): nothing steeper than 45° except 0.42 mm ledges at the
desk-side slot mouths (under one line width). No supports.

| Setting | ASA (recommended) | PETG |
|---|---|---|
| Dry filament | 70-80 °C, 4-8 h | 55-65 °C, 6-8 h |
| Nozzle | 255-260 °C | 240-250 °C |
| Bed | 100-110 °C, satin/textured PEI + glue | 80-90 °C, textured/satin PEI (never bare smooth PEI) |
| Enclosure | Yes, draft-free (chamber 45-60 °C if available) | No (open the door on enclosed printers) |
| Part fan | 0% first 3 layers, then 0-15% | 0-30% (slicer overhang fan for the lips) |
| Brim | 5-8 mm (holds the gusset feet) | 3-5 mm, optional |

Both: 0.2 mm layers, 0.45-0.5 mm line width, 5 perimeters with Arachne (makes 3-5 mm walls and the
posts solid), 40%+ gyroid infill, elephant-foot compensation about 0.2 mm, seam set to rear/aligned
(not inside the slots). Do not anneal. After printing, deburr the slot mouths. Print a test coupon
of one hole first if your printer's hole size is unknown.

## 4. Installation

- Screws: four #8 pan-head + #8 flat washer (or #8 truss-head) wood screws. Plate under the head is
  2.5 mm, washer about 1.6 mm. Use 5/8" (16 mm) for an 18 mm desk (about 12 mm in the wood, 6 mm left
  beyond the tip), 3/4" (19 mm) for 22 mm and thicker, 1" for 28 mm and thicker. Keep 4-5 mm of wood
  beyond the tip so the desk top doesn't dimple. Pilot 2.4-2.8 mm in particleboard/MDF, 3.2 mm in hardwood.
  Snug, don't crank: plastic relaxes.
- Order: screw the bracket up first (the screws are under the charger), then strap the charger on.
- Straps: two non-elastic 1" straps rated 25 lb (110 N) or more. Thread each out through a slot, around
  the lip tip, under the charger, and around the other lip. Put the hook-and-loop overlap away from the
  hot case (hook-and-loop creeps when warm). Snug only.

## 5. Validation (do this once)

Run the laptop at full load for 2 h or more (convection-cooled bricks take 2-3 h to settle). Measure the
case at the center of the largest face with a thermocouple, or an IR thermometer aimed at a piece of black
electrical tape (emissivity about 0.95). Pass: under 70 °C, no laptop power throttling, and within about
5 °C of the same charger lying in free air. If PETG was used, the case must stay under 50 °C.

## Sources

- Lenovo product page GX21M50625 (dimensions; screenshot supplied by the user)
- Adapter weight: https://www.shi.com/product/49800870/Lenovo-USB-C-power-adapter
- PETG data: https://cdn.shopify.com/s/files/1/1745/6181/files/PETG_TechSheet_ENG.pdf ; https://polymaker.com/wp-content/uploads/lana-downloads/PolyLite_PETG_TDS_EN_V5.4.pdf ; https://www.esun3d.com/uploads/PETG-Basic-TDS21.pdf
- ASA data: https://polymaker.com/wp-content/uploads/lana-downloads/PolyLite_ASA_TDS_EN_V5.4.pdf ; https://polyalkemi.no/wp-content/uploads/2024/01/Bambu_ASA_Technical_Data_Sheet.pdf ; https://help.prusa3d.com/article/asa_1809
- Countersunk screws in plastic: https://plasticstoday.com/automotive-mobility/plastic-part-design-selecting-appropriate-screw-fasteners ; https://www.ejot.com/presse-SpringHead ; https://odr.chalmers.se/bitstreams/273044b7-21b7-4b1f-b314-3341d8974866/download
- Screw withdrawal: https://engineersedge.com/calculators/wood_screw_pullout_withdraw_resistance_15385.htm ; https://dergipark.org.tr/tr/download/article-file/3471727
- Hook-and-loop: https://multimedia.3m.com/mws/media/1174469O/3m-reclosable-fastenerbrochure-lr.pdf ; https://zoro.com/velcro-brand-100-w-x-120-l-hook-and-loop-black-back-to-back-fastener-strap-450-pk-170353/i/G9790523
- Efficiency rules: https://resources.altium.com/p/external-power-supply-efficiency-ratings ; https://belfuse.com/resource-library/tech-paper/efficiency-standards-for-external-power-supplies ; https://www.infineon.com/cms/en/product/evaluation-boards/gs-evm-chg-140wpfcqr/
- Charger temperatures: https://www.chargerlab.com/lenovo-150w-gan-adapter-completes-60-hour-140w-full-load-challenge/ ; https://www.tomshardware.com/peripherals/usb/we-tested-20-wall-chargers-from-cheap-to-expensive-to-see-what-we-would-find-from-15-140w-with-screens-and-without
- Lenovo ventilation guidance: https://download.lenovo.com/pccbbs/pubs/t490/html_en/en/Heat_and_product_ventilation.html
- Touch limits: https://japan.ul.com/wp-content/uploads/sites/27/2014/06/1_techbrief_touchtemp.pdf ; https://regulatorydecoded.com/temperature-limits-in-product-design/
- Convection correlations: https://ht.readthedocs.io/en/latest/ht.conv_free_enclosed.html ; https://ht.readthedocs.io/en/latest/ht.conv_free_immersed.html ; https://www.electronics-cooling.com/?p=228
- Mounting orientation: https://www.advancedenergy.com/globalassets/resources-root/application-notes/en-lv-convection-cooling-application-note.pdf
- Printing: https://help.prusa3d.com/article/petg_2059 ; https://help.prusa3d.com/article/elephant-foot-compensation_114492 ; https://help.prusa3d.com/article/drying-filament_332086 ; https://cnckitchen.com/blog/the-effect-of-extrusion-width-on-strength-and-quality-of-3d-prints ; https://www.hubs.com/knowledge-base/how-design-parts-fdm-3d-printing/
