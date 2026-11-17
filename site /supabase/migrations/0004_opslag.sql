-- Bestandsopslag voor documenten (Supabase Storage). Pad: <deelnemer_id>/<bestandsnaam>.
-- Toegang volgt de tabel public.documenten: wie het documentrecord mag zien, mag het bestand ophalen.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('documenten', 'documenten', false, 10485760, array['application/pdf','image/png','image/jpeg','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do nothing;

create policy documenten_bestand_lezen on storage.objects for select to authenticated
  using (bucket_id = 'documenten' and exists (select 1 from public.documenten d where d.storage_pad = name));
create policy documenten_bestand_uploaden on storage.objects for insert to authenticated
  with check (bucket_id = 'documenten' and public.is_begeleider_van((split_part(name, '/', 1))::uuid));
create policy documenten_bestand_verwijderen on storage.objects for delete to authenticated
  using (bucket_id = 'documenten' and public.is_begeleider_van((split_part(name, '/', 1))::uuid));
