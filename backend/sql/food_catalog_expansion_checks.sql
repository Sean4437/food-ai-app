-- Food catalog expansion checks
-- Run after each import batch.

-- 1) Active food counts by language
select lang, count(*) as active_food_count
from public.food_catalog
where coalesce(is_active, true) = true
group by lang
order by lang;

-- 2) Duplicate active food_name
select lang, lower(trim(food_name)) as food_name_key, count(*) as cnt
from public.food_catalog
where coalesce(is_active, true) = true
group by lang, lower(trim(food_name))
having count(*) > 1
order by cnt desc, food_name_key;

-- 3) Duplicate active canonical_name
select lang, lower(trim(canonical_name)) as canonical_key, count(*) as cnt
from public.food_catalog
where coalesce(is_active, true) = true
  and canonical_name is not null
  and trim(canonical_name) <> ''
group by lang, lower(trim(canonical_name))
having count(*) > 1
order by cnt desc, canonical_key;

-- 4) Ambiguous aliases (one alias mapped to multiple active foods)
select
  fa.lang,
  lower(trim(fa.alias)) as alias_key,
  count(distinct fa.food_id) as food_cnt
from public.food_aliases fa
join public.food_catalog fc on fc.id = fa.food_id
where coalesce(fc.is_active, true) = true
group by fa.lang, lower(trim(fa.alias))
having count(distinct fa.food_id) > 1
order by food_cnt desc, alias_key;

-- 5) Null/empty key fields check
select
  sum(case when food_name is null or trim(food_name) = '' then 1 else 0 end) as empty_food_name,
  sum(case when calorie_range is null or trim(calorie_range) = '' then 1 else 0 end) as empty_calorie_range,
  sum(case when macros is null then 1 else 0 end) as null_macros
from public.food_catalog
where coalesce(is_active, true) = true;

-- 6) Top missing search queries in last 30 days (admin should review and add)
select query_norm, lang, count(*) as miss_cnt, max(created_at) as last_seen_at
from public.food_search_miss
where created_at >= (now() - interval '30 days')
group by query_norm, lang
order by miss_cnt desc, last_seen_at desc
limit 100;
