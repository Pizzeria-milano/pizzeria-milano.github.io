-- ============================================================
-- Storage-Bucket fuer die Speisen-Bilder
--
-- Einmalig im SQL Editor des Supabase-Projekts ausfuehren, BEVOR in
-- der Verwaltung auf "Jetzt verschieben" geklickt wird.
--
-- Hintergrund: Die Bilder lagen als Base64-Data-URL in der Spalte
-- pizzeria_menu.image. Dadurch gingen sie bei jeder Menue-Abfrage
-- komplett ueber die API und konnten vom Browser nie zwischen-
-- gespeichert werden. Als Storage-Dateien liefert sie das CDN aus und
-- der Browser behaelt sie ein Jahr; die Spalte image haelt danach nur
-- noch die URL.
-- ============================================================

-- 1) Bucket anlegen (oeffentlich lesbar, damit <img src="..."> ohne
--    Anmeldung funktioniert). Laeuft auch durch, wenn er schon da ist.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('menu-bilder', 'menu-bilder', true, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public             = true,
      file_size_limit    = 2097152,
      allowed_mime_types = array['image/jpeg','image/png','image/webp'];

-- 2) Zugriffsregeln.
--
--    ACHTUNG, bitte bewusst entscheiden: Die App meldet sich bei
--    Supabase nicht an - sie kennt nur den oeffentlichen Key und
--    prueft das Verwaltungs-Passwort im Browser. Damit das Hochladen
--    aus der Verwaltung funktioniert, muss Schreiben fuer die Rolle
--    "anon" erlaubt sein. Wer den Bucket-Namen und den oeffentlichen
--    Key kennt, kann dann theoretisch Bilder hochladen oder ersetzen.
--    Fuer eine private Spass-Seite vertretbar; fuer mehr waere echte
--    Supabase-Authentifizierung noetig.
--
--    Die Groesse ist auf 2 MB je Datei begrenzt, erlaubt sind nur
--    Bildformate - das begrenzt den moeglichen Schaden.

drop policy if exists "menu-bilder oeffentlich lesen"   on storage.objects;
drop policy if exists "menu-bilder schreiben"           on storage.objects;
drop policy if exists "menu-bilder aktualisieren"       on storage.objects;
drop policy if exists "menu-bilder loeschen"            on storage.objects;

create policy "menu-bilder oeffentlich lesen"
  on storage.objects for select
  using (bucket_id = 'menu-bilder');

create policy "menu-bilder schreiben"
  on storage.objects for insert
  with check (bucket_id = 'menu-bilder');

create policy "menu-bilder aktualisieren"
  on storage.objects for update
  using (bucket_id = 'menu-bilder')
  with check (bucket_id = 'menu-bilder');

create policy "menu-bilder loeschen"
  on storage.objects for delete
  using (bucket_id = 'menu-bilder');

-- 3) Kontrolle: zeigt den Bucket und die gesetzten Regeln.
select id, name, public, file_size_limit from storage.buckets where id = 'menu-bilder';
select policyname, cmd from pg_policies
where schemaname = 'storage' and tablename = 'objects'
  and policyname like 'menu-bilder%'
order by policyname;
