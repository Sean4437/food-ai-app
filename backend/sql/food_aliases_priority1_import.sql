-- Import aliases for priority-1 foods.
-- Run in Supabase SQL Editor after catalog import.
begin;

with alias_seed(food_name, alias_lang, alias) as (
  values
    ('肉燥飯', 'zh-TW', '肉燥飯'),
    ('豬腳飯', 'zh-TW', '豬腳飯'),
    ('滷雞腿飯', 'zh-TW', '滷雞腿飯'),
    ('香腸飯', 'zh-TW', '香腸飯'),
    ('鯖魚便當', 'zh-TW', '鯖魚便當'),
    ('鱈魚便當', 'zh-TW', '鱈魚便當'),
    ('蒜泥白肉便當', 'zh-TW', '蒜泥白肉便當'),
    ('打拋豬飯', 'zh-TW', '打拋豬飯'),
    ('海南雞飯', 'zh-TW', '海南雞飯'),
    ('咖哩雞腿飯', 'zh-TW', '咖哩雞腿飯'),
    ('咖哩牛肉飯', 'zh-TW', '咖哩牛肉飯'),
    ('肉絲炒飯', 'zh-TW', '肉絲炒飯'),
    ('雞肉炒飯', 'zh-TW', '雞肉炒飯'),
    ('泡菜炒飯', 'zh-TW', '泡菜炒飯'),
    ('火腿炒飯', 'zh-TW', '火腿炒飯'),
    ('廣州炒飯', 'zh-TW', '廣州炒飯'),
    ('蛋包飯', 'zh-TW', '蛋包飯'),
    ('咖哩蛋包飯', 'zh-TW', '咖哩蛋包飯'),
    ('豬排蛋包飯', 'zh-TW', '豬排蛋包飯'),
    ('叉燒飯', 'zh-TW', '叉燒飯'),
    ('燒鴨飯', 'zh-TW', '燒鴨飯'),
    ('油雞飯', 'zh-TW', '油雞飯'),
    ('鍋燒意麵', 'zh-TW', '鍋燒意麵'),
    ('鍋燒烏龍麵', 'zh-TW', '鍋燒烏龍麵'),
    ('鍋燒雞絲麵', 'zh-TW', '鍋燒雞絲麵'),
    ('麻油麵線', 'zh-TW', '麻油麵線'),
    ('當歸麵線', 'zh-TW', '當歸麵線'),
    ('肉羹麵', 'zh-TW', '肉羹麵'),
    ('肉羹米粉', 'zh-TW', '肉羹米粉'),
    ('魷魚羹麵', 'zh-TW', '魷魚羹麵'),
    ('魷魚羹米粉', 'zh-TW', '魷魚羹米粉'),
    ('臭豆腐', 'zh-TW', '臭豆腐'),
    ('大腸包小腸', 'zh-TW', '大腸包小腸'),
    ('潤餅', 'zh-TW', '潤餅'),
    ('刈包', 'zh-TW', '刈包'),
    ('豬血糕', 'zh-TW', '豬血糕'),
    ('鹽水雞', 'zh-TW', '鹽水雞'),
    ('番茄炒蛋', 'zh-TW', '番茄炒蛋'),
    ('麻婆豆腐', 'zh-TW', '麻婆豆腐'),
    ('宮保雞丁', 'zh-TW', '宮保雞丁'),
    ('糖醋排骨', 'zh-TW', '糖醋排骨'),
    ('三杯雞', 'zh-TW', '三杯雞')
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
