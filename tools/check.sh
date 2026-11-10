#!/usr/bin/env bash
# One command: the whole verification ladder. Dev-only; ships nothing.
#   ./tools/check.sh [shots]
#
# The browser suite runs three times on purpose, in three WINDOW SHAPES: whatever the window
# happens to be, and a deliberately tall one, and a deliberately flat one. The field has to come
# out horizontal in all three - two players sit next to each other, one at each end of the table -
# and a suite that only ever sees one shape cannot tell that claim from a probe written in the
# wrong screen axis. That is not hypothetical: three pixel probes were wrong in exactly that way.
set -uo pipefail
cd "$(dirname "$0")/.."
N=${1:-1000}
rc=0
echo "== self-containment ==" ; node tools/offline-check.mjs || rc=1
echo; echo "== physics (node, DOM-free extraction) ==" ; node tools/physics-test.mjs "$N" | tail -12 || rc=1
# The shape passes exist to catch probes written in the wrong screen axis, not to re-run a
# thousand shots, so they take a smaller shot count.
M=$(( N < 120 ? N : 120 ))
echo; echo "== in-browser: default window ==" ; ./tools/browser-test.sh "$N" || rc=1
echo; echo "== in-browser: portrait window 820x1180 ==" ; WIN=820,1180 ./tools/browser-test.sh "$M" || rc=1
echo; echo "== in-browser: flat window 1280x600 ==" ; WIN=1280,600 ./tools/browser-test.sh "$M" || rc=1
echo
if [ $rc -eq 0 ]; then echo "ALL GREEN"; else echo "FAILURES (rc=$rc)"; fi
exit $rc
