-- Food catalog hardening migration for existing projects.
-- Safe to run multiple times in Supabase SQL Editor.

create extension if not exists pg_trgm;

alter table public.food_catalog
  add column if not exists lang text;

alter table public.food_catalog
  add column if not exists is_active boolean;

alter table public.food_catalog
  add column if not exists deprecated_at timestamptz;

alter table public.food_catalog
  add column if not exists reference_used text;

alter table public.food_aliases
  add column if not exists lang text;

update public.food_catalog
set lang = case
  when lang in ('zh-TW', 'en') then lang
  else 'zh-TW'
end
where lang is null or btrim(lang) = '' or lang not in ('zh-TW', 'en');

update public.food_catalog
set is_active = true
where is_active is null;

update public.food_catalog
set reference_used = 'catalog'
where reference_used is null or btrim(reference_used) = '';

update public.food_aliases fa
set lang = case
  when coalesce(nullif(fa.lang, ''), fc.lang) in ('zh-TW', 'en') then coalesce(nullif(fa.lang, ''), fc.lang)
  else 'zh-TW'
end
from public.food_catalog fc
where fa.food_id = fc.id
  and (fa.lang is null or btrim(fa.lang) = '' or fa.lang not in ('zh-TW', 'en'));

alter table public.food_catalog
  alter column lang set default 'zh-TW';

alter table public.food_catalog
  alter column lang set not null;

alter table public.food_catalog
  alter column is_active set default true;

alter table public.food_catalog
  alter column is_active set not null;

alter table public.food_aliases
  alter column lang set default 'zh-TW';

alter table public.food_aliases
  alter column lang set not null;

update public.food_catalog
set macros = jsonb_build_object(
  'protein', greatest(0, coalesce(case when coalesce(macros->>'protein', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'protein')::numeric end, 0)),
  'carbs', greatest(0, coalesce(case when coalesce(macros->>'carbs', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'carbs')::numeric end, 0)),
  'fat', greatest(0, coalesce(case when coalesce(macros->>'fat', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'fat')::numeric end, 0)),
  'sodium', greatest(0, coalesce(case when coalesce(macros->>'sodium', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'sodium')::numeric end, 0))
)
where macros is null
   or jsonb_typeof(macros) <> 'object'
   or not (macros ? 'protein' and macros ? 'carbs' and macros ? 'fat' and macros ? 'sodium')
   or not (
     coalesce(case when coalesce(macros->>'protein', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'protein')::numeric end, -1) >= 0
     and coalesce(case when coalesce(macros->>'carbs', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'carbs')::numeric end, -1) >= 0
     and coalesce(case when coalesce(macros->>'fat', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'fat')::numeric end, -1) >= 0
     and coalesce(case when coalesce(macros->>'sodium', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'sodium')::numeric end, -1) >= 0
   );

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chk_food_catalog_lang'
      and conrelid = 'public.food_catalog'::regclass
  ) then
    alter table public.food_catalog
      add constraint chk_food_catalog_lang
      check (lang in ('zh-TW', 'en')) not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chk_food_catalog_verified_level'
      and conrelid = 'public.food_catalog'::regclass
  ) then
    alter table public.food_catalog
      add constraint chk_food_catalog_verified_level
      check (verified_level between 0 and 5) not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'chk_food_catalog_macros_nonnegative'
      and conrelid = 'public.food_catalog'::regclass
  ) then
    alter table public.food_catalog
      add constraint chk_food_catalog_macros_nonnegative
      check (
        jsonb_typeof(macros) = 'object'
        and macros ? 'protein'
        and macros ? 'carbs'
        and macros ? 'fat'
        and macros ? 'sodium'
        and coalesce(case when coalesce(macros->>'protein', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'protein')::numeric end, -1) >= 0
        and coalesce(case when coalesce(macros->>'carbs', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'carbs')::numeric end, -1) >= 0
        and coalesce(case when coalesce(macros->>'fat', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'fat')::numeric end, -1) >= 0
        and coalesce(case when coalesce(macros->>'sodium', '') ~ '^-?[0-9]+([.][0-9]+)?$' then (macros->>'sodium')::numeric end, -1) >= 0
      ) not valid;
  end if;
end $$;

do $$
begin
  begin
    alter table public.food_catalog validate constraint chk_food_catalog_lang;
  exception when others then
    raise notice 'Skip validate chk_food_catalog_lang: %', sqlerrm;
  end;
  begin
    alter table public.food_catalog validate constraint chk_food_catalog_verified_level;
  exception when others then
    raise notice 'Skip validate chk_food_catalog_verified_level: %', sqlerrm;
  end;
  begin
    alter table public.food_catalog validate constraint chk_food_catalog_macros_nonnegative;
  exception when others then
    raise notice 'Skip validate chk_food_catalog_macros_nonnegative: %', sqlerrm;
  end;
end $$;

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

do $$
begin
  if to_regclass('public.uq_food_catalog_lang_food_name_active') is null then
    if exists (
      select 1
      from (
        select lang, lower(btrim(food_name)) as name_norm, count(*) as cnt
        from public.food_catalog
        where is_active
        group by lang, lower(btrim(food_name))
        having count(*) > 1
      ) dup
    ) then
      raise notice 'Skip unique index uq_food_catalog_lang_food_name_active: duplicate active names exist.';
    else
      create unique index uq_food_catalog_lang_food_name_active
        on public.food_catalog (lang, lower(btrim(food_name)))
        where is_active;
    end if;
  end if;
end $$;

do $$
begin
  if to_regclass('public.uq_food_catalog_lang_canonical_name_active') is null then
    if exists (
      select 1
      from (
        select lang, lower(btrim(canonical_name)) as canonical_norm, count(*) as cnt
        from public.food_catalog
        where is_active and canonical_name is not null and btrim(canonical_name) <> ''
        group by lang, lower(btrim(canonical_name))
        having count(*) > 1
      ) dup
    ) then
      raise notice 'Skip unique index uq_food_catalog_lang_canonical_name_active: duplicate active canonical names exist.';
    else
      create unique index uq_food_catalog_lang_canonical_name_active
        on public.food_catalog (lang, lower(btrim(canonical_name)))
        where is_active and canonical_name is not null and btrim(canonical_name) <> '';
    end if;
  end if;
end $$;

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

create or replace function public.cleanup_food_search_miss(retention_days integer default 180)
returns bigint
language plpgsql
as $$
declare
  deleted_count bigint := 0;
begin
  if retention_days < 1 then
    retention_days := 1;
  end if;
  delete from public.food_search_miss
  where created_at < now() - make_interval(days => retention_days);
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

select public.cleanup_food_search_miss(180);
