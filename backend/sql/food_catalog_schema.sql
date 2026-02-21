-- Food catalog tables for name-first logging flow.
-- Apply in Supabase SQL editor.

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

create table if not exists public.food_catalog (
  id uuid primary key default gen_random_uuid(),
  lang text not null default 'zh-TW' check (lang in ('zh-TW', 'en')),
  food_name text not null,
  canonical_name text,
  calorie_range text not null default '' check (
    calorie_range = '' or calorie_range ~ '^[0-9]+\\s*-\\s*[0-9]+\\s*kcal$'
  ),
  macros jsonb not null default '{"protein":0,"carbs":0,"fat":0,"sodium":0}'::jsonb,
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
  verified_level integer not null default 0 check (verified_level between 0 and 5),
  is_food boolean not null default true,
  is_beverage boolean not null default false,
  is_active boolean not null default true,
  deprecated_at timestamptz,
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
  add column if not exists lang text not null default 'zh-TW';

alter table public.food_catalog
  add column if not exists is_active boolean not null default true;

alter table public.food_catalog
  add column if not exists deprecated_at timestamptz;

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

create index if not exists idx_food_catalog_lang_active
  on public.food_catalog (lang, is_active);

create index if not exists idx_food_catalog_updated_at
  on public.food_catalog (updated_at desc);

create index if not exists idx_food_catalog_food_name_trgm
  on public.food_catalog using gin (food_name gin_trgm_ops);

create index if not exists idx_food_catalog_canonical_name_trgm
  on public.food_catalog using gin (canonical_name gin_trgm_ops);

create unique index if not exists uq_food_catalog_lang_food_name_active
  on public.food_catalog (lang, lower(btrim(food_name)))
  where is_active;

create unique index if not exists uq_food_catalog_lang_canonical_name_active
  on public.food_catalog (lang, lower(btrim(canonical_name)))
  where is_active and canonical_name is not null and btrim(canonical_name) <> '';

create table if not exists public.food_aliases (
  id bigserial primary key,
  food_id uuid not null references public.food_catalog(id) on delete cascade,
  lang text not null default 'zh-TW',
  alias text not null,
  alias_norm text generated always as (lower(trim(alias))) stored,
  created_at timestamptz not null default now(),
  unique (food_id, lang, alias_norm)
);

create index if not exists idx_food_aliases_alias_norm
  on public.food_aliases (alias_norm);

create index if not exists idx_food_aliases_alias_trgm
  on public.food_aliases using gin (alias gin_trgm_ops);

create index if not exists idx_food_aliases_food_id
  on public.food_aliases (food_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_food_catalog_set_updated_at on public.food_catalog;
create trigger trg_food_catalog_set_updated_at
before update on public.food_catalog
for each row execute function public.set_updated_at();

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
