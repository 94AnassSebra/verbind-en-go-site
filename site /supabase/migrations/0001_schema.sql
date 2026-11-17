-- =====================================================================
-- Verbind & GO — portaal: datamodel (migratie 0001)
-- Uitgangspunten:
--  * Alleen gegevens die nodig zijn voor begeleiding. Geen BSN, geen
--    medische gegevens, geen reden van uitkering.
--  * Interne notities zijn gescheiden van gedeelde informatie; per record
--    staat expliciet of het met werkgever en/of gemeente gedeeld is.
--  * Technisch beheer (rol beheerder) ziet gebruikers en toewijzingen,
--    maar géén dossierinhoud (notities, evaluaties, metingen, documenten).
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- enums ----------
create type public.rol as enum ('deelnemer', 'begeleider', 'werkgever', 'gemeente', 'beheerder');
create type public.organisatie_soort as enum ('verbind', 'werkgever', 'gemeente');
create type public.traject_status as enum ('intake', 'actief', 'afgerond', 'gestopt');
create type public.doel_status as enum ('open', 'in_uitvoering', 'behaald', 'gestopt');
create type public.afspraak_status as enum ('gepland', 'wijziging_aangevraagd', 'bevestigd', 'afgerond', 'geannuleerd');
create type public.opdracht_status as enum ('open', 'ingeleverd', 'beoordeeld');
create type public.beheersing as enum ('nog_niet', 'met_hulp', 'zelfstandig', 'zeker');
create type public.meting_soort as enum ('nulmeting', 'tussenmeting', 'eindmeting');

-- ---------- organisaties en gebruikers ----------
create table public.organisaties (
  id uuid primary key default gen_random_uuid(),
  naam text not null,
  soort public.organisatie_soort not null,
  plaats text,
  actief boolean not null default true,
  created_at timestamptz not null default now()
);

-- Eén profiel per inlogaccount (auth.users). Rol en organisatie worden door
-- een beheerder gezet; een nieuw account begint zonder toewijzingen en ziet niets.
create table public.profielen (
  id uuid primary key references auth.users (id) on delete cascade,
  naam text not null,
  email text,
  rol public.rol not null default 'deelnemer',
  organisatie_id uuid references public.organisaties (id) on delete set null,
  functie text,
  actief boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------- deelnemers en trajecten ----------
create table public.deelnemers (
  id uuid primary key default gen_random_uuid(),
  profiel_id uuid unique references public.profielen (id) on delete set null, -- account van de deelnemer (optioneel)
  naam text not null,
  fase text,                      -- vrije tekst, bijv. 'Starten op het werk'
  focus text,                     -- bijv. 'Werktaal en vaktaal logistiek'
  functie_werkplek text,          -- bijv. 'Orderpicker (proefplaatsing)'
  status public.traject_status not null default 'intake',
  startdatum date,
  werkgever_org_id uuid references public.organisaties (id) on delete set null,
  gemeente_org_id uuid references public.organisaties (id) on delete set null,
  domeinen text[] not null default '{}', -- afgesproken domeinen uit het kader
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Wie is bij welke deelnemer betrokken. Dit is de basis van alle toegang.
create table public.toewijzingen (
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  profiel_id uuid not null references public.profielen (id) on delete cascade,
  rol public.rol not null check (rol in ('begeleider', 'werkgever', 'gemeente')),
  hoofd boolean not null default false, -- verantwoordelijke begeleider
  created_at timestamptz not null default now(),
  primary key (deelnemer_id, profiel_id)
);
create index toewijzingen_profiel_idx on public.toewijzingen (profiel_id);

create table public.doelen (
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  titel text not null,
  toelichting text,
  status public.doel_status not null default 'open',
  gedeeld_werkgever boolean not null default false,
  gedeeld_gemeente boolean not null default false,
  aangemaakt_door uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index doelen_deelnemer_idx on public.doelen (deelnemer_id);

-- ---------- leeromgeving ----------
create table public.opdrachten_bibliotheek (
  id uuid primary key default gen_random_uuid(),
  titel text not null,
  soort text not null,            -- 'Werktaal', 'Vaktaal', 'Digitaal', 'Werknemersvaardigheden'
  duur_minuten int,
  instructie text not null,
  actief boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.opdrachten (
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  bibliotheek_id uuid references public.opdrachten_bibliotheek (id) on delete set null,
  titel text not null,
  soort text,
  instructie text not null,
  status public.opdracht_status not null default 'open',
  antwoord text,
  ingeleverd_op timestamptz,
  feedback text,
  beheersing public.beheersing,
  beoordeeld_door uuid references public.profielen (id) on delete set null,
  beoordeeld_op timestamptz,
  toegewezen_door uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index opdrachten_deelnemer_idx on public.opdrachten (deelnemer_id);

-- ---------- agenda ----------
create table public.afspraken (
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  titel text not null,
  start timestamptz not null,
  einde timestamptz,
  locatie text,
  online boolean not null default false,
  status public.afspraak_status not null default 'gepland',
  toelichting text,
  wijziging_verzoek text,          -- tekst van de deelnemer bij 'wijziging_aangevraagd'
  gedeeld_werkgever boolean not null default false,
  opdracht_id uuid references public.opdrachten (id) on delete set null,
  aangemaakt_door uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index afspraken_deelnemer_start_idx on public.afspraken (deelnemer_id, start);

create table public.afspraak_betrokkenen (
  afspraak_id uuid not null references public.afspraken (id) on delete cascade,
  profiel_id uuid not null references public.profielen (id) on delete cascade,
  primary key (afspraak_id, profiel_id)
);

-- ---------- voortgang: evaluaties en interne notities ----------
create table public.evaluaties (
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  datum date not null default current_date,
  soort text,                      -- bijv. 'Werkplekbezoek', 'Driegesprek'
  tekst text not null,
  gedeeld_werkgever boolean not null default false,
  gedeeld_gemeente boolean not null default false,
  auteur_id uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index evaluaties_deelnemer_idx on public.evaluaties (deelnemer_id);

create table public.notities (          -- intern; nooit gedeeld, nooit zichtbaar voor beheerder
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  tekst text not null,
  auteur_id uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index notities_deelnemer_idx on public.notities (deelnemer_id);

-- ---------- documenten (metadata; bestanden in Storage-bucket 'documenten') ----------
create table public.documenten (
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  titel text not null,
  soort text,                      -- 'Trajectplan', 'Evaluatieverslag', ...
  storage_pad text not null,       -- pad in bucket 'documenten': <deelnemer_id>/<bestand>
  zichtbaar_voor public.rol[] not null default '{}', -- extra rollen naast begeleider: deelnemer/werkgever/gemeente
  geupload_door uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now()
);
create index documenten_deelnemer_idx on public.documenten (deelnemer_id);

-- ---------- competentiekader en metingen ----------
create table public.kader_domeinen (
  id text primary key,             -- 'werktaal', 'vaktaal', 'digitaal', 'werk', 'samen'
  naam text not null,
  kort text not null,
  kleur text not null,
  uitleg text,
  deelbaar_werkgever boolean not null default false, -- taalniveaus niet; werk/digitaal/samen wel
  volgorde int not null default 0,
  actief boolean not null default true
);

create table public.kader_items (
  id text primary key,             -- 'wt1', 'dg2', ...
  domein_id text not null references public.kader_domeinen (id) on delete cascade,
  naam text not null,
  uitleg text,
  volgorde int not null default 0,
  actief boolean not null default true
);

create table public.metingen (
  id uuid primary key default gen_random_uuid(),
  deelnemer_id uuid not null references public.deelnemers (id) on delete cascade,
  datum date not null default current_date,
  soort public.meting_soort not null,
  toelichting text,
  gedeeld_werkgever boolean not null default false,
  gedeeld_gemeente boolean not null default false,
  auteur_id uuid references public.profielen (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index metingen_deelnemer_datum_idx on public.metingen (deelnemer_id, datum);

create table public.meting_niveaus (
  meting_id uuid not null references public.metingen (id) on delete cascade,
  item_id text not null references public.kader_items (id) on delete cascade,
  niveau smallint not null check (niveau between 1 and 4), -- 1 nog niet · 2 met hulp · 3 zelfstandig · 4 zeker
  primary key (meting_id, item_id)
);

-- ---------- logboek van wijzigingen ----------
create table public.logboek (
  id bigint generated always as identity primary key,
  tijdstip timestamptz not null default now(),
  profiel_id uuid,                 -- wie (auth.uid()), null bij systeem
  actie text not null,             -- INSERT / UPDATE / DELETE
  tabel text not null,
  record_id text,
  deelnemer_id uuid,
  details jsonb
);
create index logboek_tijdstip_idx on public.logboek (tijdstip desc);
create index logboek_deelnemer_idx on public.logboek (deelnemer_id);

-- ---------- triggers: updated_at, logboek, profiel bij nieuw account ----------
create or replace function public.tg_set_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

do $$
declare t text;
begin
  foreach t in array array['profielen','deelnemers','doelen','opdrachten','afspraken','evaluaties','notities','metingen']
  loop
    execute format('create trigger %I_updated_at before update on public.%I for each row execute function public.tg_set_updated_at()', t, t);
  end loop;
end $$;

create or replace function public.tg_logboek() returns trigger
language plpgsql security definer set search_path = public as $$
declare rid text; did uuid; det jsonb;
begin
  if tg_op = 'DELETE' then
    rid := coalesce(to_jsonb(old)->>'id', (to_jsonb(old)->>'deelnemer_id') || '/' || coalesce(to_jsonb(old)->>'profiel_id', to_jsonb(old)->>'item_id', ''));
    did := nullif(to_jsonb(old)->>'deelnemer_id', '')::uuid;
    det := jsonb_build_object('oud', to_jsonb(old) - 'tekst' - 'antwoord' - 'feedback' - 'toelichting');
  else
    rid := coalesce(to_jsonb(new)->>'id', (to_jsonb(new)->>'deelnemer_id') || '/' || coalesce(to_jsonb(new)->>'profiel_id', to_jsonb(new)->>'item_id', ''));
    did := nullif(to_jsonb(new)->>'deelnemer_id', '')::uuid;
    -- geen vrije tekst in het logboek; alleen welke velden veranderden
    if tg_op = 'UPDATE' then
      select jsonb_object_agg(key, value) into det from jsonb_each(to_jsonb(new)) n where n.value is distinct from (to_jsonb(old)->n.key) and n.key not in ('tekst','antwoord','feedback','toelichting','wijziging_verzoek','updated_at');
    else
      det := jsonb_build_object('velden', (select jsonb_agg(key) from jsonb_object_keys(to_jsonb(new)) key));
    end if;
  end if;
  if tg_table_name = 'deelnemers' then did := coalesce(did, (case when tg_op = 'DELETE' then old.id else new.id end)); end if;
  insert into public.logboek (profiel_id, actie, tabel, record_id, deelnemer_id, details)
  values (auth.uid(), tg_op, tg_table_name, rid, did, det);
  return null;
end $$;

do $$
declare t text;
begin
  foreach t in array array['profielen','deelnemers','toewijzingen','doelen','opdrachten','afspraken','evaluaties','notities','documenten','metingen']
  loop
    execute format('create trigger %I_logboek after insert or update or delete on public.%I for each row execute function public.tg_logboek()', t, t);
  end loop;
end $$;

-- Nieuw inlogaccount -> profiel. Rol komt uit de uitnodiging (user_metadata.rol),
-- anders 'deelnemer'. Zonder toewijzing ziet een account niets.
create or replace function public.tg_nieuw_account() returns trigger
language plpgsql security definer set search_path = public as $$
declare r public.rol;
begin
  begin r := coalesce(new.raw_user_meta_data->>'rol', 'deelnemer')::public.rol; exception when others then r := 'deelnemer'; end;
  insert into public.profielen (id, naam, email, rol)
  values (new.id, coalesce(new.raw_user_meta_data->>'naam', split_part(coalesce(new.email, ''), '@', 1)), new.email, r)
  on conflict (id) do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.tg_nieuw_account();
