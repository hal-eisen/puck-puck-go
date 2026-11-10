#!/usr/bin/env bash
# Debug-only text view of the rendered canvas: opens index.html?debug&ascii in headless
# Chrome and prints the character map that DEBUG.asciiMap writes into #dtest.
set -uo pipefail
cd "$(dirname "$0")/.."
COLS=${1:-74}
W=${2:-1280}
H=${3:-800}
Q="cols=$COLS"
[ -n "${4:-}" ] && Q="$Q&$4"            # 4th arg: extra debug params, e.g. "layout=tall"
find_browser() {
  if [ -n "${BROWSER:-}" ]; then echo "$BROWSER"; return; fi
  for b in google-chrome google-chrome-stable chromium chromium-browser; do
    command -v "$b" >/dev/null 2>&1 && { echo "$b"; return; }
  done
  echo "no chrome/chromium found (set BROWSER=...)" >&2; exit 2
}
BROWSER=$(find_browser)
"$BROWSER" --headless=new --no-sandbox --disable-gpu --allow-file-access-from-files \
  --window-size="$W,$H" --virtual-time-budget=4000 --dump-dom \
  "file://$PWD/index.html?debug&ascii&$Q" 2>/dev/null \
  | python3 tools/parse-ascii.py
