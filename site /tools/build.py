#!/usr/bin/env python3
"""Bouwt de website van Verbind & GO.

    python3 tools/build.py              -> leest project/ en site.config.json, schrijft dist/
    python3 tools/build.py project dist  (paden optioneel)

Wat het script doet, zonder handwerk:
- zet de ontwerpbestanden (project/*.dc.html) om naar gewone HTML-pagina's + runtime.js;
- vult bedrijfsgegevens uit site.config.json in (e-mail, telefoon, adres, KvK, privacy);
- zet het contactformulier aan zodra formEndpoint is ingevuld;
- schrijft meta-beschrijvingen, Open Graph, favicon, sitemap.xml, robots.txt, 404.html;
- controleert dat elke pagina geldige XML/HTML is.
"""
import json, re, sys, html, pathlib, datetime
import xml.dom.minidom as minidom

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
SRC = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'project'
DIST = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / 'dist'
CFG_PATH = ROOT / 'site.config.json'
CFG = json.loads(CFG_PATH.read_text(encoding='utf-8')) if CFG_PATH.exists() else {}
CFG = {k: v for k, v in CFG.items() if not k.startswith('_')}
DIST.mkdir(parents=True, exist_ok=True)
# oude pagina's opruimen, zodat verwijderde pagina's (zoals de portaaldemo) niet online blijven
for old in DIST.glob('*.html'):
    old.unlink()

PAGES = {  # bestandsnaam op het canvas -> bestandsnaam in de export, beschrijving
    'Main.dc.html': ('index.html', 'Verbind & GO brengt taal, digitale vaardigheden, coaching en begeleiding op de werkvloer samen. Voor gemeenten en werkgevers. Samen op weg naar werk dat blijft.'),
    'Werkgevers.dc.html': ('werkgevers.html', 'Nieuwe medewerkers goed laten starten en blijven: werktaal, digitale vaardigheden, duidelijke werkafspraken en een vaste begeleider die ook de leidinggevende ondersteunt.'),
    'Gemeenten.dc.html': ('gemeenten.html', 'Eén traject voor taal, werk en persoonlijke doelen: intake, individuele doelen, uitvoering, evaluatie en nazorg, met voortgang op vooraf afgesproken indicatoren.'),
    'Aanpak.dc.html': ('aanpak.html', 'Vijf stappen, één doorlopende lijn: kennismaken, doelen afspreken, leren en oefenen, starten of groeien op het werk, evalueren en nazorg.'),
    'OverOns.dc.html': ('over-ons.html', 'Kennis van NT2-onderwijs, werktaal en vaktaal, digitale vaardigheden, coaching en begeleiding op de werkvloer, in één hand.'),
    'Contact.dc.html': ('contact.html', 'Plan een kennismaking of bespreek een samenwerking met Verbind & GO. Een eerste gesprek verplicht u tot niets.'),
    'Inloggen.dc.html': ('inloggen.html', 'Inloggen op het begeleidingsportaal van Verbind & GO. Iedere rol ziet alleen wat voor die rol bedoeld is.'),
    # Portaal.dc.html (demo) wordt bewust niet gepubliceerd; alleen voor presentaties.
}
SHARED = ['Header.dc.html', 'Footer.dc.html']
VOID = r'(input|br|img|hr|meta|link|source|wbr)'
NOINDEX = {'portaal.html'}

def parse_dc(path):
    s = path.read_text(encoding='utf-8')
    title = re.search(r'<title>(.*?)</title>', s, re.S).group(1)
    helmet = re.search(r'<helmet>([\s\S]*?)</helmet>', s).group(1)
    body = re.search(r'</helmet>([\s\S]*?)</x-dc>', s).group(1).strip()
    m = re.search(r'<script type="text/x-dc" data-dc-script data-props=\'(.*?)\'>([\s\S]*?)</script>', s)
    props = json.loads(html.unescape(m.group(1)))
    src = m.group(2)
    for old, (new, _d) in PAGES.items():
        src = src.replace("'%s'" % old, "'%s'" % new).replace('"%s"' % old, '"%s"' % new)
    return title, helmet, body, props, src

def mark(value, link=None):
    v = html.escape(value)
    return f'<a href="{link}" style="color:inherit;font-weight:600">{v}</a>' if link else v

def apply_config(body):
    """Vervangt de IN TE VULLEN-markeringen door echte gegevens uit site.config.json."""
    def sub_mark(pattern, replacement):
        nonlocal body
        body = re.sub(pattern, replacement, body, flags=re.I)
    if CFG.get('email'):
        e = CFG['email']
        sub_mark(r'<mark class="(?:l|lf)-mark"[^>]*>IN TE VULLEN: E-MAILADRES</mark>', mark(e, 'mailto:' + e))
    if CFG.get('telefoon'):
        t = CFG['telefoon']
        sub_mark(r'<mark class="(?:l|lf)-mark"[^>]*>IN TE VULLEN: TELEFOONNUMMER</mark>', mark(t, 'tel:' + re.sub(r'[^+\d]', '', t)))
    if CFG.get('bereikbaarheid'):
        sub_mark(r'<mark class="(?:l|lf)-mark"[^>]*>IN TE VULLEN: BEREIKBAARHEID</mark>', mark(CFG['bereikbaarheid']))
    if CFG.get('adres'):
        sub_mark(r'<mark class="(?:l|lf)-mark"[^>]*>IN TE VULLEN: ADRES OF WERKGEBIED</mark>', mark(CFG['adres']))
    if CFG.get('kvk'):
        sub_mark(r'KvK <mark class="lf-mark"[^>]*>IN TE VULLEN</mark>', 'KvK ' + mark(CFG['kvk']))
    if CFG.get('privacyUrl'):
        sub_mark(r'Privacyverklaring <mark class="lf-mark"[^>]*>NOG OP TE STELLEN</mark>', f'<a href="{html.escape(CFG["privacyUrl"])}" style="color:inherit">Privacyverklaring</a>')
    if CFG.get('formEndpoint'):
        body = body.replace('Eerste versie · formulieren nog niet aangesloten', 'Gebouwd met zorg · ' + str(datetime.date.today().year))
        body = body.replace("const txt = 'IN TE VULLEN: e-mailadres';", "const txt = '%s';" % (CFG.get('email') or 'IN TE VULLEN: e-mailadres'))
    return body

def to_xml(body):
    body = re.sub(r'<' + VOID + r'\b([^>]*?)\s*/?>', lambda m: '<%s%s/>' % (m.group(1), m.group(2)), body)
    body = body.replace('&nbsp;', '&#160;')
    body = re.sub(r'\s(novalidate|open|disabled|checked|required|autofocus)(?=[\s>/])', r' \1="\1"', body)
    for old, (new, _d) in PAGES.items():
        body = body.replace('href="%s"' % old, 'href="%s"' % new)
    try:
        minidom.parseString('<r>' + body + '</r>')
    except Exception as e:
        print('XML-fout in template:', e); raise
    return body

comps = {}
for name in SHARED + list(PAGES):
    title, helmet, body, props, src = parse_dc(SRC / name)
    body = apply_config(body)
    src = apply_config(src)
    comps[name.replace('.dc.html', '')] = dict(title=title, helmet=helmet, tpl=to_xml(body), props=props, src=src)

def js_json(obj):
    return json.dumps(obj, ensure_ascii=False).replace('</', '<\\/')

runtime = (HERE / 'runtime.js').read_text(encoding='utf-8')
(DIST / 'runtime.js').write_text(runtime, encoding='utf-8')

FAVICON = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='16' fill='%231F5D5A'/%3E%3Cpath d='M12 20c16 0 18 12 28 12M12 44c16 0 18-12 28-12M12 32h36' fill='none' stroke='%23FFFFFF' stroke-width='4' stroke-linecap='round'/%3E%3Ccircle cx='50' cy='32' r='6' fill='%23F0862B'/%3E%3C/svg%3E"
SETTLED_CSS = '<style>[data-settled] .o-w,[data-settled] .o-fade{animation:none!important;opacity:1!important;transform:none!important}</style>'
site_cfg_public = {k: CFG.get(k, '') for k in ('organisatie', 'email', 'telefoon', 'formEndpoint')}
base = (CFG.get('domein') or '').rstrip('/')
if base and not base.startswith('http'):
    base = 'https://' + base

# Beveiliging: lettertypen lokaal (geen verzoeken naar Google), en een Content-Security-Policy.
import shutil
shutil.copytree(ROOT / 'fonts', DIST / 'fonts', dirs_exist_ok=True)
_connect = ["'self'"] + [u for u in [CFG.get('supabaseUrl', ''), re.sub(r'^(https://[^/]+).*$', r'\1', CFG.get('formEndpoint', ''))] if u]
CSP = ('<meta http-equiv="Content-Security-Policy" content="default-src \'self\'; '
       "script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; font-src 'self'; "
       "img-src 'self' data:; connect-src " + ' '.join(_connect) + "; form-action 'self'; base-uri 'self'; object-src 'none'\">")
written = []
for name, (out, desc) in PAGES.items():
    key = name.replace('.dc.html', '')
    page = comps[key]
    used = [key] + (['Header', 'Footer'] if '<dc-import' in page['tpl'] else [])
    heads = ''.join(comps[k]['helmet'] for k in used)
    seen, parts = set(), []
    for line in heads.split('\n'):
        if line.strip().startswith('<link') and line.strip() in seen: continue
        seen.add(line.strip()); parts.append(line)
    heads = '\n'.join(p for p in parts if 'fonts.googleapis.com' not in p and 'fonts.gstatic.com' not in p)
    reg = ''.join('DC.register(%s,%s);\n' % (js_json(k), js_json({'tpl': comps[k]['tpl'], 'props': comps[k]['props'], 'src': comps[k]['src']})) for k in used)
    canonical = f'<link rel="canonical" href="{base}/{"" if out == "index.html" else out}">' if base else ''
    robots = '<meta name="robots" content="noindex,nofollow">' if out in NOINDEX else ''
    og_img = f'<meta property="og:image" content="{html.escape(CFG["ogImage"])}">' if CFG.get('ogImage') else ''
    doc = f'''<!doctype html>
<html lang="nl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{page['title']}</title>
<meta name="description" content="{html.escape(desc)}">
<meta property="og:title" content="{page['title']}">
<meta property="og:description" content="{html.escape(desc)}">
<meta property="og:type" content="website">
<meta property="og:locale" content="nl_NL">
{og_img}
<meta name="theme-color" content="#1F5D5A">
<link rel="icon" href="{FAVICON}">
{CSP}
<meta name="referrer" content="strict-origin-when-cross-origin">
<link rel="stylesheet" href="fonts/fonts.css">
{canonical}
{robots}
{heads}
{SETTLED_CSS}
</head>
<body>
<div id="app"></div>
<script>window.SITE_CONFIG={js_json(site_cfg_public)};</script>
<script src="runtime.js"></script>
<script>
{reg}DC.mount({js_json(key)}, '#app');
</script>
</body>
</html>
'''
    doc = re.sub(r'\n{3,}', '\n\n', doc)
    (DIST / out).write_text(doc, encoding='utf-8')
    written.append(out)
    print('geschreven', out)

# 404, robots, sitemap
(DIST / '404.html').write_text(f'''<!doctype html><html lang="nl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Pagina niet gevonden — Verbind &amp; GO</title><link rel="icon" href="{FAVICON}"><link rel="stylesheet" href="/fonts/fonts.css"><style>body{{margin:0;font-family:Figtree,system-ui,sans-serif;color:#0F1F1F;background:#F7F4EE;display:grid;place-items:center;min-height:100dvh;padding:24px}}main{{max-width:560px;text-align:center}}h1{{font-family:Outfit,sans-serif;font-weight:800;font-size:clamp(36px,7vw,64px);letter-spacing:-.04em;margin:0 0 12px}}a{{display:inline-flex;align-items:center;min-height:52px;padding:0 24px;border-radius:999px;background:#0D3534;color:#fff;text-decoration:none;font-weight:600;margin-top:20px}}</style></head><body><main><p style="font-weight:700;letter-spacing:.16em;color:#1F5D5A;font-size:12px">404</p><h1>Deze pagina bestaat niet.</h1><p style="color:#4F6260;line-height:1.6">Misschien is de link verouderd. Ga terug naar de homepage of neem contact met ons op.</p><a href="/">Naar de homepage</a></main></body></html>''', encoding='utf-8')
if base:
    today = datetime.date.today().isoformat()
    urls = ''.join(f'<url><loc>{base}/{"" if p == "index.html" else p}</loc><lastmod>{today}</lastmod></url>' for p in written if p not in NOINDEX)
    (DIST / 'sitemap.xml').write_text(f'<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{urls}</urlset>', encoding='utf-8')
    (DIST / 'robots.txt').write_text(f'User-agent: *\nAllow: /\nDisallow: /portaal.html\nSitemap: {base}/sitemap.xml\n', encoding='utf-8')
else:
    (DIST / 'robots.txt').write_text('User-agent: *\nAllow: /\nDisallow: /portaal.html\n', encoding='utf-8')
(DIST / '.nojekyll').write_text('', encoding='utf-8')
print('klaar ·', 'formulier: LIVE' if CFG.get('formEndpoint') else 'formulier: demostand (formEndpoint leeg)')
