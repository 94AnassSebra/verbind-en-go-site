-- Achtergrond van een deelnemer (alleen wat nodig is voor begeleiding; geen BSN, geen medische gegevens).
-- Zichtbaar voor begeleider en deelnemer; werkgever en gemeente zien deze kolommen niet (kolomrecht).
alter table public.deelnemers
  add column situatie text,
  add column taal text,
  add column opleiding text,
  add column werkervaring text,
  add column interesses text,
  add column ondersteuning text,
  add column opdrachtgever text;

revoke select on public.deelnemers from authenticated;
grant select (id, profiel_id, naam, fase, focus, functie_werkplek, status, startdatum, werkgever_org_id, gemeente_org_id, domeinen, created_at, updated_at) on public.deelnemers to authenticated;
grant insert, update on public.deelnemers to authenticated;

create or replace function public.deelnemer_achtergrond(p_deelnemer uuid)
returns table (situatie text, taal text, opleiding text, werkervaring text, interesses text, ondersteuning text, opdrachtgever text)
language sql stable security definer set search_path = public as $$
  select situatie, taal, opleiding, werkervaring, interesses, ondersteuning, opdrachtgever
  from public.deelnemers d
  where d.id = p_deelnemer and public.rol_bij(p_deelnemer) in ('begeleider', 'deelnemer')
$$;
revoke all on function public.deelnemer_achtergrond(uuid) from public, anon;
grant execute on function public.deelnemer_achtergrond(uuid) to authenticated;
