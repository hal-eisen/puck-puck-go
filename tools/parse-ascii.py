#!/usr/bin/env python3
"""Pull the #dtest block out of a dumped DOM and print it verbatim (the ASCII canvas map)."""
import sys, re, html

h = sys.stdin.read()
# the dump also contains the page's own source (including the literal string that creates
# this element), so take the longest real payload rather than the last match
m = [x for x in re.findall(r'<pre id="dtest"[^>]*>(.*?)</pre>', h, re.S) if x.strip()]
if not m:
    print('NO MAP: #dtest was empty - did the page load, and is ?debug&ascii set?')
    sys.exit(1)
print(html.unescape(max(m, key=len)).strip())
