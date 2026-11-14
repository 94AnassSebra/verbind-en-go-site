-- =====================================================================
-- Verbind & GO — portaal: toegangsregels (migratie 0002)
-- Alle toegang loopt via Row Level Security. Een account zonder toewijzing ziet niets.
--  deelnemer   : alleen het eigen traject
--  begeleider  : alleen toegewezen deelnemers, volledig dossier
--  werkgever   : alleen toegewezen medewerkers en wat expliciet gedeeld is; nooit notities, nooit taalniveaus
--  gemeente    : alleen toegewezen trajecten en gedeelde samenvattingen; geen details per vaardigheid
--  beheerder   : gebruikers, organisaties, toewijzingen, kader en logboek; geen dossierinhoud
-- =====================================================================

-- ---------- hulpfuncties (security definer, zodat ze niet zelf door RLS geblokkeerd worden) ----------
create or replace function public.mijn_rol() returns public.rol
language sql stable security definer set search_path = public as $$
  select rol from public.profielen where id = auth.uid() and actief
$$;

create or replace function public.is_beheerder() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select rol = 'beheerder' from public.profielen where id = auth.uid() and actief), false)
$$;

create or replace function public.mijn_deelnemer_id() returns uuid
language sql stable security definer set search_path = public as $$
  select d.id from public.deelnemers d join public.profielen p on p.id = d.profiel_id
  where p.id = auth.uid() and p.actief
$$;

-- Welke rol heeft de ingelogde gebruiker bij deze deelnemer? (null = geen toegang)
create or replace function public.rol_bij(d uuid) returns public.rol
language sql stable security definer set search_path = public as $$
  select case
    when exists (select 1 from public.deelnemers x join public.profielen p on p.id = x.profiel_id where x.id = d and p.id = auth.uid() and p.actief) then 'deelnemer'::public.rol
    else (select t.rol from public.toewijzingen t join public.profielen p on p.id = t.profiel_id
          where t.deelnemer_id = d and t.profiel_id = auth.uid() and p.actief and p.rol = t.rol)
  end
$$;

create or replace function public.is_begeleider_van(d uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.rol_bij(d) = 'begeleider'
$$;

-- Zijn ik en profiel p betrokken bij hetzelfde traject (als begeleider/werkgever/gemeente of als de deelnemer zelf)?
create or replace function public.deelt_traject_met(p uuid) returns boolean
language sql stable security definer set search_path = public as $$
  with mijn as (
    select deelnemer_id from public.toewijzingen where profiel_id = auth.uid()
    union select id from public.deelnemers where profiel_id = auth.uid()
  ), hun as (
    select deelnemer_id from public.toewijzingen where profiel_id = p
    union select id from public.deelnemers where profiel_id = p
  )
  select exists (select 1 from mijn join hun using (deelnemer_id))
$$;

create or replace function public.is_betrokkene_bij(a uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.afspraak_betrokkenen b where b.afspraak_id = a and b.profiel_id = auth.uid())
$$;

revoke all on function public.mijn_rol(), public.is_beheerder(), public.mijn_deelnemer_id(), public.rol_bij(uuid), public.is_begeleider_van(uuid), public.is_betrokkene_bij(uuid), public.deelt_traject_met(uuid) from public, anon;
grant execute on function public.mijn_rol(), public.is_beheerder(), public.mijn_deelnemer_id(), public.rol_bij(uuid), public.is_begeleider_van(uuid), public.is_betrokkene_bij(uuid), public.deelt_traject_met(uuid) to authenticated;

-- ---------- RLS aan op alle tabellen ----------
do $$
declare t text;
begin
  foreach t in array array['organisaties','profielen','deelnemers','toewijzingen','doelen','opdrachten_bibliotheek','opdrachten','afspraken','afspraak_betrokkenen','evaluaties','notities','documenten','kader_domeinen','kader_items','metingen','meting_niveaus','logboek']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('alter table public.%I force row level security', t);
  end loop;
end $$;

-- anon (niet ingelogd) krijgt nergens toegang
revoke all on all tables in schema public from anon;

-- ---------- organisaties ----------
create policy organisaties_lezen on public.organisaties for select to authenticated using (true);
create policy organisaties_beheer on public.organisaties for all to authenticated using (public.is_beheerder()) with check (public.is_beheerder());

-- ---------- profielen ----------
-- e-mailadres niet via de API leesbaar (beheerders gebruiken beheer_gebruikers())
revoke select on public.profielen from authenticated;
grant select (id, naam, rol, organisatie_id, functie, actief, created_at) on public.profielen to authenticated;
revoke update on public.profielen from authenticated;
grant update (naam, functie) on public.profielen to authenticated;

create policy profielen_lezen on public.profielen for select to authenticated using (
  id = auth.uid()
  or public.is_beheerder()
  or public.mijn_rol() = 'begeleider'
  -- betrokkenen bij hetzelfde traject zien elkaars naam en rol
  or public.deelt_traject_met(id)
);
create policy profielen_eigen_wijzigen on public.profielen for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- Beheerders beheren rol, organisatie en actief via beheer_profiel(); kolomrechten houden dat voor anderen dicht.
create or replace function public.beheer_profiel(p_id uuid, p_rol public.rol, p_organisatie_id uuid, p_actief boolean, p_naam text default null, p_functie text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_beheerder() then raise exception 'alleen beheerders'; end if;
  update public.profielen set rol = p_rol, organisatie_id = p_organisatie_id, actief = p_actief,
    naam = coalesce(p_naam, naam), functie = coalesce(p_functie, functie) where id = p_id;
end $$;

create or replace function public.beheer_gebruikers()
returns table (id uuid, naam text, email text, rol public.rol, organisatie_id uuid, functie text, actief boolean, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select id, naam, email, rol, organisatie_id, functie, actief, created_at from public.profielen
  where public.is_beheerder() order by naam
$$;
revoke all on function public.beheer_profiel(uuid, public.rol, uuid, boolean, text, text), public.beheer_gebruikers() from public, anon;
grant execute on function public.beheer_profiel(uuid, public.rol, uuid, boolean, text, text), public.beheer_gebruikers() to authenticated;

-- ---------- deelnemers ----------
create policy deelnemers_lezen on public.deelnemers for select to authenticated using (public.rol_bij(id) is not null or public.is_beheerder());
create policy deelnemers_aanmaken on public.deelnemers for insert to authenticated with check (public.mijn_rol() in ('begeleider', 'beheerder'));
create policy deelnemers_wijzigen on public.deelnemers for update to authenticated using (public.is_begeleider_van(id) or public.is_beheerder()) with check (public.is_begeleider_van(id) or public.is_beheerder());
create policy deelnemers_verwijderen on public.deelnemers for delete to authenticated using (public.is_beheerder());

-- ---------- toewijzingen ----------
create policy toewijzingen_lezen on public.toewijzingen for select to authenticated using (
  profiel_id = auth.uid() or public.is_beheerder() or public.is_begeleider_van(deelnemer_id) or deelnemer_id = public.mijn_deelnemer_id()
);
create policy toewijzingen_beheer on public.toewijzingen for all to authenticated
  using (public.is_beheerder() or public.is_begeleider_van(deelnemer_id))
  with check (public.is_beheerder() or public.is_begeleider_van(deelnemer_id));

-- ---------- doelen ----------
create policy doelen_lezen on public.doelen for select to authenticated using (
  public.is_begeleider_van(deelnemer_id)
  or deelnemer_id = public.mijn_deelnemer_id()
  or (gedeeld_werkgever and public.rol_bij(deelnemer_id) = 'werkgever')
  or (gedeeld_gemeente and public.rol_bij(deelnemer_id) = 'gemeente')
);
create policy doelen_beheer on public.doelen for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

-- ---------- opdrachten ----------
create policy bibliotheek_lezen on public.opdrachten_bibliotheek for select to authenticated using (public.mijn_rol() in ('begeleider', 'beheerder'));
create policy bibliotheek_beheer on public.opdrachten_bibliotheek for all to authenticated using (public.mijn_rol() in ('begeleider', 'beheerder')) with check (public.mijn_rol() in ('begeleider', 'beheerder'));

create policy opdrachten_lezen on public.opdrachten for select to authenticated using (public.is_begeleider_van(deelnemer_id) or deelnemer_id = public.mijn_deelnemer_id());
create policy opdrachten_beheer on public.opdrachten for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

-- deelnemer levert in via een functie: alleen antwoord en status kunnen veranderen
create or replace function public.lever_opdracht_in(p_opdracht uuid, p_antwoord text)
returns void language plpgsql security definer set search_path = public as $$
declare d uuid;
begin
  select deelnemer_id into d from public.opdrachten where id = p_opdracht;
  if d is null or d <> public.mijn_deelnemer_id() then raise exception 'geen toegang'; end if;
  if length(trim(coalesce(p_antwoord, ''))) = 0 then raise exception 'antwoord is leeg'; end if;
  update public.opdrachten set antwoord = p_antwoord, status = 'ingeleverd', ingeleverd_op = now()
  where id = p_opdracht and status = 'open';
  if not found then raise exception 'opdracht is al ingeleverd'; end if;
end $$;

-- ---------- afspraken ----------
create policy afspraken_lezen on public.afspraken for select to authenticated using (
  public.is_begeleider_van(deelnemer_id)
  or deelnemer_id = public.mijn_deelnemer_id()
  or (gedeeld_werkgever and public.rol_bij(deelnemer_id) = 'werkgever')
  or public.is_betrokkene_bij(id)
);
create policy afspraken_beheer on public.afspraken for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

create policy betrokkenen_lezen on public.afspraak_betrokkenen for select to authenticated using (exists (select 1 from public.afspraken a where a.id = afspraak_id));
create policy betrokkenen_beheer on public.afspraak_betrokkenen for all to authenticated
  using (exists (select 1 from public.afspraken a where a.id = afspraak_id and public.is_begeleider_van(a.deelnemer_id)))
  with check (exists (select 1 from public.afspraken a where a.id = afspraak_id and public.is_begeleider_van(a.deelnemer_id)));

create or replace function public.vraag_wijziging(p_afspraak uuid, p_tekst text)
returns void language plpgsql security definer set search_path = public as $$
declare d uuid;
begin
  select deelnemer_id into d from public.afspraken where id = p_afspraak;
  if d is null or d <> public.mijn_deelnemer_id() then raise exception 'geen toegang'; end if;
  update public.afspraken set status = 'wijziging_aangevraagd', wijziging_verzoek = nullif(trim(p_tekst), '')
  where id = p_afspraak and status in ('gepland', 'bevestigd');
  if not found then raise exception 'deze afspraak kan niet meer gewijzigd worden'; end if;
end $$;

-- ---------- evaluaties ----------
create policy evaluaties_lezen on public.evaluaties for select to authenticated using (
  public.is_begeleider_van(deelnemer_id)
  or deelnemer_id = public.mijn_deelnemer_id()
  or (gedeeld_werkgever and public.rol_bij(deelnemer_id) = 'werkgever')
  or (gedeeld_gemeente and public.rol_bij(deelnemer_id) = 'gemeente')
);
create policy evaluaties_beheer on public.evaluaties for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

-- ---------- notities: alleen begeleiders van de deelnemer, niemand anders ----------
create policy notities_begeleider on public.notities for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

-- ---------- documenten (metadata) ----------
create policy documenten_lezen on public.documenten for select to authenticated using (
  public.is_begeleider_van(deelnemer_id) or public.rol_bij(deelnemer_id) = any (zichtbaar_voor)
);
create policy documenten_beheer on public.documenten for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

-- ---------- competentiekader ----------
create policy kader_domeinen_lezen on public.kader_domeinen for select to authenticated using (true);
create policy kader_domeinen_beheer on public.kader_domeinen for all to authenticated using (public.is_beheerder()) with check (public.is_beheerder());
create policy kader_items_lezen on public.kader_items for select to authenticated using (true);
create policy kader_items_beheer on public.kader_items for all to authenticated using (public.is_beheerder()) with check (public.is_beheerder());

-- ---------- metingen ----------
create policy metingen_lezen on public.metingen for select to authenticated using (
  public.is_begeleider_van(deelnemer_id)
  or deelnemer_id = public.mijn_deelnemer_id()
  or (gedeeld_werkgever and public.rol_bij(deelnemer_id) = 'werkgever')
  or (gedeeld_gemeente and public.rol_bij(deelnemer_id) = 'gemeente')
);
create policy metingen_beheer on public.metingen for all to authenticated using (public.is_begeleider_van(deelnemer_id)) with check (public.is_begeleider_van(deelnemer_id));

-- niveaus per vaardigheid: begeleider en deelnemer volledig; werkgever alleen deelbare domeinen; gemeente niets (alleen samenvatting via functie)
create policy niveaus_lezen on public.meting_niveaus for select to authenticated using (
  exists (
    select 1 from public.metingen m join public.kader_items i on i.id = meting_niveaus.item_id join public.kader_domeinen k on k.id = i.domein_id
    where m.id = meting_niveaus.meting_id and (
      public.is_begeleider_van(m.deelnemer_id)
      or m.deelnemer_id = public.mijn_deelnemer_id()
      or (m.gedeeld_werkgever and k.deelbaar_werkgever and public.rol_bij(m.deelnemer_id) = 'werkgever')
    )
  )
);
create policy niveaus_beheer on public.meting_niveaus for all to authenticated
  using (exists (select 1 from public.metingen m where m.id = meting_id and public.is_begeleider_van(m.deelnemer_id)))
  with check (exists (select 1 from public.metingen m where m.id = meting_id and public.is_begeleider_van(m.deelnemer_id)));

-- Samenvatting per domein (gemiddeld niveau), voor iedereen die de meting mag zien.
-- Gemeente krijgt alleen dit; werkgever alleen deelbare domeinen.
create or replace function public.voortgang_per_domein(p_deelnemer uuid)
returns table (meting_id uuid, datum date, soort public.meting_soort, domein_id text, domein_naam text, gemiddelde numeric, aantal int, aantal_zelfstandig int)
language sql stable security definer set search_path = public as $$
  with r as (select public.rol_bij(p_deelnemer) as rol)
  select m.id, m.datum, m.soort, k.id, k.naam,
         round(avg(n.niveau)::numeric, 2), count(*)::int, count(*) filter (where n.niveau >= 3)::int
  from public.metingen m
  join public.meting_niveaus n on n.meting_id = m.id
  join public.kader_items i on i.id = n.item_id
  join public.kader_domeinen k on k.id = i.domein_id
  cross join r
  where m.deelnemer_id = p_deelnemer and r.rol is not null and (
      r.rol in ('begeleider', 'deelnemer')
      or (r.rol = 'werkgever' and m.gedeeld_werkgever and k.deelbaar_werkgever)
      or (r.rol = 'gemeente' and m.gedeeld_gemeente)
  )
  group by m.id, m.datum, m.soort, k.id, k.naam, k.volgorde
  order by m.datum, k.volgorde
$$;

revoke all on function public.lever_opdracht_in(uuid, text), public.vraag_wijziging(uuid, text), public.voortgang_per_domein(uuid) from public, anon;
grant execute on function public.lever_opdracht_in(uuid, text), public.vraag_wijziging(uuid, text), public.voortgang_per_domein(uuid) to authenticated;

-- ---------- logboek: alleen beheerders lezen; schrijven gebeurt door triggers ----------
create policy logboek_lezen on public.logboek for select to authenticated using (public.is_beheerder());
revoke insert, update, delete on public.logboek from authenticated;
