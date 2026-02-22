-- Beverage baseline seed for public catalog.
-- This file is ASCII-only by design.
-- Chinese strings are stored via SQL Unicode escapes (U&'\XXXX').
--
-- Run in Supabase SQL Editor.

begin;

alter table if exists public.food_catalog
  add column if not exists reference_used text;

with seed(
  food_name,
  canonical_name,
  calorie_range,
  protein_g,
  carbs_g,
  fat_g,
  sodium_mg,
  dish_summary,
  suggestion,
  food_items_json,
  judgement_tags_json,
  beverage_base_ml,
  beverage_full_sugar_carbs,
  beverage_default_sugar_ratio,
  beverage_sugar_adjustable
) as (
  values
    (U&'\9752\8336', 'green tea',               '0-20 kcal',   0.0,  0.0, 0.0,  10.0, 'Tea base, almost zero calories.',            'Prefer no sugar or light sugar.',                    '["tea"]'::jsonb,                 '["light"]'::jsonb,         500.0, 35.0, 0.0, true),
    (U&'\7DA0\8336', 'green tea',               '0-20 kcal',   0.0,  0.0, 0.0,  10.0, 'Tea base, almost zero calories.',            'Prefer no sugar or light sugar.',                    '["tea"]'::jsonb,                 '["light"]'::jsonb,         500.0, 35.0, 0.0, true),
    (U&'\7D05\8336', 'black tea',               '0-20 kcal',   0.0,  0.0, 0.0,  12.0, 'Black tea base.',                             'Prefer no sugar or light sugar.',                    '["black tea"]'::jsonb,           '["light"]'::jsonb,         500.0, 35.0, 0.0, true),
    (U&'\70CF\9F8D\8336', 'oolong tea',         '0-20 kcal',   0.0,  0.0, 0.0,  12.0, 'Oolong tea base.',                            'Prefer no sugar or light sugar.',                    '["oolong tea"]'::jsonb,          '["light"]'::jsonb,         500.0, 35.0, 0.0, true),
    (U&'\56DB\5B63\6625', 'four seasons tea',   '0-20 kcal',   0.0,  0.0, 0.0,  10.0, 'Four seasons tea base.',                      'Prefer no sugar or light sugar.',                    '["tea"]'::jsonb,                 '["light"]'::jsonb,         500.0, 35.0, 0.0, true),
    (U&'\5976\8336', 'milk tea',                '190-240 kcal',3.0, 34.0, 4.0,  65.0, 'Milk tea base.',                               'Choose half sugar or less.',                         '["milk tea"]'::jsonb,            '["higher carbs"]'::jsonb,  500.0, 28.0, 1.0, true),
    (U&'\9BAE\5976\8336', 'fresh milk tea',     '220-290 kcal',6.0, 36.0, 6.0,  85.0, 'Fresh milk tea base.',                         'Choose half sugar or less.',                         '["fresh milk tea"]'::jsonb,      '["higher carbs"]'::jsonb,  500.0, 28.0, 1.0, true),
    (U&'\73CD\73E0\5976\8336', 'bubble milk tea','260-340 kcal',3.0,47.0, 4.0, 110.0, 'Milk tea with tapioca pearls.',               'Remove toppings first when cutting calories.',       '["milk tea","pearls"]'::jsonb,   '["higher carbs"]'::jsonb,  500.0, 28.0, 1.0, true),
    (U&'\7121\7CD6\8C46\6F3F', 'unsweetened soy milk','90-140 kcal',9.0,4.0,5.0,120.0, 'Soy milk drink, relatively higher protein.', 'Can pair with whole grains at breakfast.',           '["soy milk"]'::jsonb,            '["light"]'::jsonb,         500.0, 16.0, 0.4, true),
    (U&'\8C46\6F3F\7D05\8336', 'soy black tea', '120-180 kcal',9.0,14.0, 5.0, 130.0, 'Soy milk + black tea.',                        'Choose less sugar to reduce total carbs.',           '["soy milk","black tea"]'::jsonb,'["higher carbs"]'::jsonb,  500.0, 20.0, 0.5, true),
    (U&'\7F8E\5F0F\5496\5561', 'americano',     '0-20 kcal',   0.0,  0.0, 0.0,  10.0, 'Black coffee base.',                           'No-sugar black coffee is the lowest-calorie choice.', '["coffee"]'::jsonb,              '["light"]'::jsonb,         500.0, 24.0, 0.0, true),
    (U&'\62FF\9435', 'latte',                   '150-220 kcal',6.0, 13.0, 6.0,  80.0, 'Milk coffee drink.',                           'Keep sugar low and watch total daily fat.',          '["coffee","milk"]'::jsonb,       '["higher carbs"]'::jsonb,  500.0, 20.0, 0.2, true),
    (U&'\5361\5E03\5947\8AFE', 'cappuccino',    '130-200 kcal',6.0, 11.0, 5.0,  75.0, 'Foamed milk coffee.',                          'No sugar or light sugar is preferred.',              '["coffee","milk"]'::jsonb,       '["light"]'::jsonb,         500.0, 20.0, 0.2, true),
    (U&'\6469\5361', 'mocha',                   '180-260 kcal',5.0, 28.0, 8.0,  95.0, 'Chocolate coffee drink.',                      'If cutting calories, switch to unsweetened latte.',  '["coffee","cocoa"]'::jsonb,      '["higher carbs"]'::jsonb,  500.0, 28.0, 0.6, true),
    (U&'\53EF\53EF', 'cocoa',                   '190-250 kcal',4.0, 26.0, 6.0, 110.0, 'Cocoa drink with sugar already included.',     'Choose smaller cup size, especially at night.',      '["cocoa"]'::jsonb,               '["higher carbs"]'::jsonb,  500.0,  0.0, 1.0, false),
    (U&'\51AC\74DC\8336', 'winter melon tea',   '65-85 kcal',  0.0, 18.0, 0.0,  25.0, 'Winter melon syrup drink.',                    'Keep cup size smaller to control sugar intake.',     '["winter melon tea"]'::jsonb,    '["higher carbs"]'::jsonb,  500.0,  0.0, 1.0, false),
    (U&'\51AC\74DC\9752\8336', 'winter melon green tea','70-100 kcal',0.0,20.0,0.0,28.0,'Winter melon syrup with tea base.',          'Keep cup size smaller to control sugar intake.',     '["winter melon tea","green tea"]'::jsonb, '["higher carbs"]'::jsonb, 500.0, 0.0, 1.0, false),
    (U&'\6AB8\6AAC\7DA0\8336', 'lemon green tea','45-75 kcal', 0.0, 12.0, 0.0,  20.0, 'Lemon tea drink.',                             'Use less sugar and avoid extra toppings.',           '["lemon","green tea"]'::jsonb,   '["light"]'::jsonb,         500.0, 20.0, 0.5, true),
    (U&'\8702\871C\7DA0\8336', 'honey green tea','90-130 kcal',0.0,24.0, 0.0,  16.0, 'Honey provides intrinsic sugar.',              'For sugar control, switch to unsweetened tea.',      '["honey","green tea"]'::jsonb,   '["higher carbs"]'::jsonb,  500.0,  0.0, 1.0, false),
    (U&'\7518\8517\9752\8336', 'sugarcane green tea','95-135 kcal',0.0,25.0,0.0,22.0,'Sugarcane juice provides intrinsic sugar.',    'Keep cup size smaller when cutting calories.',       '["sugarcane","green tea"]'::jsonb, '["higher carbs"]'::jsonb, 500.0, 0.0, 1.0, false),
    (U&'\591A\591A\7DA0\8336', 'yakult green tea','80-120 kcal',1.0,20.0,0.0,42.0,   'Lactic drink + tea.',                          'Avoid adding extra sugar or sweet desserts.',        '["yakult","green tea"]'::jsonb,  '["higher carbs"]'::jsonb,  500.0,  0.0, 1.0, false),
    (U&'\6C34\679C\8336', 'fruit tea',          '110-160 kcal',0.0,28.0, 0.0,  30.0, 'Fruit tea usually includes juice and syrup.',   'Half sugar or less is recommended.',                 '["fruit","tea"]'::jsonb,         '["higher carbs"]'::jsonb,  500.0, 22.0, 0.7, true),
    (U&'\694A\679D\7518\9732', 'mango pomelo sago','210-280 kcal',2.0,36.0,2.0,40.0,'Dessert drink with fruit and toppings.',       'Treat as occasional dessert beverage.',              '["mango","pomelo","sago"]'::jsonb,'["higher carbs"]'::jsonb, 500.0, 0.0, 1.0, false)
),
updated as (
  update public.food_catalog fc
  set
    lang = 'zh-TW',
    canonical_name = s.canonical_name,
    calorie_range = s.calorie_range,
    macros = jsonb_build_object(
      'protein', s.protein_g,
      'carbs', s.carbs_g,
      'fat', s.fat_g,
      'sodium', s.sodium_mg
    ),
    dish_summary = s.dish_summary,
    suggestion = s.suggestion,
    food_items = s.food_items_json,
    judgement_tags = s.judgement_tags_json,
    source = 'manual_seed',
    verified_level = greatest(coalesce(fc.verified_level, 0), 4),
    reference_used = 'catalog',
    is_beverage = true,
    is_food = true,
    is_active = true,
    beverage_base_ml = s.beverage_base_ml,
    beverage_full_sugar_carbs = s.beverage_full_sugar_carbs,
    beverage_default_sugar_ratio = s.beverage_default_sugar_ratio,
    beverage_sugar_adjustable = s.beverage_sugar_adjustable,
    beverage_profile = jsonb_build_object(
      'base_ml', s.beverage_base_ml,
      'default_sugar_ratio', s.beverage_default_sugar_ratio,
      'full_sugar_carbs', s.beverage_full_sugar_carbs,
      'sugar_adjustable', s.beverage_sugar_adjustable
    )
  from seed s
  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))
    and coalesce(fc.lang, 'zh-TW') = 'zh-TW'
    and coalesce(fc.is_active, true) = true
  returning fc.id
)
insert into public.food_catalog (
  lang,
  food_name,
  canonical_name,
  calorie_range,
  macros,
  dish_summary,
  suggestion,
  food_items,
  judgement_tags,
  source,
  verified_level,
  reference_used,
  is_beverage,
  is_food,
  is_active,
  beverage_base_ml,
  beverage_full_sugar_carbs,
  beverage_default_sugar_ratio,
  beverage_sugar_adjustable,
  beverage_profile
)
select
  'zh-TW',
  s.food_name,
  s.canonical_name,
  s.calorie_range,
  jsonb_build_object(
    'protein', s.protein_g,
    'carbs', s.carbs_g,
    'fat', s.fat_g,
    'sodium', s.sodium_mg
  ),
  s.dish_summary,
  s.suggestion,
  s.food_items_json,
  s.judgement_tags_json,
  'manual_seed',
  4,
  'catalog',
  true,
  true,
  true,
  s.beverage_base_ml,
  s.beverage_full_sugar_carbs,
  s.beverage_default_sugar_ratio,
  s.beverage_sugar_adjustable,
  jsonb_build_object(
    'base_ml', s.beverage_base_ml,
    'default_sugar_ratio', s.beverage_default_sugar_ratio,
    'full_sugar_carbs', s.beverage_full_sugar_carbs,
    'sugar_adjustable', s.beverage_sugar_adjustable
  )
from seed s
where not exists (
  select 1
  from public.food_catalog fc
  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))
    and coalesce(fc.lang, 'zh-TW') = 'zh-TW'
    and coalesce(fc.is_active, true) = true
);

with alias_seed(food_name, alias_lang, alias) as (
  values
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\7121\7CD6'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\5FAE\7CD6'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\5C11\7CD6'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\534A\7CD6'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\5168\7CD6'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\534A\7CD6\53BB\51B0'),
    (U&'\9752\8336', 'zh-TW', U&'\9752\8336\534A\7CD6\53BB\51B0\52A0\73CD\73E0'),
    (U&'\9752\8336', 'en', 'green tea'),

    (U&'\7DA0\8336', 'zh-TW', U&'\7DA0\8336'),
    (U&'\7DA0\8336', 'zh-TW', U&'\7DA0\8336\7121\7CD6'),
    (U&'\7DA0\8336', 'zh-TW', U&'\7DA0\8336\5FAE\7CD6'),
    (U&'\7DA0\8336', 'zh-TW', U&'\7DA0\8336\534A\7CD6'),
    (U&'\7DA0\8336', 'en', 'green tea'),

    (U&'\7D05\8336', 'zh-TW', U&'\7D05\8336'),
    (U&'\7D05\8336', 'zh-TW', U&'\7D05\8336\7121\7CD6'),
    (U&'\7D05\8336', 'zh-TW', U&'\7D05\8336\5FAE\7CD6'),
    (U&'\7D05\8336', 'zh-TW', U&'\7D05\8336\534A\7CD6'),
    (U&'\7D05\8336', 'en', 'black tea'),

    (U&'\70CF\9F8D\8336', 'zh-TW', U&'\70CF\9F8D\8336'),
    (U&'\70CF\9F8D\8336', 'zh-TW', U&'\9AD8\5C71\70CF\9F8D'),
    (U&'\70CF\9F8D\8336', 'zh-TW', U&'\91D1\8431'),
    (U&'\70CF\9F8D\8336', 'zh-TW', U&'\9435\89C0\97F3'),
    (U&'\70CF\9F8D\8336', 'en', 'oolong tea'),

    (U&'\56DB\5B63\6625', 'zh-TW', U&'\56DB\5B63\6625'),
    (U&'\56DB\5B63\6625', 'zh-TW', U&'\56DB\5B63\6625\8336'),
    (U&'\56DB\5B63\6625', 'en', 'four seasons tea'),

    (U&'\5976\8336', 'zh-TW', U&'\5976\8336'),
    (U&'\5976\8336', 'zh-TW', U&'\5976\8336\5FAE\7CD6'),
    (U&'\5976\8336', 'zh-TW', U&'\5976\8336\534A\7CD6'),
    (U&'\5976\8336', 'en', 'milk tea'),

    (U&'\9BAE\5976\8336', 'zh-TW', U&'\9BAE\5976\8336'),
    (U&'\9BAE\5976\8336', 'zh-TW', U&'\7D05\8336\62FF\9435'),
    (U&'\9BAE\5976\8336', 'zh-TW', U&'\7DA0\8336\62FF\9435'),
    (U&'\9BAE\5976\8336', 'en', 'fresh milk tea'),

    (U&'\73CD\73E0\5976\8336', 'zh-TW', U&'\73CD\73E0\5976\8336'),
    (U&'\73CD\73E0\5976\8336', 'zh-TW', U&'\6CE2\9738\5976\8336'),
    (U&'\73CD\73E0\5976\8336', 'zh-TW', U&'\73CD\5976'),
    (U&'\73CD\73E0\5976\8336', 'zh-TW', U&'\73CD\73E0\9BAE\5976\8336'),
    (U&'\73CD\73E0\5976\8336', 'en', 'bubble milk tea'),
    (U&'\73CD\73E0\5976\8336', 'en', 'boba milk tea'),

    (U&'\7121\7CD6\8C46\6F3F', 'zh-TW', U&'\7121\7CD6\8C46\6F3F'),
    (U&'\7121\7CD6\8C46\6F3F', 'zh-TW', U&'\8C46\4E73'),
    (U&'\7121\7CD6\8C46\6F3F', 'zh-TW', U&'\8C46\5976'),
    (U&'\7121\7CD6\8C46\6F3F', 'en', 'unsweetened soy milk'),
    (U&'\7121\7CD6\8C46\6F3F', 'en', 'soy milk'),

    (U&'\8C46\6F3F\7D05\8336', 'zh-TW', U&'\8C46\6F3F\7D05\8336'),
    (U&'\8C46\6F3F\7D05\8336', 'zh-TW', U&'\8C46\5976\7D05\8336'),
    (U&'\8C46\6F3F\7D05\8336', 'zh-TW', U&'\8C46\4E73\7D05\8336'),
    (U&'\8C46\6F3F\7D05\8336', 'en', 'soy black tea'),

    (U&'\7F8E\5F0F\5496\5561', 'zh-TW', U&'\7F8E\5F0F\5496\5561'),
    (U&'\7F8E\5F0F\5496\5561', 'zh-TW', U&'\7F8E\5F0F'),
    (U&'\7F8E\5F0F\5496\5561', 'zh-TW', U&'\51B0\7F8E\5F0F'),
    (U&'\7F8E\5F0F\5496\5561', 'zh-TW', U&'\71B1\7F8E\5F0F'),
    (U&'\7F8E\5F0F\5496\5561', 'en', 'americano'),
    (U&'\7F8E\5F0F\5496\5561', 'en', 'black coffee'),

    (U&'\62FF\9435', 'zh-TW', U&'\62FF\9435'),
    (U&'\62FF\9435', 'zh-TW', U&'\5496\5561\62FF\9435'),
    (U&'\62FF\9435', 'zh-TW', U&'\9BAE\5976\62FF\9435'),
    (U&'\62FF\9435', 'zh-TW', U&'\71D5\9EA5\62FF\9435'),
    (U&'\62FF\9435', 'en', 'latte'),

    (U&'\5361\5E03\5947\8AFE', 'zh-TW', U&'\5361\5E03\5947\8AFE'),
    (U&'\5361\5E03\5947\8AFE', 'zh-TW', U&'\5361\5E03'),
    (U&'\5361\5E03\5947\8AFE', 'en', 'cappuccino'),

    (U&'\6469\5361', 'zh-TW', U&'\6469\5361'),
    (U&'\6469\5361', 'zh-TW', U&'\6469\5361\5496\5561'),
    (U&'\6469\5361', 'en', 'mocha'),

    (U&'\53EF\53EF', 'zh-TW', U&'\53EF\53EF'),
    (U&'\53EF\53EF', 'zh-TW', U&'\71B1\53EF\53EF'),
    (U&'\53EF\53EF', 'zh-TW', U&'\5DE7\514B\529B\53EF\53EF'),
    (U&'\53EF\53EF', 'en', 'cocoa'),
    (U&'\53EF\53EF', 'en', 'hot chocolate'),

    (U&'\51AC\74DC\8336', 'zh-TW', U&'\51AC\74DC\8336'),
    (U&'\51AC\74DC\8336', 'zh-TW', U&'\51AC\74DC\6AB8\6AAC'),
    (U&'\51AC\74DC\8336', 'en', 'winter melon tea'),

    (U&'\51AC\74DC\9752\8336', 'zh-TW', U&'\51AC\74DC\9752\8336'),
    (U&'\51AC\74DC\9752\8336', 'zh-TW', U&'\51AC\74DC\7DA0\8336'),
    (U&'\51AC\74DC\9752\8336', 'en', 'winter melon green tea'),

    (U&'\6AB8\6AAC\7DA0\8336', 'zh-TW', U&'\6AB8\6AAC\7DA0\8336'),
    (U&'\6AB8\6AAC\7DA0\8336', 'zh-TW', U&'\6AB8\6AAC\9752\8336'),
    (U&'\6AB8\6AAC\7DA0\8336', 'zh-TW', U&'\6AB8\6AAC\7D05\8336'),
    (U&'\6AB8\6AAC\7DA0\8336', 'en', 'lemon green tea'),

    (U&'\8702\871C\7DA0\8336', 'zh-TW', U&'\8702\871C\7DA0\8336'),
    (U&'\8702\871C\7DA0\8336', 'zh-TW', U&'\8702\871C\9752\8336'),
    (U&'\8702\871C\7DA0\8336', 'zh-TW', U&'\8702\871C\7D05\8336'),
    (U&'\8702\871C\7DA0\8336', 'en', 'honey green tea'),

    (U&'\7518\8517\9752\8336', 'zh-TW', U&'\7518\8517\9752\8336'),
    (U&'\7518\8517\9752\8336', 'zh-TW', U&'\7518\8517\7DA0\8336'),
    (U&'\7518\8517\9752\8336', 'zh-TW', U&'\7518\8517\7D05\8336'),
    (U&'\7518\8517\9752\8336', 'en', 'sugarcane green tea'),

    (U&'\591A\591A\7DA0\8336', 'zh-TW', U&'\591A\591A\7DA0\8336'),
    (U&'\591A\591A\7DA0\8336', 'zh-TW', U&'\990A\6A02\591A\7DA0\8336'),
    (U&'\591A\591A\7DA0\8336', 'zh-TW', U&'\591A\591A\9752\8336'),
    (U&'\591A\591A\7DA0\8336', 'en', 'yakult green tea'),

    (U&'\6C34\679C\8336', 'zh-TW', U&'\6C34\679C\8336'),
    (U&'\6C34\679C\8336', 'zh-TW', U&'\767E\9999\7DA0'),
    (U&'\6C34\679C\8336', 'zh-TW', U&'\67F3\6A59\7DA0'),
    (U&'\6C34\679C\8336', 'zh-TW', U&'\8461\8404\67DA\7DA0'),
    (U&'\6C34\679C\8336', 'en', 'fruit tea'),

    (U&'\694A\679D\7518\9732', 'zh-TW', U&'\694A\679D\7518\9732'),
    (U&'\694A\679D\7518\9732', 'en', 'mango pomelo sago')
)
insert into public.food_aliases (food_id, lang, alias)
select
  fc.id,
  a.alias_lang,
  a.alias
from alias_seed a
join public.food_catalog fc
  on lower(btrim(fc.food_name)) = lower(btrim(a.food_name))
 and coalesce(fc.lang, 'zh-TW') = 'zh-TW'
 and coalesce(fc.is_active, true) = true
where not exists (
  select 1
  from public.food_aliases fa
  where fa.food_id = fc.id
    and lower(btrim(fa.lang)) = lower(btrim(a.alias_lang))
    and lower(btrim(fa.alias)) = lower(btrim(a.alias))
);

commit;

-- Verification:
-- select food_name, calorie_range, macros, beverage_profile
-- from public.food_catalog
-- where lang = 'zh-TW'
-- order by food_name;
