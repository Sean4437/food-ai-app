-- Add production subscription fields to profiles.
-- Safe to run multiple times.

alter table if exists public.profiles
  add column if not exists plan_id text;

alter table if exists public.profiles
  add column if not exists subscription_expires_at timestamptz;

do $$
begin
  if to_regclass('public.profiles') is null then
    return;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_plan_id_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_plan_id_check
      check (plan_id is null or plan_id in ('free', 'pro', 'plus'));
  end if;
end $$;

create index if not exists idx_profiles_plan_id
  on public.profiles (plan_id);

create index if not exists idx_profiles_subscription_expires_at
  on public.profiles (subscription_expires_at);

