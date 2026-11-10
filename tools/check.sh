#!/usr/bin/env bash
# One command: the whole verification ladder. Dev-only; ships nothing.
#   ./tools/check.sh [shots]
#
# The browser suite runs three times on purpose: once with the layout the window picks by
# itself, and once with each layout forced. A layout is a second coordinate system, and a
# suite that only ever sees one of them cannot tell a real bug from a probe that was written
# in the wrong screen axis.
set -uo pipefail
cd "$(dirname "$0")/.."
N=${1:-1000}
rc=0
echo "== self-containment ==" ; node tools/offline-check.mjs || rc=1
echo; echo "== physics (node, DOM-free extraction) ==" ; node tools/physics-test.mjs "$N" | tail -12 || rc=1
echo; echo "== in-browser: auto layout ==" ; ./tools/browser-test.sh "$N" || rc=1
# The two forced-layout passes exist to catch probes written in the wrong screen axis, not to
# re-run a thousand shots, so they take a smaller shot count.
M=$(( N < 120 ? N : 120 ))
echo; echo "== in-browser: layout=tall forced ==" ; ./tools/browser-test.sh "$M" "file://$PWD/index.html?layout=tall" || rc=1
echo; echo "== in-browser: layout=wide forced ==" ; ./tools/browser-test.sh "$M" "file://$PWD/index.html?layout=wide" || rc=1
echo
if [ $rc -eq 0 ]; then echo "ALL GREEN"; else echo "FAILURES (rc=$rc)"; fi
exit $rc
