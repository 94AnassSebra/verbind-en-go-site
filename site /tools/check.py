#!/usr/bin/env python3
"""Controleert dist/ vóór publicatie.

    python3 tools/check.py          -> rapport; exitcode 1 bij kapotte links of ontbrekende bestanden

Meldt per pagina: nog in te vullen gegevens, interne links die nergens heen gaan, en of het
contactformulier live staat. Vul gegevens in via site.config.json en bouw opnieuw.
"""
import re, sys, json, pathlib
ROOT = pathlib.Path(__file__).resolve().parents[1]
DIST = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'dist'
cfg = json.loads((ROOT / 'site.config.json').read_text(encoding='utf-8'))
pages = sorted(p for p in DIST.glob('*.html') if p.name != '404.html')
if not pages:
    print('Geen dist/*.html gevonden. Bouw eerst: python3 tools/build.py'); sys.exit(1)
fout = 0
print(f'Controle van {DIST}\n')
for p in pages:
    s = p.read_text(encoding='utf-8')
    marks = sorted(set(re.findall(r'(?:IN TE VULLEN|NOG OP TE STELLEN|FOTO IN TE VULLEN)[^<"\x27;\\]{0,70}', s)))
    links = set(re.findall(r'href=\\?"([a-z0-9\-]+\.html)', s)) | set(re.findall(r"'([a-z0-9\-]+\.html)'", s))
    missing = sorted(l for l in links if not (DIST / l).exists())
    status = 'OK' if not missing else 'FOUT'
    if missing: fout += 1
    print(f'{p.name:16} {status}')
    for l in missing: print(f'    kapotte link -> {l}')
    for m in marks[:12]: print(f'    nog in te vullen: {m.strip()}')
    if len(marks) > 12: print(f'    … en {len(marks) - 12} meer')
print()
print('Contactformulier:', 'LIVE ->' + cfg.get('formEndpoint', '') if cfg.get('formEndpoint') else 'demostand (zet formEndpoint in site.config.json)')
print('Domein:', cfg.get('domein') or 'niet ingevuld (sitemap en canonical worden dan overgeslagen)')
leeg = [k for k in ('email', 'telefoon', 'adres', 'kvk', 'privacyUrl') if not cfg.get(k)]
print('Lege velden in site.config.json:', ', '.join(leeg) if leeg else 'geen')
sys.exit(1 if fout else 0)
