# Portaal — database en toegang (Supabase)

Project: **verbind-en-go** · regio Frankfurt (eu-central-1) · `https://tqxnjouxtimcgjvcmxjm.supabase.co`
Publieke sleutel voor de frontend: `sb_publishable_VgycS_QCI8iwohx92Y5qyw_LQ5hXhqI` (mag in de website staan; de toegangsregels zitten in de database, niet in de sleutel).

```
migrations/0001_schema.sql    tabellen, enums, triggers (updated_at, logboek, profiel bij nieuw account)
migrations/0002_toegang.sql   Row Level Security per rol, hulpfuncties, API-functies
migrations/0003_kader.sql     competentiekader (5 domeinen, 18 vaardigheden) en 8 opdrachten
migrations/0004_opslag.sql    bestandsopslag 'documenten' met toegang via de documententabel
migrations/0005_adviezen.sql  opvolging van de Supabase security-adviseur
tests/01_toegang_test.sql     51 controles: wie ziet wat (draait lokaal met tests/run_local.sh)
```

Alle migraties zijn toegepast op het project (14 november 2026). De toegangstest slaagt lokaal én op het project (51/51), zonder dat er gegevens zijn achtergebleven.

## Toegangsmodel (zoals afgedwongen in de database)

| | deelnemer | begeleider (toegewezen) | werkgever (toegewezen) | gemeente (toegewezen) | beheerder |
|---|---|---|---|---|---|
| Deelnemergegevens | eigen | ja | ja (naam, functie, status) | ja | namen (voor toewijzen) |
| Doelen | eigen | ja | alleen gedeeld | alleen gedeeld | nee |
| Afspraken | eigen (wijziging aanvragen via functie) | ja | alleen gedeeld | nee | nee |
| Opdrachten | eigen (inleveren via functie) | ja + feedback | nee | nee | nee |
| Evaluaties | eigen | ja | alleen gedeeld | alleen gedeeld | nee |
| Interne notities | nee | ja | nee | nee | nee |
| Metingen per vaardigheid | eigen | ja | alleen digitaal, werk, samen (gedeeld) | nee | nee |
| Samenvatting per domein | eigen | ja | deelbare domeinen | alleen gedeeld | nee |
| Documenten | als gedeeld | ja | als gedeeld | als gedeeld | nee |
| Gebruikers, rollen, toewijzingen, kader | — | eigen deelnemers toewijzen | — | — | ja |
| Logboek | — | — | — | — | lezen |

Een account zonder toewijzing ziet niets. Een begeleider die zelf een deelnemer aanmaakt, ziet die pas na een toewijzing (beheerder of hoofdbegeleider). E-mailadressen zijn niet via de API leesbaar; beheerders halen ze op met `beheer_gebruikers()`. Rollen worden alleen gewijzigd via `beheer_profiel()` (beheerder).

## Gebruikers toevoegen

1. Supabase-dashboard → *Authentication → Users → Invite user*. Vul bij *User metadata* `{"naam": "Voornaam Achternaam", "rol": "begeleider"}` in (rol: deelnemer, begeleider, werkgever, gemeente, beheerder). De uitnodigingsmail komt van Supabase; eigen afzender en tekst stel je in onder *Authentication → Email templates / SMTP*.
2. Het profiel ontstaat automatisch. Een beheerder koppelt de persoon aan een organisatie (`beheer_profiel`) en aan deelnemers (`toewijzingen`).
3. Eerste beheerder: nodig jezelf uit met rol `beheerder`.

Aanbevolen instellingen (dashboard → *Authentication*): e-mailbevestiging aan, wachtwoordlengte ≥ 12, MFA (TOTP) verplicht voor begeleiders en beheerders zodra het portaal live gaat; sessieduur beperken.

## Voor de frontend (volgende stap)

- Gebruik `@supabase/supabase-js` met de URL en de publieke sleutel hierboven.
- `profielen`: altijd expliciete kolommen selecteren (`id, naam, rol, organisatie_id, functie, actief`); `select *` faalt bewust (e-mail is afgeschermd).
- Deelnemer-acties: `rpc('lever_opdracht_in', {p_opdracht, p_antwoord})`, `rpc('vraag_wijziging', {p_afspraak, p_tekst})`.
- Voortgang per domein (ook voor gemeente/werkgever): `rpc('voortgang_per_domein', {p_deelnemer})`.
- Beheer: `rpc('beheer_gebruikers')`, `rpc('beheer_profiel', {...})`.
- Documenten: bestand uploaden naar bucket `documenten` op pad `<deelnemer_id>/<bestandsnaam>` én een record in `documenten` met `zichtbaar_voor`.

## Lokaal testen

Vereist PostgreSQL 16. `tests/00_supabase_mock.sql` bootst `auth.uid()` en de rollen na.
```
export PGHOST=... PGPORT=... PGUSER=postgres
supabase/tests/run_local.sh
```

## Wat nog moet vóór echte deelnemers

- Verwerkersovereenkomst met Supabase (standaard DPA in het dashboard), afspraken met gemeenten over gegevensdeling en bewaartermijnen, privacyverklaring, korte DPIA.
- Bewaartermijnen technisch: een opschoonroutine voor afgeronde trajecten (nog te bouwen, termijn is een beleidskeuze).
- Back-ups staan aan op Pro (dagelijks); point-in-time recovery is een optie.
- Logging van *lezen* gebeurt niet in de database (wel van alle wijzigingen). Wil je inzage-logging, dan kan dat via de API-laag (Edge Function) — later te bepalen.
