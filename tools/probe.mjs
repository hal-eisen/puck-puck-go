// Dev-only probe: numbers quoted in docs/ENGINEERING_DESIGN.md §13, measured from the shipped
// code rather than from algebra. node tools/probe.mjs
import fs from 'node:fs';

const html = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const cut = (from, to) => {
  const a = html.indexOf(from), b = html.indexOf(to);
  if (a < 0 || b < 0) throw new Error('marker not found: ' + from);
  return html.slice(a, b);
};
const core = cut('const CONFIG = {', '/* ============================== SECTION: PRNG');
const prng = cut('function mulberry32', 'const SEED =');
const run = new Function('document', 'window', 'location',
  core + '\n' + prng + '\n; return { CONFIG, GEOM, SIM };');
const { CONFIG, GEOM, SIM } = run({ getElementById: () => null }, { __PPG: {} }, { search: '' });
const P = CONFIG.PHYSICS;

function roll(v0, x0 = -0.70, y0 = 0) {
  const sim = SIM.create();
  sim.reset();
  for (let i = 0; i < sim.world.stones.length; i++) {
    const o = sim.world.stones[i]; o.x = -0.5 - 0.15 * i; o.y = 1.5 + 0.15 * i;
  }
  sim.world.puck.x = 0; sim.world.puck.y = 0.7;
  const s = sim.world.stones[0]; s.x = x0; s.y = y0;
  const savedW = P.halfW, savedH = P.halfH;
  P.halfW = 40; P.halfH = 40;
  sim.fire(s, 0, v0);
  let d = 0, t = 0, lx = s.x, ly = s.y;
  while (t < 40 && Math.hypot(s.vx, s.vy) > P.restThreshold) {
    sim.step(P.step); t += P.step;
    d += Math.hypot(s.x - lx, s.y - ly); lx = s.x; ly = s.y;
  }
  P.halfW = savedW; P.halfH = savedH;
  return { d, t };
}

// real board: does a max shot from the back row reach the far wall, and how hot is it there?
function crossBoard(v0, x0) {
  const sim = SIM.create();
  sim.reset();
  sim.world.stones.forEach((o, i) => { o.x = -0.72 + 0.15 * i; o.y = -0.42; });
  sim.world.puck.x = 0; sim.world.puck.y = 0.45;
  const s = sim.world.stones[0]; s.x = x0; s.y = 0;
  sim.fire(s, 0, v0);
  let t = 0, hit = null, d = 0, lx = s.x;
  while (t < 30 && !sim.allAtRest()) {
    sim.step(P.step); t += P.step;
    d += Math.abs(s.x - lx); lx = s.x;
    if (hit === null && Math.abs(s.vx) < Math.abs(v0) && s.vx < 0) hit = { x: s.x, speed: Math.abs(s.vx) };
  }
  return { d, t, hit };
}

const rows = [1, 0.67, 0.5, 0.33].map((f) => {
  const v = f * P.maxLaunchSpeed;
  const r = roll(v);
  return `${(f * 100).toFixed(0)}% v0=${v.toFixed(2)} rest=${r.t.toFixed(2)}s path=${r.d.toFixed(3)}H ` +
    `= ${Math.round(r.d / (2 * P.halfW) * 100)}% of table`;
});
console.log('maxLaunchSpeed = ' + P.maxLaunchSpeed + ' H/s, table length = ' + (2 * P.halfW) + ' H');
rows.forEach((r) => console.log(' ' + r));

for (const x0 of [-0.65, -0.35, 0]) {
  const c = crossBoard(P.maxLaunchSpeed, x0);
  console.log(`max shot from x=${x0}: path=${c.d.toFixed(2)}H time=${c.t.toFixed(2)}s ` +
    (c.hit ? `hit far wall at x=${c.hit.x.toFixed(3)} with ${c.hit.speed.toFixed(2)}H/s (${Math.round(c.hit.speed / P.maxLaunchSpeed * 100)}% of launch)` : 'never reached the far wall'));
}
