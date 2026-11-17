-- Toegangstest per rol met fictieve gebruikers. Draait lokaal (zie tests/README) en kan ook
-- tegen Supabase draaien in een SQL-sessie als postgres (de set role/claims werken daar hetzelfde).
\set ON_ERROR_STOP on
\set QUIET on
begin;

-- fictieve accounts (trigger maakt de profielen)
insert into auth.users (id, email, raw_app_meta_data) values
 ('00000000-0000-0000-0000-000000000001', 'noor@voorbeeld.nl',  '{"rol":"begeleider"}'),
 ('00000000-0000-0000-0000-000000000002', 'samira@voorbeeld.nl','{"rol":"deelnemer"}'),
 ('00000000-0000-0000-0000-000000000003', 'petra@voorbeeld.nl', '{"rol":"werkgever"}'),
 ('00000000-0000-0000-0000-000000000004', 'kees@voorbeeld.nl',  '{"rol":"gemeente"}'),
 ('00000000-0000-0000-0000-000000000005', 'admin@voorbeeld.nl', '{"rol":"beheerder"}'),
 ('00000000-0000-0000-0000-000000000006', 'bram@voorbeeld.nl',  '{"rol":"begeleider"}'),
 ('00000000-0000-0000-0000-000000000007', 'daniel@voorbeeld.nl','{"rol":"deelnemer"}');

insert into public.organisaties (id, naam, soort) values
 ('10000000-0000-0000-0000-000000000001', 'Verbind & GO', 'verbind'),
 ('10000000-0000-0000-0000-000000000002', 'Fictief Logistiek BV', 'werkgever'),
 ('10000000-0000-0000-0000-000000000003', 'Gemeente Voorbeeldstad', 'gemeente');

insert into public.deelnemers (id, profiel_id, naam, fase, focus, status, werkgever_org_id, gemeente_org_id, domeinen) values
 ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Samira Haddad', 'Starten op het werk', 'Werktaal en vaktaal logistiek', 'actief', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003', '{werktaal,vaktaal,digitaal,werk,samen}'),
 ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000007', 'Daniël Vos', 'Doelen afspreken', 'Werkritme en coaching', 'actief', null, '10000000-0000-0000-0000-000000000003', '{werk,samen}');

insert into public.toewijzingen (deelnemer_id, profiel_id, rol, hoofd) values
 ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'begeleider', true),
 ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', 'werkgever', false),
 ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', 'gemeente', false),
 ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'begeleider', true),
 ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004', 'gemeente', false);

insert into public.doelen (id, deelnemer_id, titel, gedeeld_werkgever, gedeeld_gemeente, aangemaakt_door) values
 ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Veiligheidswoorden in het magazijn herkennen', true, true, '00000000-0000-0000-0000-000000000001'),
 ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'Intern doel: zelfvertrouwen bij navragen', false, false, '00000000-0000-0000-0000-000000000001');
insert into public.notities (deelnemer_id, tekst, auteur_id) values ('20000000-0000-0000-0000-000000000001', 'INTERNE NOTITIE', '00000000-0000-0000-0000-000000000001');
insert into public.evaluaties (deelnemer_id, tekst, gedeeld_werkgever, gedeeld_gemeente, auteur_id) values
 ('20000000-0000-0000-0000-000000000001', 'Gedeelde evaluatie', true, true, '00000000-0000-0000-0000-000000000001'),
 ('20000000-0000-0000-0000-000000000001', 'Interne evaluatie', false, false, '00000000-0000-0000-0000-000000000001');
insert into public.opdrachten (id, deelnemer_id, titel, instructie, toegewezen_door) values ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Veiligheidswoorden', 'Schrijf vijf woorden op.', '00000000-0000-0000-0000-000000000001');
insert into public.afspraken (id, deelnemer_id, titel, start, gedeeld_werkgever, aangemaakt_door) values
 ('50000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Werkplekbezoek', now() + interval '2 day', true, '00000000-0000-0000-0000-000000000001'),
 ('50000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'Begeleidingsgesprek', now() + interval '3 day', false, '00000000-0000-0000-0000-000000000001');
insert into public.metingen (id, deelnemer_id, datum, soort, gedeeld_werkgever, gedeeld_gemeente, auteur_id) values
 ('60000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '2026-10-14', 'nulmeting', true, true, '00000000-0000-0000-0000-000000000001');
insert into public.meting_niveaus (meting_id, item_id, niveau) values
 ('60000000-0000-0000-0000-000000000001', 'wt1', 2), ('60000000-0000-0000-0000-000000000001', 'wt2', 1),
 ('60000000-0000-0000-0000-000000000001', 'dg1', 1), ('60000000-0000-0000-0000-000000000001', 'dg2', 2),
 ('60000000-0000-0000-0000-000000000001', 'wc1', 3), ('60000000-0000-0000-0000-000000000001', 'sw1', 2);
insert into public.documenten (deelnemer_id, titel, storage_pad, zichtbaar_voor, geupload_door) values
 ('20000000-0000-0000-0000-000000000001', 'Trajectplan', '20000000-0000-0000-0000-000000000001/trajectplan.pdf', '{deelnemer,gemeente}', '00000000-0000-0000-0000-000000000001'),
 ('20000000-0000-0000-0000-000000000001', 'Interne aantekening', '20000000-0000-0000-0000-000000000001/intern.pdf', '{}', '00000000-0000-0000-0000-000000000001');

-- hulpmacro: wissel van gebruiker
create or replace function pg_temp.als(u text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', case u when 'noor' then '00000000-0000-0000-0000-000000000001' when 'samira' then '00000000-0000-0000-0000-000000000002' when 'petra' then '00000000-0000-0000-0000-000000000003' when 'kees' then '00000000-0000-0000-0000-000000000004' when 'admin' then '00000000-0000-0000-0000-000000000005' when 'bram' then '00000000-0000-0000-0000-000000000006' when 'daniel' then '00000000-0000-0000-0000-000000000007' else '' end, true) $$;

create temp table verwacht (gebruiker text, wat text, verwacht int, gevonden int);
grant all on verwacht to authenticated, anon;
create or replace function pg_temp.check(u text, wat text, q text, exp int) returns void language plpgsql as $$
declare n int;
begin
  perform pg_temp.als(u);
  execute 'select count(*) from (' || q || ') x' into n;
  insert into verwacht values (u, wat, exp, n);
end $$;

set role authenticated;

-- begeleider Noor: alles van haar deelnemers
select pg_temp.check('noor', 'deelnemers', 'select id, naam from public.deelnemers', 2);
select pg_temp.check('noor', 'doelen (incl. intern)', 'select * from public.doelen', 2);
select pg_temp.check('noor', 'notities', 'select * from public.notities', 1);
select pg_temp.check('noor', 'evaluaties', 'select * from public.evaluaties', 2);
select pg_temp.check('noor', 'niveaus per vaardigheid', 'select * from public.meting_niveaus', 6);
select pg_temp.check('noor', 'documenten', 'select * from public.documenten', 2);
select pg_temp.check('noor', 'logboek (geen toegang)', 'select * from public.logboek', 0);
-- andere begeleider Bram: niets
select pg_temp.check('bram', 'deelnemers', 'select id, naam from public.deelnemers', 0);
select pg_temp.check('bram', 'notities', 'select * from public.notities', 0);
select pg_temp.check('bram', 'metingen', 'select * from public.metingen', 0);
-- deelnemer Samira: alleen eigen traject
select pg_temp.check('samira', 'deelnemers (alleen zichzelf)', 'select id, naam from public.deelnemers', 1);
select pg_temp.check('samira', 'doelen (ook interne doelen van begeleider, want eigen traject)', 'select * from public.doelen', 2);
select pg_temp.check('samira', 'notities (nooit)', 'select * from public.notities', 0);
select pg_temp.check('samira', 'afspraken', 'select * from public.afspraken', 2);
select pg_temp.check('samira', 'opdrachten', 'select * from public.opdrachten', 1);
select pg_temp.check('samira', 'documenten (alleen gedeeld met deelnemer)', 'select * from public.documenten', 1);
select pg_temp.check('samira', 'niveaus', 'select * from public.meting_niveaus', 6);
-- werkgever Petra: alleen gedeeld, geen taal
select pg_temp.check('petra', 'deelnemers (alleen Samira)', 'select id, naam from public.deelnemers', 1);
select pg_temp.check('petra', 'doelen (alleen gedeeld)', 'select * from public.doelen', 1);
select pg_temp.check('petra', 'notities (nooit)', 'select * from public.notities', 0);
select pg_temp.check('petra', 'evaluaties (alleen gedeeld)', 'select * from public.evaluaties', 1);
select pg_temp.check('petra', 'afspraken (alleen gedeeld)', 'select * from public.afspraken', 1);
select pg_temp.check('petra', 'opdrachten (nooit)', 'select * from public.opdrachten', 0);
select pg_temp.check('petra', 'niveaus (alleen digitaal/werk/samen: 4 van 6)', 'select * from public.meting_niveaus', 4);
select pg_temp.check('petra', 'documenten (niet gedeeld met werkgever)', 'select * from public.documenten', 0);
-- gemeente Kees: samenvatting
select pg_temp.check('kees', 'deelnemers (beide)', 'select id, naam from public.deelnemers', 2);
select pg_temp.check('kees', 'doelen (alleen gedeeld)', 'select * from public.doelen', 1);
select pg_temp.check('kees', 'notities (nooit)', 'select * from public.notities', 0);
select pg_temp.check('kees', 'afspraken (nooit)', 'select * from public.afspraken', 0);
select pg_temp.check('kees', 'metingen (kop, gedeeld)', 'select * from public.metingen', 1);
select pg_temp.check('kees', 'niveaus per vaardigheid (nooit)', 'select * from public.meting_niveaus', 0);
select pg_temp.check('kees', 'samenvatting per domein (4 domeinen in de meting)', 'select * from public.voortgang_per_domein(''20000000-0000-0000-0000-000000000001'')', 4);
select pg_temp.check('kees', 'documenten (gedeeld met gemeente)', 'select * from public.documenten', 1);
-- beheerder: gebruikers en toewijzingen, geen dossier
select pg_temp.check('admin', 'profielen (zonder e-mailkolom)', 'select id, naam, rol from public.profielen', 7);
select pg_temp.check('petra', 'profielen (alleen betrokkenen bij eigen traject: Noor, Samira, Kees, zichzelf)', 'select id, naam, rol from public.profielen', 4);
select pg_temp.check('admin', 'profielen met e-mail via functie', 'select * from public.beheer_gebruikers()', 7);
select pg_temp.check('admin', 'deelnemers (namen)', 'select id, naam from public.deelnemers', 2);
select pg_temp.check('admin', 'toewijzingen', 'select * from public.toewijzingen', 5);
select pg_temp.check('admin', 'notities (nooit)', 'select * from public.notities', 0);
select pg_temp.check('admin', 'evaluaties (nooit)', 'select * from public.evaluaties', 0);
select pg_temp.check('admin', 'metingen (nooit)', 'select * from public.metingen', 0);
select pg_temp.check('admin', 'documenten (nooit)', 'select * from public.documenten', 0);
select pg_temp.check('admin', 'logboek', 'select * from public.logboek where tabel in (''deelnemers'',''toewijzingen'',''doelen'',''notities'')', 10);
-- werkgever als samenvatting: alleen deelbare domeinen (digitaal, werk, samen)
select pg_temp.check('petra', 'samenvatting per domein (3 deelbare domeinen)', 'select * from public.voortgang_per_domein(''20000000-0000-0000-0000-000000000001'')', 3);

-- schrijfacties
  -- Samira levert in via functie; direct wijzigen mag niet
  select pg_temp.als('samira');
  select public.lever_opdracht_in('40000000-0000-0000-0000-000000000001', 'STOP: bij de heftruck.');
  select pg_temp.check('samira', 'opdracht ingeleverd', 'select * from public.opdrachten where status = ''ingeleverd''', 1);
  select public.vraag_wijziging('50000000-0000-0000-0000-000000000002', 'Kan het een uur later?');
  select pg_temp.check('samira', 'wijziging aangevraagd', 'select * from public.afspraken where status = ''wijziging_aangevraagd''', 1);
-- directe update door deelnemer op feedback: RLS -> 0 rijen geraakt
select pg_temp.als('samira');
with u as (update public.opdrachten set feedback = 'ik geef mezelf feedback' where id = '40000000-0000-0000-0000-000000000001' returning 1) insert into verwacht select 'samira', 'eigen feedback schrijven (moet 0 zijn)', 0, count(*) from u;
-- werkgever probeert een notitie te lezen via join (moet 0)
select pg_temp.check('petra', 'notities via join', 'select n.* from public.notities n join public.deelnemers d on d.id = n.deelnemer_id', 0);
-- Bram probeert een deelnemer in te voegen: mag (rol begeleider), maar ziet hem daarna niet zonder toewijzing
select pg_temp.als('bram');
insert into public.deelnemers (naam) values ('Nieuwe deelnemer van Bram');
select pg_temp.check('bram', 'nieuwe deelnemer zonder toewijzing (ziet 0)', 'select id, naam from public.deelnemers', 0);
-- beheerder zet rol via functie; gewone gebruiker mag eigen rol niet veranderen
select pg_temp.als('admin');
select public.beheer_profiel('00000000-0000-0000-0000-000000000006', 'begeleider', '10000000-0000-0000-0000-000000000001', true);
select pg_temp.als('samira');
do $$ begin
  begin
    update public.profielen set rol = 'beheerder' where id = auth.uid();
    insert into verwacht values ('samira', 'eigen rol wijzigen (moet geweigerd worden)', 1, 0);
  exception when insufficient_privilege then
    insert into verwacht values ('samira', 'eigen rol wijzigen (moet geweigerd worden)', 1, 1);
  end;
end $$;
-- zelf aanmelden met een verzonnen rol: wordt een inactieve deelnemer zonder toegang
reset role;
insert into auth.users (id, email, raw_user_meta_data) values ('00000000-0000-0000-0000-000000000099', 'hacker@voorbeeld.nl', '{"rol":"beheerder"}');
insert into verwacht select 'aanmelder', 'zelf aanmelden als beheerder (moet inactieve deelnemer zijn)', 1, count(*)::int from public.profielen where id = '00000000-0000-0000-0000-000000000099' and rol = 'deelnemer' and not actief;
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000099', true);
insert into verwacht select 'aanmelder', 'is_beheerder (moet 0 zijn)', 0, (public.is_beheerder())::int;
insert into verwacht select 'aanmelder', 'deelnemers zien (moet 0 zijn)', 0, count(*)::int from public.deelnemers;
insert into verwacht select 'aanmelder', 'organisaties zien (moet 0 zijn)', 0, count(*)::int from public.organisaties;
select pg_temp.check('petra', 'organisaties (alleen eigen, als die is ingesteld)', 'select * from public.organisaties', 0);
select pg_temp.check('noor', 'organisaties (begeleider ziet alle)', 'select * from public.organisaties', 3);
-- anon ziet niets
reset role; set role anon;
do $$ declare n int; begin
  begin execute 'select count(*) from public.deelnemers' into n; insert into verwacht values ('anon', 'deelnemers (moet geweigerd worden)', 1, 0);
  exception when insufficient_privilege then insert into verwacht values ('anon', 'deelnemers (moet geweigerd worden)', 1, 1); end;
end $$;
reset role;

\set QUIET off
select gebruiker, wat, verwacht, gevonden, case when verwacht = gevonden then 'OK' else 'FOUT' end as uitkomst from verwacht order by gebruiker, wat;
select count(*) filter (where verwacht <> gevonden) as fouten, count(*) as totaal from verwacht;
rollback;
