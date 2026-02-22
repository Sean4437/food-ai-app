-- Resolve ambiguous English alias "green tea" between 青茶 and 綠茶.
-- Safe to run multiple times.

begin;

-- Remove "green tea" from 青茶 so English lookup maps to 綠茶 only.
delete from public.food_aliases fa
using public.food_catalog fc
where fa.food_id = fc.id
  and fa.lang = 'en'
  and lower(trim(fa.alias)) = 'green tea'
  and fc.food_name = U&'\9752\8336' -- 青茶
  and coalesce(fc.is_active, true) = true;

-- Add unique aliases for 青茶.
insert into public.food_aliases (food_id, lang, alias)
select fc.id, 'en', 'qing tea'
from public.food_catalog fc
where fc.food_name = U&'\9752\8336' -- 青茶
  and coalesce(fc.is_active, true) = true
on conflict (food_id, lang, alias_norm) do nothing;

insert into public.food_aliases (food_id, lang, alias)
select fc.id, 'en', 'qingcha'
from public.food_catalog fc
where fc.food_name = U&'\9752\8336' -- 青茶
  and coalesce(fc.is_active, true) = true
on conflict (food_id, lang, alias_norm) do nothing;

commit;

-- Verify no ambiguous alias remains:
-- select fa.lang, lower(trim(fa.alias)) as alias_key, count(distinct fa.food_id) as food_cnt
-- from public.food_aliases fa
-- join public.food_catalog fc on fc.id = fa.food_id
-- where coalesce(fc.is_active,true)=true
-- group by fa.lang, lower(trim(fa.alias))
-- having count(distinct fa.food_id) > 1
-- order by food_cnt desc, alias_key;
