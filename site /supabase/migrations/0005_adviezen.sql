-- Opvolging van de Supabase security-adviseur
create or replace function public.tg_set_updated_at() returns trigger
language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end $$;

-- triggerfuncties zijn niet bedoeld als API
revoke all on function public.tg_logboek(), public.tg_nieuw_account(), public.tg_set_updated_at() from public, anon, authenticated;
