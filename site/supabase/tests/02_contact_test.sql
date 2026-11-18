-- Contactformulier: anon mag toevoegen, niet lezen; beheerder mag lezen.
begin;
create temp table r (wat text, ok boolean) on commit drop;
grant all on r to anon, authenticated;
set role anon;
insert into public.contactaanvragen (type, naam, email, toelichting) values ('werkgever', 'Test', 'a@b.nl', 'hallo');
insert into r select 'anon kan toevoegen', true;
do $$ begin perform 1 from public.contactaanvragen; insert into r values ('anon kan NIET lezen', false); exception when insufficient_privilege then insert into r values ('anon kan NIET lezen', true); end $$;
do $$ begin insert into public.contactaanvragen (type, naam) values ('anders', 'Zonder contact'); insert into r values ('zonder mail/tel geweigerd', false); exception when check_violation then insert into r values ('zonder mail/tel geweigerd', true); end $$;
do $$ begin insert into public.contactaanvragen (type, naam, email, status) values ('anders', 'X', 'x@y.nl', 'afgehandeld'); insert into r values ('status zetten geweigerd', false); exception when insufficient_privilege then insert into r values ('status zetten geweigerd', true); end $$;
reset role;
select wat, ok from r;
rollback;
