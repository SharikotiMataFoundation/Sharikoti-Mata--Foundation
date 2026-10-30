-- SHARIKOTI MATA FOUNDATION RecordBook cloud setup
-- Run once in Supabase SQL Editor. Uses authenticated Director access only.
-- The public publishable key belongs in the app; never use service_role here.

create unique index if not exists user_access_auth_user_id_uidx
  on public.user_access (auth_user_id);

insert into public.user_access (auth_user_id, role)
values ('c351417f-a815-4fff-8b13-1ae4707233e3'::uuid, 'Director')
on conflict (auth_user_id)
do update set role = excluded.role;

create unique index if not exists recordbook_data_record_type_uidx
  on public.recordbook_data (record_type);

alter table public.user_access enable row level security;
alter table public.recordbook_data enable row level security;

-- Remove old policies on these two tables so no permissive legacy policy
-- accidentally grants broader access.
do $$
declare p record;
begin
  for p in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('user_access', 'recordbook_data')
  loop
    execute format('drop policy if exists %I on %I.%I',
      p.policyname, p.schemaname, p.tablename);
  end loop;
end $$;

create policy "user_access_read_own"
on public.user_access
for select
to authenticated
using (auth_user_id = auth.uid());

create policy "recordbook_director_select"
on public.recordbook_data
for select
to authenticated
using (
  exists (
    select 1 from public.user_access ua
    where ua.auth_user_id = auth.uid()
      and ua.role = 'Director'
  )
);

create policy "recordbook_director_insert"
on public.recordbook_data
for insert
to authenticated
with check (
  exists (
    select 1 from public.user_access ua
    where ua.auth_user_id = auth.uid()
      and ua.role = 'Director'
  )
);

create policy "recordbook_director_update"
on public.recordbook_data
for update
to authenticated
using (
  exists (
    select 1 from public.user_access ua
    where ua.auth_user_id = auth.uid()
      and ua.role = 'Director'
  )
)
with check (
  exists (
    select 1 from public.user_access ua
    where ua.auth_user_id = auth.uid()
      and ua.role = 'Director'
  )
);

create policy "recordbook_director_delete"
on public.recordbook_data
for delete
to authenticated
using (
  exists (
    select 1 from public.user_access ua
    where ua.auth_user_id = auth.uid()
      and ua.role = 'Director'
  )
);
