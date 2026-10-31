-- SHARIKOTI MATA FOUNDATION RecordBook cloud storage
-- SAFE VERSION: creates a separate table; does not drop or modify existing tables/policies.
-- Run this in Supabase SQL Editor. Access is restricted to each signed-in user’s own row.

create table if not exists public.smf_recordbook_cloud (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  record_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.smf_recordbook_cloud enable row level security;

grant select, insert, update, delete
on public.smf_recordbook_cloud to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'smf_recordbook_cloud'
      and policyname = 'smf_cloud_select_own'
  ) then
    create policy smf_cloud_select_own
      on public.smf_recordbook_cloud
      for select to authenticated
      using (owner_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'smf_recordbook_cloud'
      and policyname = 'smf_cloud_insert_own'
  ) then
    create policy smf_cloud_insert_own
      on public.smf_recordbook_cloud
      for insert to authenticated
      with check (owner_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'smf_recordbook_cloud'
      and policyname = 'smf_cloud_update_own'
  ) then
    create policy smf_cloud_update_own
      on public.smf_recordbook_cloud
      for update to authenticated
      using (owner_id = auth.uid())
      with check (owner_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'smf_recordbook_cloud'
      and policyname = 'smf_cloud_delete_own'
  ) then
    create policy smf_cloud_delete_own
      on public.smf_recordbook_cloud
      for delete to authenticated
      using (owner_id = auth.uid());
  end if;
end $$;

-- Refresh the API schema cache so the app can see the new table.
notify pgrst, 'reload schema';
