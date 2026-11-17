-- 0007 Beveiligingscontrole (17 nov 2026)
-- 1. Rol bij nieuw account komt NIET meer uit user_metadata (die kan iedereen bij aanmelden meesturen).
--    Alleen app_metadata (alleen te zetten met de service-sleutel, dus door ons) telt.
--    Accounts zonder rol in app_metadata starten als inactieve deelnemer; een beheerder activeert ze.
create or replace function public.tg_nieuw_account() returns trigger
language plpgsql security definer set search_path = public as $$
declare r public.rol; heeft_rol boolean := (new.raw_app_meta_data ? 'rol');
begin
  begin r := coalesce(new.raw_app_meta_data->>'rol', 'deelnemer')::public.rol; exception when others then r := 'deelnemer'; heeft_rol := false; end;
  insert into public.profielen (id, naam, email, rol, actief)
  values (new.id, coalesce(new.raw_user_meta_data->>'naam', split_part(coalesce(new.email, ''), '@', 1)), new.email, r, heeft_rol)
  on conflict (id) do nothing;
  return new;
end $$;

-- 2. Een dossier geeft alleen 'deelnemer'-toegang aan een account met de rol deelnemer.
create or replace function public.rol_bij(d uuid) returns public.rol
language sql stable security definer set search_path = public as $$
  select case
    when exists (select 1 from public.deelnemers x join public.profielen p on p.id = x.profiel_id
                 where x.id = d and p.id = auth.uid() and p.actief and p.rol = 'deelnemer') then 'deelnemer'::public.rol
    else (select t.rol from public.toewijzingen t join public.profielen p on p.id = t.profiel_id
          where t.deelnemer_id = d and t.profiel_id = auth.uid() and p.actief and p.rol = t.rol)
  end
$$;
create or replace function public.mijn_deelnemer_id() returns uuid
language sql stable security definer set search_path = public as $$
  select d.id from public.deelnemers d join public.profielen p on p.id = d.profiel_id
  where p.id = auth.uid() and p.actief and p.rol = 'deelnemer'
$$;

-- 3. Overbodige rechten weg (extra slot op de deur; RLS weigerde dit al).
revoke insert on public.profielen from authenticated, anon;
revoke update (id, created_at, updated_at) on public.deelnemers from authenticated;
revoke insert (id, created_at, updated_at) on public.deelnemers from authenticated;

-- 4. Organisaties: niet iedereen ziet alle werkgevers en gemeenten.
drop policy if exists organisaties_lezen on public.organisaties;
create policy organisaties_lezen on public.organisaties for select to authenticated using (
  public.mijn_rol() in ('begeleider', 'beheerder')
  or id = (select p.organisatie_id from public.profielen p where p.id = (select auth.uid()))
);

-- 5. Prestaties: auth.uid() één keer per query, indexen op verwijzingen.
drop policy if exists profielen_lezen on public.profielen;
create policy profielen_lezen on public.profielen for select to authenticated using (
  id = (select auth.uid()) or public.is_beheerder() or public.mijn_rol() = 'begeleider' or public.deelt_traject_met(id));
drop policy if exists profielen_eigen_wijzigen on public.profielen;
create policy profielen_eigen_wijzigen on public.profielen for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
drop policy if exists toewijzingen_lezen on public.toewijzingen;
create policy toewijzingen_lezen on public.toewijzingen for select to authenticated using (
  profiel_id = (select auth.uid()) or public.is_beheerder() or public.is_begeleider_van(deelnemer_id) or deelnemer_id = public.mijn_deelnemer_id());

create index if not exists afspraak_betrokkenen_profiel_idx on public.afspraak_betrokkenen (profiel_id);
create index if not exists afspraken_aangemaakt_door_idx on public.afspraken (aangemaakt_door);
create index if not exists afspraken_opdracht_idx on public.afspraken (opdracht_id);
create index if not exists deelnemers_gemeente_org_idx on public.deelnemers (gemeente_org_id);
create index if not exists deelnemers_werkgever_org_idx on public.deelnemers (werkgever_org_id);
create index if not exists documenten_geupload_door_idx on public.documenten (geupload_door);
create index if not exists doelen_aangemaakt_door_idx on public.doelen (aangemaakt_door);
create index if not exists evaluaties_auteur_idx on public.evaluaties (auteur_id);
create index if not exists kader_items_domein_idx on public.kader_items (domein_id);
create index if not exists meting_niveaus_item_idx on public.meting_niveaus (item_id);
create index if not exists metingen_auteur_idx on public.metingen (auteur_id);
create index if not exists notities_auteur_idx on public.notities (auteur_id);
create index if not exists opdrachten_beoordeeld_door_idx on public.opdrachten (beoordeeld_door);
create index if not exists opdrachten_bibliotheek_idx on public.opdrachten (bibliotheek_id);
create index if not exists opdrachten_toegewezen_door_idx on public.opdrachten (toegewezen_door);
create index if not exists profielen_organisatie_idx on public.profielen (organisatie_id);
