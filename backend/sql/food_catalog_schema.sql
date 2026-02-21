-- Food catalog tables for name-first logging flow.
-- Apply in Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.food_catalog (
  id uuid primary key default gen_random_uuid(),
  food_name text not null,
  canonical_name text,
  calorie_range text not null default '',
  macros jsonb not null default '{}'::jsonb,
  food_items jsonb not null default '[]'::jsonb,
  judgement_tags jsonb not null default '[]'::jsonb,
  dish_summary text not null default '',
  suggestion text not null default '',
  kcal_100g numeric,
  protein_100g numeric,
  carbs_100g numeric,
  fat_100g numeric,
  sodium_mg_100g numeric,
  source text not null default 'catalog',
  verified_level integer not null default 0,
  is_food boolean not null default true,
  is_beverage boolean not null default false,
  beverage_base_ml numeric,
  beverage_full_sugar_carbs numeric,
  beverage_default_sugar_ratio numeric,
  beverage_sugar_adjustable boolean,
  beverage_profile jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.food_catalog
  add column if not exists food_items jsonb not null default '[]'::jsonb;

alter table public.food_catalog
  add column if not exists judgement_tags jsonb not null default '[]'::jsonb;

alter table public.food_catalog
  add column if not exists beverage_base_ml numeric;

alter table public.food_catalog
  add column if not exists beverage_full_sugar_carbs numeric;

alter table public.food_catalog
  add column if not exists beverage_default_sugar_ratio numeric;

alter table public.food_catalog
  add column if not exists beverage_sugar_adjustable boolean;

alter table public.food_catalog
  add column if not exists beverage_profile jsonb not null default '{}'::jsonb;

create index if not exists idx_food_catalog_food_name
  on public.food_catalog (food_name);

create index if not exists idx_food_catalog_canonical_name
  on public.food_catalog (canonical_name);

create table if not exists public.food_aliases (
  id bigserial primary key,
  food_id uuid not null references public.food_catalog(id) on delete cascade,
  lang text,
  alias text not null,
  alias_norm text generated always as (lower(trim(alias))) stored,
  created_at timestamptz not null default now(),
  unique (food_id, lang, alias_norm)
);

create index if not exists idx_food_aliases_alias_norm
  on public.food_aliases (alias_norm);

create index if not exists idx_food_aliases_food_id
  on public.food_aliases (food_id);

alter table public.food_catalog enable row level security;
alter table public.food_aliases enable row level security;

drop policy if exists "food_catalog_read_authenticated" on public.food_catalog;
create policy "food_catalog_read_authenticated"
  on public.food_catalog
  for select
  to authenticated
  using (true);

drop policy if exists "food_aliases_read_authenticated" on public.food_aliases;
create policy "food_aliases_read_authenticated"
  on public.food_aliases
  for select
  to authenticated
  using (true);

-- Optional seed example:
-- insert into public.food_catalog (food_name, calorie_range, macros, dish_summary, suggestion, source, verified_level)
-- values ('雞胸肉便當', '500-620 kcal', '{"protein":35,"carbs":62,"fat":14,"sodium":920}', '主食＋蛋白質便當', '可搭配一份無糖茶與青菜。', 'manual_seed', 3)
-- on conflict do nothing;
