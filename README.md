# Puck Puck Go

Two players, one tablet, one flick each: knock the shared puck into the other player's goal.
First to 5 wins.

**Play it:** <https://hal-eisen.github.io/puck-puck-go/> — or open `index.html`. That is the entire
product: one self-contained file, no install, no network, no build step. Copy it to a tablet and
double-tap it. The tablet copy is the one that matters; the URL is just how it gets there.

Fullscreen on the first touch, no scrolling, no zooming, no pausing to think about the browser. `r`
restarts the match.

## Which way the table points

The table does not require landscape. It requires stones big enough to aim at, which is a different
requirement and the one that actually matters:

* **`wide`** — long axis across the screen, players left and right, scoreboard strip across the top.
* **`tall`** — long axis up the screen, players bottom and top, scoreboard strip down the left edge,
  each score nearest the end that player defends.
* **`auto`** (default) — whichever of the two draws the bigger board, so a tall panel that has the room
  gets the tall layout and the same board it would have had in landscape.

Measured: `1024×768` and `768×1024` both give a 573 px board with 51 px stones. Turning the tablet
changes where you sit, not how big the game is. Nothing is locked to any orientation, because no sensor
knows where the two players are sitting — and a portrait display mounted in the middle of a car has both
players *beside* it, which is the seat `auto` cannot see.

So it is overridable: **`?layout=wide`**, **`?layout=tall`**, **`?layout=auto`**. If the board really is
too small — in either orientation — the game says so and quotes the measurement (*"Stones are 15 px wide
here; the game needs at least 18 px"*) instead of asking for a rotation that would not have helped.

## Design

* Product requirements: `Puck Puck Go PRD.md`
* Engineering design (constants, derivations, decision register, defect log): `docs/ENGINEERING_DESIGN.md`

## Verify it

Requires only Node and a Chrome/Chromium binary.

```
./tools/check.sh            # whole ladder, 1,000 shots
./tools/check.sh 300        # quick pass
```

`check.sh` runs the browser suite three times: once with the layout the window picks, then with
`layout=tall` forced, then `layout=wide`. A layout is a second coordinate system, and a suite that only
ever sees one of them cannot tell a rendering bug from a test that was written in the wrong screen axis.
That is not hypothetical — three pixel probes were wrong in exactly that way, and the suite had never
once been run in the other layout.

| Command | Checks |
| --- | --- |
| `node tools/offline-check.mjs` | Still one file: no external script/link/image/URL/fetch/import |
| `node tools/physics-test.mjs [n]` | Physics only, in Node, extracted from the shipped `index.html` |
| `./tools/browser-test.sh [n]` | Headless Chrome: physics + pixels + rules + input + match flow + layout |
| `./tools/browser-test.sh [n] <url>` | Same suite against a deployed copy instead of the local file |
| `./tools/browser-test.sh [n] "<url>?layout=tall"` | Same suite with one layout forced |
| `./tools/render-map.sh [cols] [w] [h] [extra params]` | The canvas as a character map: `,` felt, `+` scoreboard, `B`/`O` stones, `#` puck. Try `./tools/render-map.sh 60 768 1024` (portrait) and add `"layout=wide"` to compare |
| `node tools/probe.mjs` | The quoted numbers: how far a shot rolls, when it rests, how hot it hits the far wall |

The same self-tests are compiled into the game. On a real tablet open
`index.html?debug&selftest` and tap **selftest** — that is the only way to get the frame-rate and
glare numbers that matter, since a headless run cannot measure either.

`index.html?debug` also exposes live physics sliders (rollingDecel, linearDamping, wall e, body e,
maxSpeed, puckMass) for tuning feel on the device, and a **flip layout** button that rotates the board
without touching the physics — useful when two people are sitting somewhere no browser can detect.
Nothing in `?debug`/`?selftest` runs by default.

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
./tools/browser-test.sh 120 "https://hal-eisen.github.io/puck-puck-go/?layout=tall"   # forced layout too
```

The live copy is served with `access-control-allow-origin: *` and no external references, which the
offline audit keeps enforcing — Pages cannot quietly become a dependency.
