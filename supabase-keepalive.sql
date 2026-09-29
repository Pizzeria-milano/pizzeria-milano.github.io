-- Heartbeat gegen automatisches Pausieren (Free-Plan).
-- Angewendet am 2026-09-29 auf qancstbmabexmmimkxcp (Migration keepalive_heartbeat).
-- Der GitHub-Workflow .github/workflows/supabase-keepalive.yml ruft keepalive_ping()
-- mehrmals täglich auf; das erzeugt echte Schreibaktivität.
create table if not exists public.keepalive (
  id smallint primary key default 1 check (id = 1),
  last_ping timestamptz not null default now(),
  ping_count bigint not null default 0
);
alter table public.keepalive enable row level security;
-- keine Policies: direkter Zugriff über die API bleibt gesperrt, nur die Funktion schreibt.
insert into public.keepalive (id) values (1) on conflict do nothing;

create or replace function public.keepalive_ping()
returns json
language sql
security definer
set search_path = ''
as $$
  update public.keepalive
     set last_ping = now(), ping_count = ping_count + 1
   where id = 1
  returning json_build_object('last_ping', last_ping, 'ping_count', ping_count);
$$;

revoke all on function public.keepalive_ping() from public;
grant execute on function public.keepalive_ping() to anon, authenticated;
