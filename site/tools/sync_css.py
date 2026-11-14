#!/usr/bin/env python3
"""Zet design/site.css in de <helmet> van elke websitepagina (tussen markers).
Gebruik: python3 tools/sync_css.py  (vanuit de map vg/)
"""
import re, pathlib, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]
CSS = (ROOT / 'design' / 'site.css').read_text(encoding='utf-8').strip()
PAGES = ['Main', 'Aanpak', 'Gemeenten', 'Werkgevers', 'OverOns', 'Contact', 'Inloggen']
START, END = '/* @site-css */', '/* @/site-css */'
OLD_BLOCKS = [r'\n/\* === moderne laag \(6 nov\) === \*/[\s\S]*?(?=@media \(prefers-reduced-motion: reduce\)\{\*\{animation:none)',
              r'\n/\* === homepagina \(6 nov\) === \*/[\s\S]*?(?=@media \(prefers-reduced-motion: reduce\)\{\*\{animation:none)']
for name in PAGES:
    p = ROOT / 'project' / f'{name}.dc.html'
    s = p.read_text(encoding='utf-8')
    for rx in OLD_BLOCKS:
        s = re.sub(rx, '\n', s, count=1)
    s = re.sub(re.escape(START) + r'[\s\S]*?' + re.escape(END) + r'\n?', '', s)
    block = f'{START}\n{CSS}\n{END}\n'
    if '</style>\n</helmet>' not in s:
        print('geen helmet-einde in', name); sys.exit(1)
    s = s.replace('</style>\n</helmet>', block + '</style>\n</helmet>', 1)
    p.write_text(s, encoding='utf-8')
    print('gesynchroniseerd', name)
