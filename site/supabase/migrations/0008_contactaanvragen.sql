-- 0008 Contactformulier van de website (18 nov 2026)
-- Bezoekers (anon) mogen alleen een aanvraag TOEVOEGEN; niemand buiten de beheerder kan aanvragen lezen.
create table if not exists public.contactaanvragen (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  type text not null check (type in ('werkgever', 'gemeente', 'anders')),
  naam text not null check (length(trim(naam)) between 1 and 120),
  organisatie text check (organisatie is null or length(organisatie) <= 160),
  email text check (email is null or (length(email) <= 200 and email ~ '^[^\s@]+@[^\s@]+\.[^\s@]{2,}$')),
  telefoon text check (telefoon is null or length(telefoon) <= 40),
  toelichting text check (toelichting is null or length(toelichting) <= 2000),
  status text not null default 'nieuw' check (status in ('nieuw', 'in behandeling', 'afgehandeld')),
  constraint contact_bereikbaar check (coalesce(email, '') <> '' or coalesce(telefoon, '') <> '')
);
alter table public.contactaanvragen enable row level security;

revoke all on public.contactaanvragen from anon, authenticated;
grant insert (type, naam, organisatie, email, telefoon, toelichting) on public.contactaanvragen to anon, authenticated;
grant select, update (status), delete on public.contactaanvragen to authenticated;

create policy contact_insturen on public.contactaanvragen for insert to anon, authenticated
  with check (status = 'nieuw');
create policy contact_beheer_lezen on public.contactaanvragen for select to authenticated using (public.is_beheerder());
create policy contact_beheer_wijzigen on public.contactaanvragen for update to authenticated using (public.is_beheerder()) with check (public.is_beheerder());
create policy contact_beheer_verwijderen on public.contactaanvragen for delete to authenticated using (public.is_beheerder());

-- Rem tegen spam/overbelasting: maximaal 30 aanvragen per 10 minuten in totaal.
create or replace function public.tg_contact_rem() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.contactaanvragen where created_at > now() - interval '10 minutes') >= 30 then
    raise exception 'Te veel aanvragen op dit moment. Probeer het later opnieuw of bel ons.';
  end if;
  new.status := 'nieuw';
  new.created_at := now();
  return new;
end $$;
revoke execute on function public.tg_contact_rem() from public, anon, authenticated;
create trigger contact_rem before insert on public.contactaanvragen for each row execute function public.tg_contact_rem();
create index if not exists contactaanvragen_created_idx on public.contactaanvragen (created_at);

-- Opschonen: aanvragen ouder dan 12 maanden verwijderen (aan te roepen door beheer of een geplande taak).
create or replace function public.ruim_contactaanvragen_op() returns integer
language sql security definer set search_path = public as $$
  with weg as (delete from public.contactaanvragen where created_at < now() - interval '12 months' returning 1)
  select count(*)::int from weg
$$;
revoke execute on function public.ruim_contactaanvragen_op() from public, anon, authenticated;
