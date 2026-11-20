#!/usr/bin/env bash
# Renders the turntable animation to bracket-animation.mp4 (H.264, plays in iMessage).
set -euo pipefail
cd "$(dirname "$0")"
N=${N:-150}; FPS=${FPS:-30}; SIZE=${SIZE:-1080}
rm -rf frames && mkdir frames
for ((i=0; i<N; i++)); do
  T=$(python3 -c "print($i/$N)")
  ROT=$(python3 -c "print(30 + 360*$i/$N)")
  # --camera=tx,ty,tz,rx,ry,rz,dist
  xvfb-run -a openscad -q -o "frames/f$(printf %04d $i).png" \
    --imgsize=$SIZE,$SIZE --colorscheme=Tomorrow --projection=p \
    --camera=0,0,14,62,0,$ROT,430 -D "T=$T" animate.scad
done
ffmpeg -y -loglevel error -framerate $FPS -i frames/f%04d.png \
  -c:v libx264 -pix_fmt yuv420p -crf 20 -movflags +faststart bracket-animation.mp4
echo "wrote bracket-animation.mp4"
