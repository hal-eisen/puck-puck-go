# Puck Puck Go: PRD

Nov 9, 2026 · @Hal Eisen

## TL;DR

Puck Puck Go is a two-player, same-device tabletop game for a tablet. Each player flicks one of five stones per turn, slingshot style, to knock a shared puck into the opponent's goal. First to 5 goals wins.

The whole game lives or dies on feel: believable drag, satisfying ricochets, and stone-on-stone collisions. It ships as a single offline HTML file built for an AI coding agent to implement.

## Problem and context

Two people sharing one tablet in a car have few good options. Most tablet games are single-player, need a network connection, or need two devices. Turn-based games with simple rules but deep physics fill that gap: quick to learn, endlessly replayable, no connectivity required.

The bet is that a well-tuned physics sandbox with a clear goal produces emergent strategy (bank shots, blocking, setting up stones) without needing content, levels, or AI opponents.

## Goals and non-goals

**Goals**

1. Physics that feel right: felt-table drag, clean ricochets off rounded walls, and convincing stone-on-stone and stone-on-puck collisions.
2. Aiming that works reliably on a touchscreen in a moving car, with an easy way to cancel.
3. A complete match loop: kickoff, turns, scoring, reset, win, rematch.
4. Zero setup: one HTML file, opens offline, no install, no network.

**Non-goals (v1)**

- Single-player or AI opponent
- Online or multi-device play
- Trajectory prediction or aim assist beyond a direction and power indicator
- Turn timers
- Haptics
- Player name or color customization, settings menus, pause
- PWA install, accounts, persistence of stats

## User and use case

Two players, kids or adults, sitting side by side in the back of a car. They share one Android tablet or iPad held flat or propped in landscape between them. Player 1 sits on the left and defends the left goal; Player 2 sits on the right and defends the right goal.

**User stories**

- As a player, I can see whose turn it is at a glance, so we never argue about it.
- As a player, I can press and drag back on any of my stones to aim, and see the direction and power before I let go.
- As a player, I can cancel a shot by dragging back onto my stone, so a bump in the road doesn't waste my turn.
- As a player, I can bank the puck off walls and other stones, so skill and creativity are rewarded.
- As players, we can start a rematch with one tap when a match ends.

## Core gameplay rules

A match is a series of single pushes, alternating between players, each one fully resolved before the next begins.

1. **Setup.** Each player has 5 stones in an X on their half of the field. The puck sits at center.
2. **Kickoff.** The first turn of a match goes to a randomly chosen player. After any goal, the player who was scored on takes the next turn.
3. **Turn.** The active player pushes exactly one of their 5 stones, from wherever it currently sits on the field. There is no time limit.
4. **Resolution.** The turn ends when every body (all 10 stones and the puck) has come to rest. Input is locked until then.
5. **Scoring.** A goal is scored the moment the puck fully crosses a goal line. Whoever's goal it entered concedes; own goals count for the opponent.
6. **Stones and goals.** Stones cannot enter a goal. The goal mouth acts as a wall for stones and an opening for the puck.
7. **After a goal.** Play a short goal celebration, then fully reset: puck to center, all stones back to their X positions.
8. **Resting puck near a wall.** If the puck comes to rest touching or within one puck radius of a wall, it eases away from the wall along the wall normal before the next turn starts. This prevents unplayable pinned pucks.
9. **Win.** First player to 5 goals wins. Show a winner screen with a one-tap Rematch button that starts a new match from 0–0 with a new random kickoff.

**Game states**

| State | Input | Exits to |
| --- | --- | --- |
| Kickoff | None (brief turn banner) | Aiming |
| Aiming | Active player only, own stones only | Simulating (on release) or Aiming (on cancel) |
| Simulating | None | Goal, or Settling, then Aiming for the other player |
| Settling | None (wall nudge if needed) | Aiming |
| Goal | None (celebration, about 2 s) | Kickoff, or Match over at 5 |
| Match over | Rematch button | Kickoff |

## Controls and aiming

Aiming is slingshot style: touch a stone, drag back away from where you want it to go, release to fire.

1. **Grab.** A touch that starts within the stone's radius plus 12 px of tolerance selects that stone. Only the active player's stones respond. Touches on the opponent's stones, the puck, or empty field do nothing.
2. **Aim.** While held, the launch direction is the vector from the finger to the stone's center. Power scales linearly with drag distance, clamped at a max drag of about 25% of field height.
3. **Indicator.** Draw an arrow from the stone in the launch direction, with length and color proportional to power (for example, green at low power shading to red at max). No trajectory prediction, no ghost path.
4. **Fire.** Releasing the finger applies an instantaneous impulse to the stone in the launch direction.
5. **Cancel.** Releasing with the finger inside the stone's radius plus a small dead zone cancels the shot. The stone stays put and it is still the same player's turn. Show the indicator as faded or neutral while in the cancel zone so the player knows.
6. **Multitouch.** Track only the first touch pointer per aim. Ignore any additional touches until release, so a second hand or the other player's finger can't interfere.
7. **Interruptions.** A pointercancel event (system gesture, app switch) cancels the aim, same as rule 5.

The whole page must suppress default browser gestures: no scroll, no pinch zoom, no pull-to-refresh, no text selection, no long-press context menu.

## Physics requirements

Physics quality is the top priority. The target feel is a felt billiards table: crisp, energetic collisions, but bodies slow noticeably and settle within a few seconds.

**Engine**

- Use a 2D rigid-body library, bundled inline. Prefer Planck.js (a Box2D port) for its continuous collision detection on fast bodies; Matter.js is acceptable if tunneling is handled.
- All bodies are circles. Disable rotation effects on gameplay (no spin, no english). Set inter-body friction to 0 so collisions transfer momentum cleanly.
- Run a fixed timestep of 1/120 s, decoupled from render frame rate, with sub-stepping as needed so a max-power shot never tunnels through a wall, stone, or puck.
- Simulation must be deterministic for a given input on a given device.

**Drag model**

Felt slows things with roughly constant deceleration, unlike air drag. Combine both:

- A constant rolling deceleration applied opposite to velocity each step.
- A small velocity-proportional damping term so fast shots bleed speed a bit faster at the top end.
- A rest threshold: when speed drops below the threshold, set velocity to exactly 0.

**Starting constants** (in field-height units, H = field height; all live in one `PHYSICS` config object so they can be tuned in one place)

| Constant | Starting value | Notes |
| --- | --- | --- |
| Field size | 1.6 H × 1.0 H | Landscape, about 16:10 |
| Corner radius | 0.12 H | Rounded corners |
| Goal mouth width | 0.30 H | Centered on each end wall |
| Goal depth | 0.08 H | Puck must fully cross the line to score |
| Stone radius | 0.045 H |  |
| Puck radius | 0.035 H | Smaller and visually distinct |
| Stone mass | 1.0 |  |
| Puck mass | 0.6 | Lighter, so it flies off hits |
| Restitution, stone–stone | 0.92 |  |
| Restitution, stone–puck | 0.92 |  |
| Restitution, body–wall | 0.75 | Walls absorb some energy |
| Max launch speed | 3.0 H/s | A max shot crosses the field and rebounds about once |
| Rolling deceleration | 0.9 H/s² | Main felt feel |
| Linear damping | 0.4 /s | Top-end bleed |
| Rest threshold | 0.01 H/s | Below this, speed snaps to 0 |
| Settle cap | 12 s | Failsafe: after this, force all bodies to rest |
| Wall nudge distance | 1 puck radius | See rule 8 |

The builder should treat these as a first pass and tune by playtesting. Acceptance is about feel (see Acceptance criteria), not exact numbers.

**Debug overlay**

When the URL has `?debug`, show FPS, body speeds, and live sliders for the drag, restitution, and launch-speed constants. Hidden otherwise. This exists for tuning only.

## Field, visuals, and feedback

**Layout.** Landscape only. Goals sit on the left and right end walls. Player 1 (left) defends the left goal; Player 2 (right) defends the right goal. All UI is upright for both players, since they sit side by side.

**Starting X positions** (origin at field center, units of H, +x to the right). Player 1's X is centered at (−0.50, 0):

- (−0.65, −0.15), (−0.65, 0.15), (−0.50, 0), (−0.35, −0.15), (−0.35, 0.15)

Player 2's X mirrors it across the center line. The puck starts at (0, 0).

**Visuals**

- Each player has a distinct stone color (for example, blue and orange) that also tints their goal and their half's score.
- The puck is a different shape treatment and color from both players' stones (for example, white with a dark ring).
- Turn indicator: the active player's half gets a subtle glow and their stones a soft pulse. A short "Blue's turn" banner shows at the start of each turn.
- Score is always visible near the top center, colored per player.
- Field fills the screen while preserving its aspect ratio, letterboxed as needed, and re-fits on resize or rotation.

**Sound**

- Synthesize sounds with the Web Audio API; no audio files.
- Collision clack with volume and pitch scaled by impact speed. Distinct tones for stone–stone, stone–puck, and wall hits.
- Throttle to avoid more than one sound per body pair per 50 ms.
- A goal sound, and a win fanfare on the winner screen.
- Audio unlocks on the first touch (required by iOS Safari).

**Goal celebration**

- About 2 seconds: the scoring player's color flashes across the field, the score digit pops, and a short "Goal!" message appears. Input is locked during it.

**Winner screen**

- Overlay naming the winner in their color with the final score, plus one large Rematch button.

## Technical requirements

- **Language:** JavaScript (ES2020), no build step required to run.
- **Delivery:** one self-contained `index.html` with all JS, CSS, and the physics library inlined. It must work when opened from local storage with no network.
- **Rendering:** HTML Canvas 2D, scaled for `devicePixelRatio` so edges stay crisp on high-DPI tablets.
- **Input:** Pointer Events, with `touch-action: none` on the canvas.
- **Targets:** latest Chrome on Android tablets and latest Safari on iPadOS. Desktop Chrome with a mouse should also work for development.
- **Performance:** 60 fps steady on a mid-range Android tablet (about 2022 era) during the busiest collision moments.
- **Fullscreen:** request fullscreen on first touch where supported. Lock to landscape where the platform allows; otherwise show a "rotate to landscape" prompt in portrait.
- **Screen wake:** use the Wake Lock API where available so the screen doesn't dim mid-match.
- **Code structure:** separate modules (or clearly separated sections in the single file) for physics config, simulation, input, rendering, audio, and game state, so tuning and fixes stay local.
- **No persistence, analytics, or network calls.**

## Acceptance criteria

**Rules**

- [ ] Match starts 0–0 with a random first player, shown by the turn banner.
- [ ] Only the active player's stones respond to touch; all input is locked while anything is moving.
- [ ] Turn passes to the other player only after every body is at rest.
- [ ] A puck fully crossing a goal line scores for the opponent of that goal's owner, including own goals.
- [ ] Stones never enter a goal, at any launch speed.
- [ ] After a goal: celebration, full reset, and the conceding player takes the next turn.
- [ ] Reaching 5 shows the winner screen; Rematch starts a fresh match with a new random kickoff.
- [ ] A puck resting against a wall is nudged free before the next turn.

**Controls**

- [ ] Dragging back from a stone launches it in the opposite direction, with power proportional to drag distance up to the max.
- [ ] The arrow indicator updates every frame while aiming.
- [ ] Releasing inside the cancel zone cancels the shot and keeps the turn.
- [ ] A second finger on the screen does not affect an aim in progress.
- [ ] No scrolling, zooming, text selection, or context menu at any point.

**Physics and feel**

- [ ] 1,000 automated max-power shots at random angles produce zero tunneling through walls, stones, or puck.
- [ ] A max-power shot with nothing in its path crosses the field and comes to rest within 4 seconds.
- [ ] A medium shot settles all bodies within 3 seconds in a typical position.
- [ ] Stone-to-stone hits visibly transfer momentum (a head-on hit nearly stops the striker).
- [ ] Bank shots off straight walls and rounded corners are predictable to a human eye.
- [ ] The same shot from the same position produces the same result.

**Platform**

- [ ] Works fully offline from a single HTML file on iPad Safari and Android Chrome.
- [ ] Holds 60 fps during a 10-body pileup on a mid-range Android tablet.
- [ ] Sounds play on iOS after the first touch.

## Success metrics and decisions

**Success looks like**

- Players finish a full match to 5 without confusion about whose turn it is or what happened.
- Players ask for a rematch more often than not.
- Players start attempting deliberate bank shots and blocking setups within their first match.
- No playtest session is ended by a bug, a stuck puck, or an accidental shot that couldn't be cancelled.

**Decisions**

- The game is called Puck Puck Go.
- First to 5 always wins. No tiebreak, comeback, or stalemate mechanic.
- Any stone on the board is in a valid position. No limits on drifting into the opponent's half.
- The game is self-explanatory. No rules card, tutorial, or onboarding.
