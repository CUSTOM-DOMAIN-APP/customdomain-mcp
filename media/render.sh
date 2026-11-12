#!/usr/bin/env bash
# Renders media/src/*.html to media/*.png (1600 x 1000 CSS px at 2x, so 3200 x 2000 px) with headless Chrome.
# Needs Google Chrome and the fonts Instrument Serif, Inter and Geist Mono installed (all open source, SIL OFL).
# The pages are illustrations with example domains; never point this at a live account. Usage: media/render.sh [name ...]
set -euo pipefail
cd "$(dirname "$0")"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
names=("$@"); [ ${#names[@]} -eq 0 ] && names=(hero connect fix email)
for n in "${names[@]}"; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-sandbox \
    --window-size=1600,1000 --force-device-scale-factor=2 --virtual-time-budget=4000 \
    --screenshot="$PWD/$n.png" "file://$PWD/src/$n.html" >/dev/null 2>&1
  echo "wrote media/$n.png"
done
