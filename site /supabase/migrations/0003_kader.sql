-- Competentiekader (startversie; door een beheerder aan te passen) en opdrachtenbibliotheek.
insert into public.kader_domeinen (id, naam, kort, kleur, uitleg, deelbaar_werkgever, volgorde) values
 ('werktaal', 'Werktaal', 'Taal', '#2A7A74', 'Nederlands dat nodig is om mee te doen op het werk.', false, 1),
 ('vaktaal', 'Vaktaal', 'Vaktaal', '#F0862B', 'Begrippen en documenten van de eigen sector.', false, 2),
 ('digitaal', 'Digitale vaardigheden', 'Digitaal', '#C94F7C', 'Digitale handelingen die op het werk nodig zijn.', true, 3),
 ('werk', 'Werkcompetenties', 'Werken', '#3B6FB6', 'Vaardigheden die iedere medewerker nodig heeft.', true, 4),
 ('samen', 'Samenwerking', 'Samen', '#8A5BB5', 'Meedoen in het team.', true, 5);

insert into public.kader_items (id, domein_id, naam, uitleg, volgorde) values
 ('wt1', 'werktaal', 'Instructies begrijpen', 'Begrijpt een mondelinge werkinstructie en voert die uit.', 1),
 ('wt2', 'werktaal', 'Vragen stellen en navragen', 'Vraagt na als iets onduidelijk is.', 2),
 ('wt3', 'werktaal', 'Veiligheidswoorden herkennen', 'Herkent en begrijpt waarschuwingen en veiligheidsborden.', 3),
 ('wt4', 'werktaal', 'Kort overleggen', 'Kan een korte werkafspraak maken met een collega.', 4),
 ('vt1', 'vaktaal', 'Vakbegrippen gebruiken', 'Gebruikt de begrippen van de eigen afdeling.', 1),
 ('vt2', 'vaktaal', 'Werkdocumenten lezen', 'Leest een picklijst, rooster of werkbon.', 2),
 ('vt3', 'vaktaal', 'Melden en rapporteren', 'Meldt een afwijking of storing in de juiste woorden.', 3),
 ('dg1', 'digitaal', 'Rooster-app gebruiken', 'Bekijkt het rooster en ruilt of meldt een dienst via de app.', 1),
 ('dg2', 'digitaal', 'Uren registreren', 'Voert gewerkte uren op tijd en juist in.', 2),
 ('dg3', 'digitaal', 'E-mail en berichten op het werk', 'Leest werkberichten en reageert kort en duidelijk.', 3),
 ('dg4', 'digitaal', 'Veilig omgaan met wachtwoorden en gegevens', 'Gebruikt eigen inlog, deelt geen wachtwoorden en herkent verdachte berichten.', 4),
 ('wc1', 'werk', 'Op tijd en aanwezig', 'Komt op tijd en meldt zich af volgens afspraak.', 1),
 ('wc2', 'werk', 'Zelfstandig werken', 'Werkt een taak af zonder herhaalde aansturing.', 2),
 ('wc3', 'werk', 'Werktempo en nauwkeurigheid', 'Haalt het afgesproken tempo met weinig fouten.', 3),
 ('wc4', 'werk', 'Veilig werken', 'Houdt zich aan de veiligheidsregels.', 4),
 ('sw1', 'samen', 'Hulp vragen en aanbieden', 'Vraagt hulp op tijd en helpt collega''s.', 1),
 ('sw2', 'samen', 'Feedback ontvangen', 'Luistert naar feedback en past gedrag aan.', 2),
 ('sw3', 'samen', 'Meedoen in het team', 'Doet mee in overleg en pauzes.', 3);

insert into public.opdrachten_bibliotheek (titel, soort, duur_minuten, instructie) values
 ('Veiligheidswoorden in het magazijn', 'Vaktaal', 15, 'Loop door het magazijn (of kijk naar de foto''s). Schrijf vijf woorden of borden op die met veiligheid te maken hebben. Schrijf bij elk woord: wat moet je doen?'),
 ('Navragen als iets onduidelijk is', 'Werktaal', 10, 'Je teamleider zegt: "Zet die pallets straks even weg." Schrijf drie vragen op die je kunt stellen om te weten wat precies de bedoeling is.'),
 ('Een korte werkafspraak maken', 'Werktaal', 10, 'Je wilt een pauze ruilen met een collega. Schrijf op wat je zegt. Gebruik: wanneer, waarom en wat je terugdoet.'),
 ('Ziekmelden: wat zeg je?', 'Werktaal', 10, 'Je bent ziek en kunt niet werken. Schrijf op wat je zegt als je belt: wie je bent, dat je ziek bent, en wanneer je denkt terug te zijn.'),
 ('Je uren invoeren in de app', 'Digitaal', 15, 'Open de uren-app van je werk (of de oefenversie). Voer de uren van gisteren in. Schrijf daarna op: welke stappen deed je, en waar twijfelde je?'),
 ('Een kort werkbericht sturen', 'Digitaal', 10, 'Je komt morgen een half uur later door een afspraak bij de tandarts. Schrijf het bericht dat je naar je leidinggevende stuurt. Kort, duidelijk en beleefd. Zet erin: wanneer je er wel bent.'),
 ('Veilig of niet? Berichten herkennen', 'Digitaal', 15, 'Je krijgt drie berichten: (1) "Uw wachtwoord verloopt, klik hier", (2) een roosterwijziging van je teamleider, (3) "U heeft een pakket, betaal €2". Schrijf per bericht: vertrouw je het wel of niet, en waarom?'),
 ('Feedback ontvangen', 'Werknemersvaardigheden', 10, 'Je teamleider zegt dat je te snel werkt en daardoor fouten maakt. Schrijf op wat je antwoordt en wat je morgen anders doet.');
