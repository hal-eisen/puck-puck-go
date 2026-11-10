# Puck Puck Go

Two players, one tablet, one flick each: knock the shared puck into the other player's goal.
First to 5 wins.

**Play it:** <https://hal-eisen.github.io/puck-puck-go/> — or open `index.html`. That is the entire
product: one self-contained file, no install, no network, no build step. Copy it to a tablet and
double-tap it. The tablet copy is the one that matters; the URL is just how it gets there.

Works best landscape and fullscreen; it asks for both on the first touch. Rotate the tablet if the
prompt appears. `r` restarts the match.

## Design

* Product requirements: `Puck Puck Go PRD.md`
* Engineering design (constants, derivations, decision register, defect log): `docs/ENGINEERING_DESIGN.md`

## Verify it

Requires only Node and a Chrome/Chromium binary.

```
./tools/check.sh            # whole ladder, 1,000 shots
./tools/check.sh 300        # quick pass
```

| Command | Checks |
| --- | --- |
| `node tools/offline-check.mjs` | Still one file: no external script/link/image/URL/fetch/import |
| `node tools/physics-test.mjs [n]` | Physics only, in Node, extracted from the shipped `index.html` |
| `./tools/browser-test.sh [n]` | Headless Chrome: physics + pixels + rules + input + match flow |
| `./tools/browser-test.sh [n] <url>` | Same suite against a deployed copy instead of the local file |
| `./tools/render-map.sh [cols] [w] [h]` | The canvas as a character map: `,` felt, `+` scoreboard, `B`/`O` stones, `#` puck |
| `node tools/probe.mjs` | The quoted numbers: how far a shot rolls, when it rests, how hot it hits the far wall |

The same self-tests are compiled into the game. On a real tablet open
`index.html?debug&selftest` and tap **selftest** — that is the only way to get the frame-rate and
glare numbers that matter, since a headless run cannot measure either.

`index.html?debug` also exposes live physics sliders (rollingDecel, linearDamping, wall e, body e,
maxSpeed, puckMass) for tuning feel on the device. Nothing in `?debug`/`?selftest` runs by default.

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
```

The live copy is served with `access-control-allow-origin: *` and no external references, which the
offline audit keeps enforcing — Pages cannot quietly become a dependency.
