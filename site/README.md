# Verbind & GO — website en portaaldemo

Deze map is alles wat nodig is om de website live te zetten en bij te houden. Er is geen database of server nodig: de site bestaat uit gewone HTML-bestanden die overal gehost kunnen worden.

```
site.config.json      ← bedrijfsgegevens en formulier-endpoint (hier vul je dingen in)
project/              ← de ontwerpbestanden (ook het Claude Design-canvas)
design/site.css       ← het gedeelde stijlblad van de website
tools/build.py        ← bouwt dist/ uit project/ + site.config.json
tools/check.py        ← controleert dist/ (links, nog in te vullen gegevens)
tools/sync_css.py     ← zet design/site.css in alle pagina's
dist/                 ← de kant-en-klare website (dit gaat online)
.github/workflows/    ← automatische bouw en publicatie op GitHub Pages
netlify.toml, vercel.json ← idem voor Netlify of Vercel
```

## In 15 minuten live (kies één route)

**Route A — Netlify, zonder techniek (snelst)**
1. Ga naar https://app.netlify.com/drop en sleep de map `dist/` erin. De site staat direct online op een tijdelijk adres.
2. Eigen domein: Netlify → *Domain settings* → *Add domain* en volg de DNS-stappen bij je domeinregistrar. HTTPS wordt automatisch geregeld.
3. Bij elke wijziging: opnieuw bouwen (zie hieronder) en `dist/` opnieuw slepen. Of koppel de GitHub-repo (route B) zodat het vanzelf gaat.

**Route B — GitHub Pages, volledig automatisch (aanbevolen)**
1. Maak op github.com een nieuwe repository (bijvoorbeeld `verbind-en-go-site`) en upload deze hele map (via GitHub Desktop of `git push`).
2. In de repository: *Settings → Pages → Build and deployment → Source: GitHub Actions*.
3. Klaar. Bij elke push naar `main` bouwt GitHub de site, controleert hem en zet hem live. Eigen domein: *Settings → Pages → Custom domain*.

**Route C — eigen hosting (bijv. TransIP, Strato, Hostnet)**
Upload de inhoud van `dist/` via FTP of de bestandsbeheerder naar de webroot (`public_html` of `www`). Zet `404.html` als foutpagina in als de hosting dat ondersteunt.

## Gegevens invullen (één bestand)

Open `site.config.json` en vul in wat je hebt:

| Veld | Wat gebeurt er |
|---|---|
| `email`, `telefoon`, `bereikbaarheid`, `adres` | Vervangen overal de gele "IN TE VULLEN"-markeringen (voet, contactpagina). |
| `kvk` | Komt in de voet te staan. |
| `privacyUrl` | Maakt van "Privacyverklaring" een link. Een privacyverklaring is verplicht zodra het formulier live staat. |
| `domein` | Zet canonical-links, `sitemap.xml` en `robots.txt` aan. Bijvoorbeeld `verbindengo.nl`. |
| `formEndpoint` | Zet het contactformulier aan (zie hieronder). |
| `ogImage` | Afbeelding voor als de link gedeeld wordt (1200×630 px). |

Daarna opnieuw bouwen: `python3 tools/build.py` (Mac/Linux) of `start.bat` (Windows). Bij GitHub Pages hoeft dat niet: pushen is genoeg.

## Contactformulier aanzetten (5 minuten, gratis)

Het formulier is nu in demostand: het valideert, maar verstuurt niets en zegt dat ook. Zo zet je het aan:
1. Maak een gratis account bij **Formspree** (formspree.io) of **Web3Forms** (web3forms.com) en maak een formulier aan met het e-mailadres waar berichten binnen moeten komen.
2. Kopieer het endpoint (bijvoorbeeld `https://formspree.io/f/abcdwxyz`) in `site.config.json` bij `formEndpoint`.
3. Bouw opnieuw. De gele melding verdwijnt, de knop heet "Bericht versturen" en de bezoeker ziet pas "Bedankt, uw bericht is verstuurd" als de dienst 200 OK terugstuurt. Mislukt het, dan ziet de bezoeker een duidelijke foutmelding met het directe contactadres.

Wat er wordt verstuurd: type aanvraag, naam, organisatie, e-mail, telefoon en toelichting. Niets meer. Het formulier vraagt bewust niet om BSN of dossierinformatie.

## Controleren

`python3 tools/check.py` laat per pagina zien wat nog in te vullen is en of alle interne links kloppen. Dit draait ook automatisch in GitHub Actions; een kapotte link blokkeert dan de publicatie.

## Teksten en foto's aanpassen

- Teksten staan in `project/*.dc.html` (één bestand per pagina). Zoek de zin, pas aan, bouw opnieuw.
- Foto's: elke foto-plek heeft een label "FOTO IN TE VULLEN: …". Vervang het betreffende `<div class="l-photo">`-blok door `<img src="afbeeldingen/naam.webp" alt="…" style="width:100%;border-radius:28px;aspect-ratio:4/3;object-fit:cover">` en zet het bestand in `dist/afbeeldingen/` (of in `project/` en kopieer mee). Gebruik WebP, maximaal ~200 kB per foto.
- Stijl (kleuren, knoppen, kaarten): `design/site.css`. Daarna `python3 tools/sync_css.py` en bouwen.
- Dezelfde `project/`-bestanden zijn het Claude Design-canvas; wijzigingen daar kunnen 1-op-1 hierheen gekopieerd worden.

## Wat dit wel en niet is

- **Website:** productieklaar na het invullen van gegevens, foto's en een privacyverklaring.
- **Portaal (`portaal.html`):** een demonstratie met fictieve gegevens en een rolschakelaar. Het staat op `noindex` en wordt door zoekmachines niet getoond. Het is géén beveiligd portaal: er is geen inlog, opslag of serverkant. Voor een echt portaal zijn authenticatie, autorisatie op de server, een database en beveiligde bestandsopslag nodig; zie het projectdocument *oplevering-eerste-versie*. Wil je de demo niet publiek, verwijder dan `portaal.html` uit `dist/` of haal `Inloggen.dc.html`'s demo-knop weg.

## Checklist vóór "echt live"

- [ ] `site.config.json` ingevuld (minimaal e-mail, telefoon, KvK).
- [ ] Privacyverklaring geplaatst en gekoppeld (`privacyUrl`).
- [ ] Contactformulier getest met een echt bericht.
- [ ] Foto's geplaatst (6 plekken) en teamleden op *Over ons* ingevuld met bevestigde gegevens.
- [ ] Domein gekoppeld, HTTPS actief, `domein` ingevuld zodat sitemap en canonical kloppen.
- [ ] `python3 tools/check.py` geeft geen kapotte links.

## Portaal: database (toegevoegd 14 november)

De map `supabase/` bevat het datamodel, de toegangsregels per rol en een toegangstest (51 controles). Alles is toegepast op het Supabase-project *verbind-en-go* (Frankfurt). Zie `supabase/README.md` voor het toegangsmodel, het toevoegen van gebruikers en de volgende stap (de portaalschermen aansluiten).
