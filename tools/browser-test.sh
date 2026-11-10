#!/usr/bin/env bash
# Headless verification: runs the in-page self-tests (physics + render + rules/controls)
# in Chrome and prints the PASS/FAIL table plus a summary. Dev-only tool.
#
#   ./tools/browser-test.sh [shots] [url]     (url may also come first)
#
# URL defaults to the local file. Pass a deployed URL to run the same suite against what
# is actually being served - a green local run says nothing about the published copy.
set -euo pipefail
cd "$(dirname "$0")/.."
N=${1:-200}
TARGET=${2:-}
if [ -z "$TARGET" ]; then
  case "$N" in
    http://*|https://*|file://*) TARGET=$N; N=200 ;;   # URL given first: ./tools/browser-test.sh <url>
    *)                          TARGET=file://$PWD/index.html ;;
  esac
fi
find_browser() {
  if [ -n "${BROWSER:-}" ]; then echo "$BROWSER"; return; fi
  for b in google-chrome google-chrome-stable chromium chromium-browser; do
    command -v "$b" >/dev/null 2>&1 && { echo "$b"; return; }
  done
  echo "no chrome/chromium found (set BROWSER=...)" >&2; exit 2
}
BROWSER=$(find_browser)
case "$TARGET" in
  file://*) EXTRA=--allow-file-access-from-files ;;
  *)        EXTRA='' ;;
esac
sep=?; case "$TARGET" in *\?*) sep=& ;; esac
echo "target: $TARGET"
# Pages serves a ~10 minute cache, so a normal load can test the previous deploy.
FLAGS=(--headless=new --no-sandbox --disable-gpu --disk-cache-size=1 --aggressive-cache-discard)
[ -n "$EXTRA" ] && FLAGS+=("$EXTRA")
"$BROWSER" "${FLAGS[@]}" \
  --virtual-time-budget=30000 --dump-dom "$TARGET${sep}debug&selftest&n=$N" 2>/dev/null \
  | python3 tools/parse-dom.py
