// Static audit: index.html must be one self-contained offline file (PRD: ships as a single
// HTML file, playable on a plane, a tablet, in a car with no signal). Dev-only tool.
import fs from 'node:fs';

const html = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const lines = html.split('\n');
const bad = [];
const forbidden = [
  [/<script[^>]+\bsrc\s*=/i, 'external <script src>'],
  [/<link[^>]+(href|src)\s*=/i, 'external <link>'],
  [/<img[^>]+\bsrc\s*=/i, 'external <img>'],
  [/<audio|<video|<iframe|<embed|<object/i, 'media/embedded element'],
  [/\b(https?:)?\/\/(?!\/)[a-z0-9.-]+\.[a-z]{2,}/i, 'absolute URL'],
  [/\b(fetch|XMLHttpRequest|EventSource|WebSocket|sendBeacon|importScripts)\s*\(/, 'network API'],
  [/\bimport\s+[\w{*]/, 'ES import'],
  [/\brequire\s*\(/, 'require()'],
  [/\.(mp3|ogg|wav|m4a|ttf|woff2?|png|jpe?g|gif|svg)\b/i, 'binary asset reference'],
  [/\bnew\s+Image\b|\bcreateObjectURL\b/, 'asset loading'],
];
for (const [re, why] of forbidden) {
  lines.forEach((l, i) => { if (re.test(l)) bad.push(`${why} @ line ${i + 1}: ${l.trim().slice(0, 90)}`); });
}
const scripts = (html.match(/<script/gi) || []).length;
const sizeKb = (Buffer.byteLength(html) / 1024).toFixed(1);

if (bad.length) {
  console.log('FAIL not self-contained (' + sizeKb + ' kB, ' + lines.length + ' lines, ' + scripts + ' script blocks)');
  for (const b of bad) console.log('  ' + b);
  process.exit(1);
}
console.log(`PASS self-contained  ${sizeKb} kB  ${lines.length} lines  ${scripts} inline script block(s)  no network/asset references`);
