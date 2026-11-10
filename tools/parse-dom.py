import sys, re, html

h = sys.stdin.read()
rows, errs = [], []
for tag, body in re.findall(r'<pre id="([a-z]+)"[^>]*>(.*?)</pre>', h, re.S):
    if tag not in ('dtest', 'derr') or not body.strip():
        continue
    for line in html.unescape(body).split('\n'):
        if re.match(r'^(PASS|FAIL) T', line):
            rows.append(line)
        elif tag == 'derr':
            errs.append(line)

seen, ordered = set(), []
for r in rows:
    key = r.split()[1]
    if key in seen:
        continue
    seen.add(key)
    ordered.append(r)

for r in ordered:
    print(r[:200])
fails = [r for r in ordered if r.startswith('FAIL')]
print('\n%d checks, %d failed' % (len(ordered), len(fails)))
if errs:
    print('\nPAGE ERRORS:')
    print('\n'.join(errs[:8]))
sys.exit(1 if (fails or errs or not ordered) else 0)
