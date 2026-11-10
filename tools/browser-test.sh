#!/usr/bin/env bash
# Headless verification: runs the in-page self-tests (physics + render + rules/controls)
# in Chrome and prints the PASS/FAIL table plus a summary. Dev-only tool.
set -euo pipefail
cd "$(dirname "$0")/.."
N=${1:-200}
find_browser() {
  if [ -n "${BROWSER:-}" ]; then echo "$BROWSER"; return; fi
  for b in google-chrome google-chrome-stable chromium chromium-browser; do
    command -v "$b" >/dev/null 2>&1 && { echo "$b"; return; }
  done
  echo "no chrome/chromium found (set BROWSER=...)" >&2; exit 2
}
BROWSER=$(find_browser)
"$BROWSER" --headless=new --no-sandbox --disable-gpu --allow-file-access-from-files \
  --virtual-time-budget=30000 --dump-dom "file://$PWD/index.html?debug&selftest&n=$N" 2>/dev/null \
  | python3 tools/parse-dom.py
