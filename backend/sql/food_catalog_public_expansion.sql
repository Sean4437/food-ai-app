-- Public food catalog expansion: image fields + search miss telemetry.
-- Safe to run multiple times in Supabase SQL Editor.

create extension if not exists pg_trgm;

alter table public.food_catalog
  add column if not exists image_url text;

alter table public.food_catalog
  add column if not exists lang text not null default 'zh-TW';

alter table public.food_catalog
  add column if not exists is_active boolean not null default true;

alter table public.food_catalog
  add column if not exists deprecated_at timestamptz;

alter table public.food_catalog
  add column if not exists thumb_url text;

alter table public.food_catalog
  add column if not exists image_source text;

alter table public.food_catalog
  add column if not exists image_license text;

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

create table if not exists public.food_search_miss (
  id bigserial primary key,
  query text not null,
  query_norm text not null,
  lang text not null default 'zh-TW',
  source text not null default 'name_input',
  user_id uuid,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_food_search_miss_query_norm
  on public.food_search_miss (query_norm);

create index if not exists idx_food_search_miss_created_at
  on public.food_search_miss (created_at desc);

create index if not exists idx_food_search_miss_lang
  on public.food_search_miss (lang);

create index if not exists idx_food_catalog_lang_active
  on public.food_catalog (lang, is_active);

create index if not exists idx_food_catalog_updated_at
  on public.food_catalog (updated_at desc);

create index if not exists idx_food_catalog_food_name_trgm
  on public.food_catalog using gin (food_name gin_trgm_ops);

create index if not exists idx_food_catalog_canonical_name_trgm
  on public.food_catalog using gin (canonical_name gin_trgm_ops);

create index if not exists idx_food_aliases_alias_trgm
  on public.food_aliases using gin (alias gin_trgm_ops);

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

alter table public.food_search_miss enable row level security;

drop policy if exists "food_search_miss_read_authenticated" on public.food_search_miss;
create policy "food_search_miss_read_authenticated"
  on public.food_search_miss
  for select
  to authenticated
  using (true);

create or replace view public.food_search_miss_top_30d as
select
  query_norm,
  max(query) as sample_query,
  lang,
  count(*)::bigint as miss_count,
  max(created_at) as last_seen_at
from public.food_search_miss
where created_at >= (now() - interval '30 days')
group by query_norm, lang;

