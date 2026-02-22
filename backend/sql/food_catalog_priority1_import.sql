-- Import priority-1 foods into public.food_catalog.
-- Safe to run multiple times.
begin;

with seed(
  lang,
  food_name,
  canonical_name,
  calorie_range,
  macros,
  food_items,
  judgement_tags,
  dish_summary,
  suggestion,
  is_beverage,
  is_food,
  is_active,
  source,
  verified_level,
  reference_used,
  beverage_profile
) as (
  values
    ('zh-TW', '肉燥飯', '肉燥飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '豬腳飯', '豬腳飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '滷雞腿飯', '滷雞腿飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '香腸飯', '香腸飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '鯖魚便當', '鯖魚便當', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '鱈魚便當', '鱈魚便當', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '蒜泥白肉便當', '蒜泥白肉便當', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '打拋豬飯', '打拋豬飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '海南雞飯', '海南雞飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '咖哩雞腿飯', '咖哩雞腿飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '咖哩牛肉飯', '咖哩牛肉飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '肉絲炒飯', '肉絲炒飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '雞肉炒飯', '雞肉炒飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '泡菜炒飯', '泡菜炒飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '火腿炒飯', '火腿炒飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '廣州炒飯', '廣州炒飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '蛋包飯', '蛋包飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '咖哩蛋包飯', '咖哩蛋包飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '豬排蛋包飯', '豬排蛋包飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '叉燒飯', '叉燒飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '燒鴨飯', '燒鴨飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '油雞飯', '油雞飯', '553-675 kcal', '{"carbs":80,"sodium":1200,"protein":24,"fat":22}'::jsonb, '["rice/noodle","protein source","sauce"]'::jsonb, '["higher carbs"]'::jsonb, 'Rice/noodle main meal.', 'Add vegetables and reduce sauce when possible.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '鍋燒意麵', '鍋燒意麵', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '鍋燒烏龍麵', '鍋燒烏龍麵', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '鍋燒雞絲麵', '鍋燒雞絲麵', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '麻油麵線', '麻油麵線', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '當歸麵線', '當歸麵線', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '肉羹麵', '肉羹麵', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '肉羹米粉', '肉羹米粉', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '魷魚羹麵', '魷魚羹麵', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '魷魚羹米粉', '魷魚羹米粉', '484-592 kcal', '{"carbs":74,"sodium":1550,"protein":20,"fat":18}'::jsonb, '["noodle","broth","protein source"]'::jsonb, '["higher sodium"]'::jsonb, 'Soup noodle meal, usually higher sodium.', 'Drink less soup and add protein or vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '臭豆腐', '臭豆腐', '362-442 kcal', '{"carbs":45,"sodium":920,"protein":15,"fat":18}'::jsonb, '["main ingredient","sauce"]'::jsonb, '["balanced"]'::jsonb, 'Taiwanese snack. Cooking oil and sauce can vary.', 'Pair with vegetables and avoid extra sugary drinks.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '大腸包小腸', '大腸包小腸', '362-442 kcal', '{"carbs":45,"sodium":920,"protein":15,"fat":18}'::jsonb, '["main ingredient","sauce"]'::jsonb, '["balanced"]'::jsonb, 'Taiwanese snack. Cooking oil and sauce can vary.', 'Pair with vegetables and avoid extra sugary drinks.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '潤餅', '潤餅', '362-442 kcal', '{"carbs":45,"sodium":920,"protein":15,"fat":18}'::jsonb, '["main ingredient","sauce"]'::jsonb, '["balanced"]'::jsonb, 'Taiwanese snack. Cooking oil and sauce can vary.', 'Pair with vegetables and avoid extra sugary drinks.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '刈包', '刈包', '362-442 kcal', '{"carbs":45,"sodium":920,"protein":15,"fat":18}'::jsonb, '["main ingredient","sauce"]'::jsonb, '["balanced"]'::jsonb, 'Taiwanese snack. Cooking oil and sauce can vary.', 'Pair with vegetables and avoid extra sugary drinks.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '豬血糕', '豬血糕', '362-442 kcal', '{"carbs":45,"sodium":920,"protein":15,"fat":18}'::jsonb, '["main ingredient","sauce"]'::jsonb, '["balanced"]'::jsonb, 'Taiwanese snack. Cooking oil and sauce can vary.', 'Pair with vegetables and avoid extra sugary drinks.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '鹽水雞', '鹽水雞', '362-442 kcal', '{"carbs":45,"sodium":920,"protein":15,"fat":18}'::jsonb, '["main ingredient","sauce"]'::jsonb, '["balanced"]'::jsonb, 'Taiwanese snack. Cooking oil and sauce can vary.', 'Pair with vegetables and avoid extra sugary drinks.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '番茄炒蛋', '番茄炒蛋', '320-400 kcal', '{"carbs":20,"sodium":980,"protein":24,"fat":20}'::jsonb, '["main dish","seasoning"]'::jsonb, '["balanced"]'::jsonb, 'Home-style dish.', 'Pair with half bowl of rice and vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '麻婆豆腐', '麻婆豆腐', '320-400 kcal', '{"carbs":20,"sodium":980,"protein":24,"fat":20}'::jsonb, '["main dish","seasoning"]'::jsonb, '["balanced"]'::jsonb, 'Home-style dish.', 'Pair with half bowl of rice and vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '宮保雞丁', '宮保雞丁', '320-400 kcal', '{"carbs":20,"sodium":980,"protein":24,"fat":20}'::jsonb, '["main dish","seasoning"]'::jsonb, '["balanced"]'::jsonb, 'Home-style dish.', 'Pair with half bowl of rice and vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '糖醋排骨', '糖醋排骨', '320-400 kcal', '{"carbs":20,"sodium":980,"protein":24,"fat":20}'::jsonb, '["main dish","seasoning"]'::jsonb, '["balanced"]'::jsonb, 'Home-style dish.', 'Pair with half bowl of rice and vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb),
    ('zh-TW', '三杯雞', '三杯雞', '320-400 kcal', '{"carbs":20,"sodium":980,"protein":24,"fat":20}'::jsonb, '["main dish","seasoning"]'::jsonb, '["balanced"]'::jsonb, 'Home-style dish.', 'Pair with half bowl of rice and vegetables.', false, true, true, 'manual_seed', 2, 'catalog', '{}'::jsonb)
),
updated as (
  update public.food_catalog fc
  set
    canonical_name = s.canonical_name,
    calorie_range = s.calorie_range,
    macros = s.macros,
    food_items = s.food_items,
    judgement_tags = s.judgement_tags,
    dish_summary = s.dish_summary,
    suggestion = s.suggestion,
    is_beverage = s.is_beverage,
    is_food = s.is_food,
    is_active = s.is_active,
    source = s.source,
    verified_level = s.verified_level,
    reference_used = s.reference_used,
    beverage_profile = s.beverage_profile
  from seed s
  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))
    and coalesce(fc.lang, 'zh-TW') = s.lang
    and coalesce(fc.is_active, true) = true
  returning fc.id
)
insert into public.food_catalog (
  lang,
  food_name,
  canonical_name,
  calorie_range,
  macros,
  food_items,
  judgement_tags,
  dish_summary,
  suggestion,
  is_beverage,
  is_food,
  is_active,
  source,
  verified_level,
  reference_used,
  beverage_profile
)
select
  s.lang,
  s.food_name,
  s.canonical_name,
  s.calorie_range,
  s.macros,
  s.food_items,
  s.judgement_tags,
  s.dish_summary,
  s.suggestion,
  s.is_beverage,
  s.is_food,
  s.is_active,
  s.source,
  s.verified_level,
  s.reference_used,
  s.beverage_profile
from seed s
where not exists (
  select 1
  from public.food_catalog fc
  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))
    and coalesce(fc.lang, 'zh-TW') = s.lang
    and coalesce(fc.is_active, true) = true
);

commit;
