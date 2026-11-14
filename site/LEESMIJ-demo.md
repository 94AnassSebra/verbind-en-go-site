# Verbind & GO — demo-scenario voor een presentatie

De gebouwde site staat in `dist/`. Starten: `start.sh` (Mac/Linux) of `start.bat` (Windows), of dubbelklik op `dist/index.html`. Zie README.md voor live zetten.

## Starten

**Snelste manier:** dubbelklik op `index.html`. Alles werkt direct in Chrome, ook zonder server.

**Via de terminal (aanbevolen voor een presentatie):**

```bash
cd verbind-en-go-demo
python3 -m http.server 8080
```

Open daarna http://localhost:8080 in Chrome. Of gebruik `start.sh` (Mac/Linux) of `start.bat` (Windows); die doen hetzelfde.

Alternatief met Node: `npx serve .`

## Internet nodig?

Alleen voor de lettertypen (Google Fonts). Zonder internet valt de site terug op een systeemlettertype; alle functionaliteit werkt offline.

## Bestanden

| Bestand | Pagina |
|---|---|
| `index.html` | Home |
| `werkgevers.html` | Voor werkgevers (situatiekiezer) |
| `gemeenten.html` | Voor gemeenten (fasenverkenner, indicatorenkiezer) |
| `aanpak.html` | Onze aanpak (interactieve trajectlijn) |
| `over-ons.html` | Over ons |
| `contact.html` | Contact (formulier met validatie, verstuurt niets) |
| `inloggen.html` | Inloggen (toegangsmatrix per rol) |
| `portaal.html` | Portaaldemo met rolschakelaar, inclusief Progressie (competentiekader en metingen) |
| `runtime.js` | Kleine runtime die de pagina's rendert |

## Demo-scenario voor een presentatie (circa 8 minuten)

1. **Home** — scroll door: hero met bento-compositie, expertisestrip, voor wie (gemeenten, werkgevers, diensten), de tijdlijn met vijf stappen, begeleiding, de portaal-impressie (klik *Bekijk het portaal*), herkenbare situaties en de twee hoofdacties onderaan.
2. **Werkgevers** — klik de vier situaties aan; laat zien hoe de aanpak per situatie verandert.
3. **Gemeenten** — klik door de vijf fasen; vink daarna indicatoren aan en uit en wijs op de samenvatting die meebeweegt. Dit is precies wat de gemeente in het portaal ziet.
4. **Inloggen** — klik op Werkgever, dan op Gemeente: de kolom licht op. Dit is het toegangsmodel.
5. **Portaal, als begeleider** — op het dashboard staat bij elke deelnemer een mini-voortgangslijn met "x van y vooruit". Open Samira. Klik *+ Leerdoel* en sla er een op. Klik *+ Afspraak*, kies een datum, koppel een opdracht en vink *Delen met werkgever* aan.
6. **Portaal, als deelnemer** (rolschakelaar bovenaan) — de nieuwe afspraak en opdracht staan op het dashboard, naast de kaart *Wat kan ik al?* met een ring en een balk per domein. Open de opdracht, vul een antwoord in en lever in.
7. **Portaal, als begeleider** — onder *Wacht op mij* staat de ingeleverde opdracht. Geef feedback en kies een beheersingsniveau.
7b. **Portaal, Progressie** (menu) — kies Samira (vijf domeinen, inclusief digitale vaardigheden): bovenaan de kerngetallen (vaardigheden vooruit, zelfstandig of zeker, nog te ontwikkelen, meetmomenten), per domein een ring met het aandeel dat zelfstandig lukt, het competentieprofiel (radar: grijs = start, gekleurd = nu), de verdeling van niveaus (gestapelde balk start en nu), de progressielijn over de meetmomenten en per vaardigheid een balk start → nu. Klik *+ Meting vastleggen*: de vorige meting is voorgevuld, pas twee niveaus aan, schrijf een toelichting en sla op. De lijn en de tabellen veranderen direct. Kies daarna Daniël: alleen werkcompetenties en samenwerking, want hij heeft geen taalvraag. In de Leeromgeving staan nu ook digitale opdrachten (uren invoeren, een werkbericht sturen, veilige berichten herkennen).
8. **Portaal, als werkgever** — alleen de gedeelde werkafspraak en werkdoelen zijn zichtbaar; geen notities, geen opdrachten. Onderaan de medewerkerskaart staan balken voor werkcompetenties en samenwerking (grijs = start); onder *Voortgang* ziet de werkgever alleen die twee domeinen, geen taalniveaus.
9. **Portaal, als gemeente** — alleen de voortgangssamenvatting; op de trajectkaart een balk per domein plus een mini-lijn van het gemiddelde; onder *Voortgang* de kerngetallen, ringen, het competentieprofiel en de progressielijn, maar geen details per vaardigheid.
10. **Portaal, als beheerder** — rollen en toewijzingen; wijs een deelnemer aan een andere begeleider toe en schakel terug naar Begeleider om het effect te zien.

Alle gegevens in het portaal zijn fictief. Met *Demo opnieuw beginnen* zet u alles terug.

## Wat dit niet is

Dit is een frontenddemo. Er is geen echte inlog, geen opslag en geen verzending. Voor productie zijn authenticatie, autorisatie op de server, een database en beveiligde bestandsopslag nodig (zie het projectdocument *oplevering-eerste-versie*).
