$ErrorActionPreference = "Stop"

$src = Import-Csv "backend/sql/food_names_batch_300_categorized.csv" | Where-Object { $_.priority -eq "1" }

$baseByCategory = @{
  "rice_noodle" = @{
    protein = 24.0; carbs = 80.0; fat = 22.0; sodium = 1200.0
    summary = "Rice/noodle main meal."
    suggestion = "Add vegetables and reduce sauce when possible."
  }
  "noodle_soup" = @{
    protein = 20.0; carbs = 74.0; fat = 18.0; sodium = 1550.0
    summary = "Soup noodle meal, usually higher sodium."
    suggestion = "Drink less soup and add protein or vegetables."
  }
  "taiwan_snack" = @{
    protein = 15.0; carbs = 45.0; fat = 18.0; sodium = 920.0
    summary = "Taiwanese snack. Cooking oil and sauce can vary."
    suggestion = "Pair with vegetables and avoid extra sugary drinks."
  }
  "home_dish" = @{
    protein = 24.0; carbs = 20.0; fat = 20.0; sodium = 980.0
    summary = "Home-style dish."
    suggestion = "Pair with half bowl of rice and vegetables."
  }
}

function Clone-Profile($srcProfile) {
  return @{
    protein = [double]$srcProfile.protein
    carbs = [double]$srcProfile.carbs
    fat = [double]$srcProfile.fat
    sodium = [double]$srcProfile.sodium
    summary = [string]$srcProfile.summary
    suggestion = [string]$srcProfile.suggestion
  }
}

function Build-Range([double]$protein, [double]$carbs, [double]$fat) {
  $kcal = ($protein * 4.0) + ($carbs * 4.0) + ($fat * 9.0)
  $low = [int][math]::Round($kcal * 0.9)
  $high = [int][math]::Round($kcal * 1.1)
  if (($high - $low) -lt 80) { $high = $low + 80 }
  if ($low -lt 50) { $low = 50 }
  if ($high -le $low) { $high = $low + 40 }
  return "${low}-${high} kcal"
}

function Build-Tags([hashtable]$p) {
  $tags = New-Object System.Collections.Generic.List[string]
  if ($p.carbs -ge 78) { $tags.Add("higher carbs") }
  if ($p.fat -ge 24) { $tags.Add("higher fat") }
  if ($p.sodium -ge 1300) { $tags.Add("higher sodium") }
  if ($p.protein -ge 28) { $tags.Add("good protein") }
  if ($tags.Count -eq 0) { $tags.Add("balanced") }
  return @($tags | Select-Object -Unique | Select-Object -First 3)
}

function Build-Items([string]$category) {
  if ($category -eq "rice_noodle") { return @("rice/noodle", "protein source", "sauce") }
  if ($category -eq "noodle_soup") { return @("noodle", "broth", "protein source") }
  if ($category -eq "taiwan_snack") { return @("main ingredient", "sauce") }
  if ($category -eq "home_dish") { return @("main dish", "seasoning") }
  return @("main ingredient")
}

$catalogRows = foreach ($row in $src) {
  $foodName = [string]$row.food_name
  $category = [string]$row.category
  $base = $baseByCategory[$category]
  if ($null -eq $base) {
    $base = @{
      protein = 20.0; carbs = 60.0; fat = 18.0; sodium = 900.0
      summary = "Main meal."
      suggestion = "Add vegetables for better balance."
    }
  }
  $profile = Clone-Profile $base
  $tags = Build-Tags -p $profile
  $items = Build-Items -category $category
  $foodItemsJson = ConvertTo-Json -InputObject @($items) -Compress
  $tagsJson = ConvertTo-Json -InputObject @($tags) -Compress
  if (-not $foodItemsJson.TrimStart().StartsWith("[")) { $foodItemsJson = "[{0}]" -f $foodItemsJson }
  if (-not $tagsJson.TrimStart().StartsWith("[")) { $tagsJson = "[{0}]" -f $tagsJson }
  $macrosJson = ConvertTo-Json -InputObject @{
    protein = $profile.protein
    carbs = $profile.carbs
    fat = $profile.fat
    sodium = $profile.sodium
  } -Compress

  [PSCustomObject]@{
    lang = "zh-TW"
    food_name = $foodName
    canonical_name = $foodName
    calorie_range = (Build-Range -protein $profile.protein -carbs $profile.carbs -fat $profile.fat)
    macros = $macrosJson
    food_items = $foodItemsJson
    judgement_tags = $tagsJson
    dish_summary = $profile.summary
    suggestion = $profile.suggestion
    is_beverage = "false"
    is_food = "true"
    is_active = "true"
    beverage_base_ml = ""
    beverage_full_sugar_carbs = ""
    beverage_default_sugar_ratio = ""
    beverage_sugar_adjustable = ""
    beverage_profile = "{}"
    source = "manual_seed"
    verified_level = 2
    image_url = ""
    thumb_url = ""
    image_source = ""
    image_license = ""
    reference_used = "catalog"
  }
}

$catalogOut = "backend/sql/food_catalog_priority1_import_draft.csv"
$catalogRows | Export-Csv $catalogOut -NoTypeInformation -Encoding UTF8

$catalogSqlPath = "backend/sql/food_catalog_priority1_import.sql"
$catalogSql = @()
$catalogSql += "-- Import priority-1 foods into public.food_catalog."
$catalogSql += "-- Safe to run multiple times."
$catalogSql += "begin;"
$catalogSql += ""
$catalogSql += "with seed("
$catalogSql += "  lang,"
$catalogSql += "  food_name,"
$catalogSql += "  canonical_name,"
$catalogSql += "  calorie_range,"
$catalogSql += "  macros,"
$catalogSql += "  food_items,"
$catalogSql += "  judgement_tags,"
$catalogSql += "  dish_summary,"
$catalogSql += "  suggestion,"
$catalogSql += "  is_beverage,"
$catalogSql += "  is_food,"
$catalogSql += "  is_active,"
$catalogSql += "  source,"
$catalogSql += "  verified_level,"
$catalogSql += "  reference_used,"
$catalogSql += "  beverage_profile"
$catalogSql += ") as ("
$catalogSql += "  values"

$catalogTuples = @()
foreach ($r in $catalogRows) {
  $lang = ([string]$r.lang).Replace("'", "''")
  $foodName = ([string]$r.food_name).Replace("'", "''")
  $canonical = ([string]$r.canonical_name).Replace("'", "''")
  $calorieRange = ([string]$r.calorie_range).Replace("'", "''")
  $macros = ([string]$r.macros).Replace("'", "''")
  $foodItems = ([string]$r.food_items).Replace("'", "''")
  $judgementTags = ([string]$r.judgement_tags).Replace("'", "''")
  $summary = ([string]$r.dish_summary).Replace("'", "''")
  $suggestion = ([string]$r.suggestion).Replace("'", "''")
  $isBeverage = if ([string]$r.is_beverage -eq "true") { "true" } else { "false" }
  $isFood = if ([string]$r.is_food -eq "true") { "true" } else { "false" }
  $isActive = if ([string]$r.is_active -eq "true") { "true" } else { "false" }
  $source = ([string]$r.source).Replace("'", "''")
  $verifiedLevel = [int]$r.verified_level
  $referenceUsed = ([string]$r.reference_used).Replace("'", "''")
  $beverageProfile = ([string]$r.beverage_profile).Replace("'", "''")
  $catalogTuples += "    ('$lang', '$foodName', '$canonical', '$calorieRange', '$macros'::jsonb, '$foodItems'::jsonb, '$judgementTags'::jsonb, '$summary', '$suggestion', $isBeverage, $isFood, $isActive, '$source', $verifiedLevel, '$referenceUsed', '$beverageProfile'::jsonb)"
}
for ($i = 0; $i -lt $catalogTuples.Count; $i++) {
  if ($i -lt ($catalogTuples.Count - 1)) {
    $catalogSql += ($catalogTuples[$i] + ",")
  } else {
    $catalogSql += $catalogTuples[$i]
  }
}

$catalogSql += "),"
$catalogSql += "updated as ("
$catalogSql += "  update public.food_catalog fc"
$catalogSql += "  set"
$catalogSql += "    canonical_name = s.canonical_name,"
$catalogSql += "    calorie_range = s.calorie_range,"
$catalogSql += "    macros = s.macros,"
$catalogSql += "    food_items = s.food_items,"
$catalogSql += "    judgement_tags = s.judgement_tags,"
$catalogSql += "    dish_summary = s.dish_summary,"
$catalogSql += "    suggestion = s.suggestion,"
$catalogSql += "    is_beverage = s.is_beverage,"
$catalogSql += "    is_food = s.is_food,"
$catalogSql += "    is_active = s.is_active,"
$catalogSql += "    source = s.source,"
$catalogSql += "    verified_level = s.verified_level,"
$catalogSql += "    reference_used = s.reference_used,"
$catalogSql += "    beverage_profile = s.beverage_profile"
$catalogSql += "  from seed s"
$catalogSql += "  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))"
$catalogSql += "    and coalesce(fc.lang, 'zh-TW') = s.lang"
$catalogSql += "    and coalesce(fc.is_active, true) = true"
$catalogSql += "  returning fc.id"
$catalogSql += ")"
$catalogSql += "insert into public.food_catalog ("
$catalogSql += "  lang,"
$catalogSql += "  food_name,"
$catalogSql += "  canonical_name,"
$catalogSql += "  calorie_range,"
$catalogSql += "  macros,"
$catalogSql += "  food_items,"
$catalogSql += "  judgement_tags,"
$catalogSql += "  dish_summary,"
$catalogSql += "  suggestion,"
$catalogSql += "  is_beverage,"
$catalogSql += "  is_food,"
$catalogSql += "  is_active,"
$catalogSql += "  source,"
$catalogSql += "  verified_level,"
$catalogSql += "  reference_used,"
$catalogSql += "  beverage_profile"
$catalogSql += ")"
$catalogSql += "select"
$catalogSql += "  s.lang,"
$catalogSql += "  s.food_name,"
$catalogSql += "  s.canonical_name,"
$catalogSql += "  s.calorie_range,"
$catalogSql += "  s.macros,"
$catalogSql += "  s.food_items,"
$catalogSql += "  s.judgement_tags,"
$catalogSql += "  s.dish_summary,"
$catalogSql += "  s.suggestion,"
$catalogSql += "  s.is_beverage,"
$catalogSql += "  s.is_food,"
$catalogSql += "  s.is_active,"
$catalogSql += "  s.source,"
$catalogSql += "  s.verified_level,"
$catalogSql += "  s.reference_used,"
$catalogSql += "  s.beverage_profile"
$catalogSql += "from seed s"
$catalogSql += "where not exists ("
$catalogSql += "  select 1"
$catalogSql += "  from public.food_catalog fc"
$catalogSql += "  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))"
$catalogSql += "    and coalesce(fc.lang, 'zh-TW') = s.lang"
$catalogSql += "    and coalesce(fc.is_active, true) = true"
$catalogSql += ");"
$catalogSql += ""
$catalogSql += "commit;"

Set-Content -Path $catalogSqlPath -Value ($catalogSql -join [Environment]::NewLine) -Encoding UTF8

$aliasRows = @()
$aliasSeen = [System.Collections.Generic.HashSet[string]]::new()
foreach ($row in $src) {
  $foodName = [string]$row.food_name
  $pairs = @(
    @{ lang = "zh-TW"; alias = $foodName },
    @{ lang = "zh-TW"; alias = [string]$row.alias_zh },
    @{ lang = "en"; alias = [string]$row.alias_en }
  )
  foreach ($pair in $pairs) {
    $lang = [string]$pair.lang
    if ($null -eq $lang) { $lang = "" }
    $lang = $lang.Trim()
    $alias = [string]$pair.alias
    if ($null -eq $alias) { $alias = "" }
    $alias = $alias.Trim()
    if ([string]::IsNullOrWhiteSpace($alias)) { continue }
    $key = ("{0}|{1}|{2}" -f $foodName, $lang, $alias).ToLowerInvariant()
    if (-not $aliasSeen.Add($key)) { continue }
    $aliasRows += [PSCustomObject]@{
      food_name = $foodName
      lang = $lang
      alias = $alias
    }
  }
}

$aliasOut = "backend/sql/food_aliases_priority1_import_draft.csv"
$aliasRows | Export-Csv $aliasOut -NoTypeInformation -Encoding UTF8

$sqlPath = "backend/sql/food_aliases_priority1_import.sql"
$sqlRows = @()
$sqlRows += "-- Import aliases for priority-1 foods."
$sqlRows += "-- Run in Supabase SQL Editor after catalog import."
$sqlRows += "begin;"
$sqlRows += ""
$sqlRows += "with alias_seed(food_name, alias_lang, alias) as ("
$sqlRows += "  values"

$escapedTuples = @()
foreach ($a in $aliasRows) {
  $fn = ([string]$a.food_name).Replace("'", "''")
  $lg = ([string]$a.lang).Replace("'", "''")
  $al = ([string]$a.alias).Replace("'", "''")
  $escapedTuples += "    ('$fn', '$lg', '$al')"
}
for ($i = 0; $i -lt $escapedTuples.Count; $i++) {
  if ($i -lt ($escapedTuples.Count - 1)) {
    $sqlRows += ($escapedTuples[$i] + ",")
  } else {
    $sqlRows += $escapedTuples[$i]
  }
}

$sqlRows += ")"
$sqlRows += "insert into public.food_aliases (food_id, lang, alias)"
$sqlRows += "select"
$sqlRows += "  fc.id,"
$sqlRows += "  a.alias_lang,"
$sqlRows += "  a.alias"
$sqlRows += "from alias_seed a"
$sqlRows += "join public.food_catalog fc"
$sqlRows += "  on lower(btrim(fc.food_name)) = lower(btrim(a.food_name))"
$sqlRows += " and coalesce(fc.lang, 'zh-TW') = 'zh-TW'"
$sqlRows += " and coalesce(fc.is_active, true) = true"
$sqlRows += "where not exists ("
$sqlRows += "  select 1"
$sqlRows += "  from public.food_aliases fa"
$sqlRows += "  where fa.food_id = fc.id"
$sqlRows += "    and lower(btrim(fa.lang)) = lower(btrim(a.alias_lang))"
$sqlRows += "    and lower(btrim(fa.alias)) = lower(btrim(a.alias))"
$sqlRows += ");"
$sqlRows += ""
$sqlRows += "commit;"

Set-Content -Path $sqlPath -Value ($sqlRows -join [Environment]::NewLine) -Encoding UTF8

Write-Host ("catalog_rows={0}" -f $catalogRows.Count)
Write-Host ("alias_rows={0}" -f $aliasRows.Count)
Write-Host ("alias_sql={0}" -f $sqlPath)
Write-Host ("catalog_sql={0}" -f $catalogSqlPath)
