// Dev-only physics harness (not shipped). Extracts the DOM-free sections from index.html
// (CONFIG, GEOMETRY, SOLVER, SIM) plus the in-page self-tests, and runs them in Node so the
// physics acceptance criteria are gated on every commit without a browser.
//   node tools/physics-test.mjs [n]
import fs from 'node:fs';

const html = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const cut = (from, to) => {
  const a = html.indexOf(from), b = html.indexOf(to);
  if (a < 0 || b < 0) throw new Error('marker not found: ' + from);
  return html.slice(a, b);
};

const core = cut('const CONFIG = {', '/* ============================== SECTION: PRNG');
const prng = cut('function mulberry32', 'const SEED =');
const tests = cut('function runSelfTests', 'window.__PPG =');

const src = [core, prng, tests].join('\n');
const run = new Function(
  'document', 'window', 'location',
  src + '\n; return runSelfTests;'
);
const selftest = run(
  { getElementById: () => null },
  { __PPG: {} },
  { search: '' }
);

const n = Number(process.argv[2] || 1000);
const out = selftest(n);
const failed = out.filter((l) => l.startsWith('FAIL'));
console.log('\n--- physics acceptance (' + n + ' shots) ---');
for (const l of out) console.log(l);
if (failed.length) { console.log('\n' + failed.length + ' FAILED'); process.exit(1); }
console.log('\nall physics tests passed');
