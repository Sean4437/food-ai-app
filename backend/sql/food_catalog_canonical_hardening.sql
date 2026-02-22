-- Canonical name normalization + de-duplication for food_catalog.
-- Safe to run multiple times in Supabase SQL Editor.

create or replace function public.normalize_canonical_name(raw text)
returns text
language plpgsql
immutable
as $$
declare
  value text;
begin
  if raw is null then
    return null;
  end if;

  value := lower(btrim(raw));
  value := regexp_replace(value, '[_\s/]+', '-', 'g');
  value := regexp_replace(value, '[^a-z0-9-]+', '', 'g');
  value := regexp_replace(value, '-{2,}', '-', 'g');
  value := btrim(value, '-');

  if value = '' then
    return null;
  end if;
  return value;
end;
$$;

alter table public.food_catalog
  add column if not exists canonical_name text;

update public.food_catalog
set canonical_name = public.normalize_canonical_name(canonical_name)
where canonical_name is not null
  and btrim(canonical_name) <> '';

update public.food_catalog
set canonical_name = public.normalize_canonical_name(food_name)
where (canonical_name is null or btrim(canonical_name) = '')
  and food_name ~* '[a-z0-9]';

with ranked as (
  select
    id,
    canonical_name,
    row_number() over (
      partition by lang, lower(btrim(canonical_name))
      order by
        coalesce(verified_level, 0) desc,
        coalesce(updated_at, created_at, now()) desc,
        id
    ) as rn
  from public.food_catalog
  where coalesce(is_active, true) = true
    and canonical_name is not null
    and btrim(canonical_name) <> ''
)
update public.food_catalog fc
set canonical_name = ranked.canonical_name || '-' || substr(fc.id::text, 1, 8)
from ranked
where fc.id = ranked.id
  and ranked.rn > 1;

drop index if exists public.uq_food_catalog_lang_canonical_name_active;
create unique index if not exists uq_food_catalog_lang_canonical_name_active
  on public.food_catalog (lang, lower(btrim(canonical_name)))
  where coalesce(is_active, true) = true
    and canonical_name is not null
    and btrim(canonical_name) <> '';
