#!/usr/bin/env bash
# One command: the whole verification ladder. Dev-only; ships nothing.
#   ./tools/check.sh [shots]
set -uo pipefail
cd "$(dirname "$0")/.."
N=${1:-1000}
rc=0
echo "== self-containment ==" ; node tools/offline-check.mjs || rc=1
echo; echo "== physics (node, DOM-free extraction) ==" ; node tools/physics-test.mjs "$N" | tail -12 || rc=1
echo; echo "== in-browser: physics + render + rules/controls ==" ; ./tools/browser-test.sh "$N" || rc=1
echo
if [ $rc -eq 0 ]; then echo "ALL GREEN"; else echo "FAILURES (rc=$rc)"; fi
exit $rc
