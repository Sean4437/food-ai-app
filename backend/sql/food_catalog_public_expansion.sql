-- Public food catalog expansion: image fields + search miss telemetry.
-- Safe to run multiple times in Supabase SQL Editor.

alter table public.food_catalog
  add column if not exists image_url text;

alter table public.food_catalog
  add column if not exists thumb_url text;

alter table public.food_catalog
  add column if not exists image_source text;

alter table public.food_catalog
  add column if not exists image_license text;

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
