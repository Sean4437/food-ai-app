-- Core database baseline for food-ai-app.
-- Safe to run multiple times in Supabase SQL Editor.
--
-- Includes:
-- - profiles (trial metadata used by backend)
-- - meals/custom_foods/user_settings/sync_meta (frontend sync tables)
-- - storage bucket bootstrap + per-user RLS policies
--
-- Catalog tables are managed separately:
-- - food_catalog_schema.sql
-- - food_catalog_public_expansion.sql
-- - food_catalog_hardening.sql

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  trial_start timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meals (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  time timestamptz not null,
  type text not null default 'other',
  filename text not null default 'photo.jpg',
  portion_percent integer not null default 100 check (portion_percent >= 0 and portion_percent <= 300),
  override_calorie_range text,
  container_type text,
  container_size text,
  meal_id text,
  note text,
  override_food_name text,
  image_hash text,
  image_path text,
  label_image_path text,
  result_json jsonb,
  label_json jsonb,
  last_analyzed_note text,
  last_analyzed_food_name text,
  last_analyzed_at text,
  last_analyze_reason text,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.custom_foods (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  summary text not null default '',
  calorie_range text not null default '',
  suggestion text not null default '',
  macros jsonb not null default '{}'::jsonb,
  image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  profile_json jsonb not null default '{}'::jsonb,
  overrides_json jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.sync_meta (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_sync_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_trial_start
  on public.profiles (trial_start);

create index if not exists idx_meals_user_time
  on public.meals (user_id, time desc);

create index if not exists idx_meals_user_updated_at
  on public.meals (user_id, updated_at desc);

create index if not exists idx_meals_user_deleted_at
  on public.meals (user_id, deleted_at desc);

create index if not exists idx_meals_user_meal_id
  on public.meals (user_id, meal_id);

create index if not exists idx_custom_foods_user_updated_at
  on public.custom_foods (user_id, updated_at desc);

create index if not exists idx_custom_foods_user_deleted_at
  on public.custom_foods (user_id, deleted_at desc);

alter table public.profiles enable row level security;
alter table public.meals enable row level security;
alter table public.custom_foods enable row level security;
alter table public.user_settings enable row level security;
alter table public.sync_meta enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles
  for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "profiles_upsert_own" on public.profiles;
create policy "profiles_upsert_own"
  on public.profiles
  for all
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists "meals_select_own" on public.meals;
create policy "meals_select_own"
  on public.meals
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "meals_upsert_own" on public.meals;
create policy "meals_upsert_own"
  on public.meals
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "custom_foods_select_own" on public.custom_foods;
create policy "custom_foods_select_own"
  on public.custom_foods
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "custom_foods_upsert_own" on public.custom_foods;
create policy "custom_foods_upsert_own"
  on public.custom_foods
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "user_settings_select_own" on public.user_settings;
create policy "user_settings_select_own"
  on public.user_settings
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_settings_upsert_own" on public.user_settings;
create policy "user_settings_upsert_own"
  on public.user_settings
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "sync_meta_select_own" on public.sync_meta;
create policy "sync_meta_select_own"
  on public.sync_meta
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "sync_meta_upsert_own" on public.sync_meta;
create policy "sync_meta_upsert_own"
  on public.sync_meta
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('meal-images', 'meal-images', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('label-images', 'label-images', false)
on conflict (id) do nothing;

drop policy if exists "meal_images_select_own" on storage.objects;
create policy "meal_images_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'meal-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "meal_images_insert_own" on storage.objects;
create policy "meal_images_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'meal-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "meal_images_update_own" on storage.objects;
create policy "meal_images_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'meal-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'meal-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "meal_images_delete_own" on storage.objects;
create policy "meal_images_delete_own"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'meal-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "label_images_select_own" on storage.objects;
create policy "label_images_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'label-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "label_images_insert_own" on storage.objects;
create policy "label_images_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'label-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "label_images_update_own" on storage.objects;
create policy "label_images_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'label-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'label-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "label_images_delete_own" on storage.objects;
create policy "label_images_delete_own"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'label-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
