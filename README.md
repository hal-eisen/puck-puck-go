# Puck Puck Go

Two players, one tablet, one flick each: knock the shared puck into the other player's goal.
First to 5 wins.

**Play it:** open `index.html`. That is the entire product — one self-contained file, no install,
no network, no build step. Copy it to a tablet and double-tap it.

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

The same self-tests are compiled into the game. On a real tablet open
`index.html?debug&selftest` and tap **selftest** — that is the only way to get the frame-rate and
glare numbers that matter, since a headless run cannot measure either.

`index.html?debug` also exposes live physics sliders (rollingDecel, linearDamping, wall e, body e,
maxSpeed, puckMass) for tuning feel on the device. Nothing in `?debug`/`?selftest` runs by default.
