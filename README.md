# Puck Puck Go

Two players, one tablet, one flick each: knock the shared puck into the other player's goal.
First to 5 wins.

**Play it:** <https://hal-eisen.github.io/puck-puck-go/> — or open `index.html`. That is the entire
product: one self-contained file, no install, no network, no build step. Copy it to a tablet and
double-tap it. The tablet copy is the one that matters; the URL is just how it gets there.

Fullscreen on the first touch, no scrolling, no zooming, no pausing to think about the browser. `r`
restarts the match.

## Which way the table points

Always the same way. The field's long axis runs **across the screen** in every window, and the two
players sit **next to each other**, one at each end of the table:

```
        ┌───────────── 5 – 3 ─────────────┐   ← scoreboard strip, across the top
        │                                 │
   B B  │   ●        ● puck        ●      │  O O     ← each player defends their own end
        │                                 │
        └─────────────────────────────────┘
```

A tall window is fine and asks nothing of whoever is holding it — no rotating, no locking, nothing to
turn. The board is simply as wide as the window is, and the leftover height is where the scoreboard
goes, so in a tall window the strip costs the game nothing.

What a tall window does cost is width, and that is said plainly rather than papered over: the same
tablet gives a **1008 px** board lying flat and a **752 px** board standing upright, with 51 px and
38 px stones. Rotating the board would buy the width back — and is refused, because it would leave both
players sitting at the *sides* of the table instead of its ends. An earlier build did exactly that, and
every measurement in the project approved it, because every measurement was about the board and none
was about the game.

So the only gate is legibility, measured as rendered stone width, not as window shape:

```
scale = min((W − 2·8) / 1.76, (H − 2·8 − band) / 1.00)      # one layout, one basis
```

If a stone comes out under 18 px the game says so and quotes the requirement — *"Stones are 15 px wide
here; the game needs at least 18 px. The table never turns, so it needs a window at least 369 x 251 px —
make the window wider, or bigger."* `T30` then loads that exact rectangle and checks the promise, because
a number printed on screen is a claim.

## Design

* Product requirements: `Puck Puck Go PRD.md`
* Engineering design (constants, derivations, decision register, defect log): `docs/ENGINEERING_DESIGN.md`

## Verify it

Requires only Node and a Chrome/Chromium binary.

```
./tools/check.sh            # whole ladder, 1,000 shots
./tools/check.sh 300        # quick pass
```

`check.sh` runs the browser suite three times, in three window shapes: whatever window it gets, a
deliberately tall one (`WIN=820,1180`) and a deliberately flat one (`WIN=1280,600`). The field has to
come out horizontal in all three, and a suite that only ever sees one shape cannot tell that claim from a
test that was written for the shape it happened to run in. That is not hypothetical — three pixel probes
were wrong in exactly that way once already.

| Command | Checks |
| --- | --- |
| `node tools/offline-check.mjs` | Still one file: no external script/link/image/URL/fetch/import |
| `node tools/physics-test.mjs [n]` | Physics only, in Node, extracted from the shipped `index.html` |
| `./tools/browser-test.sh [n]` | Headless Chrome: physics + pixels + rules + input + match flow + layout |
| `./tools/browser-test.sh [n] <url>` | Same suite against a deployed copy instead of the local file |
| `WIN=820,1180 ./tools/browser-test.sh [n]` | Same suite in a window of that shape — try it portrait |
| `./tools/render-map.sh [cols] [w] [h]` | The canvas as a character map: `,` felt, `+` scoreboard, `B`/`O` stones, `#` puck. Try `./tools/render-map.sh 60 760 1040` (a tall window) and `./tools/render-map.sh 60 1280 560` (a flat one): the table lies across both |
| `node tools/probe.mjs` | The quoted numbers: how far a shot rolls, when it rests, how hot it hits the far wall |

The same self-tests are compiled into the game. On a real tablet open
`index.html?debug&selftest` and tap **selftest** — that is the only way to get the frame-rate and
glare numbers that matter, since a headless run cannot measure either.

`index.html?debug` also exposes live physics sliders (rollingDecel, linearDamping, wall e, body e,
maxSpeed, puckMass) for tuning feel on the device. Nothing in `?debug`/`?selftest` runs by default, and
there is no control for rotating the board: the board does not rotate.

## Publishing

GitHub Pages serves the repository root on `main`, and `index.html` sits at that root, so deploying
is pushing:

```
git push github main        # Pages rebuilds in ~30-60 s
```

`.nojekyll` at the root turns GitHub's Jekyll build off, so the bytes that get served are the bytes
that get pushed — nothing sits between the file we tested and the file the tablet runs. Pages sits
behind a CDN with a ~10 minute cache, so a fix can take a few minutes to appear; hard-refresh rather
than conclude the push failed.

Deployment is checkable, and worth checking after every push:

```
curl -s https://hal-eisen.github.io/puck-puck-go/ | md5sum   # must match: md5sum index.html
./tools/browser-test.sh https://hal-eisen.github.io/puck-puck-go/   # the suite against the live copy
WIN=820,1180 ./tools/browser-test.sh 120 https://hal-eisen.github.io/puck-puck-go/   # the live copy, portrait
```

The live copy is served with `access-control-allow-origin: *` and no external references, which the
offline audit keeps enforcing — Pages cannot quietly become a dependency.
