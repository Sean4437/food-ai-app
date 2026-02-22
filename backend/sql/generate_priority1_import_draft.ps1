param(
  [string[]]$Priorities = @("1", "2")
)

$ErrorActionPreference = "Stop"

$allRows = Import-Csv "backend/sql/food_names_batch_300_categorized.csv"

$baseByCategory = @{
  "legacy_batch_200" = @{
    protein = 22.0; carbs = 75.0; fat = 20.0; sodium = 1100.0
    summary = "Common local meal."
    suggestion = "Add vegetables and reduce sauce when possible."
  }
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
  "dessert" = @{
    protein = 6.0; carbs = 45.0; fat = 16.0; sodium = 180.0
    summary = "Dessert item."
    suggestion = "Use smaller portions and avoid extra sweet drinks."
  }
  "soup" = @{
    protein = 12.0; carbs = 18.0; fat = 10.0; sodium = 850.0
    summary = "Soup-based dish."
    suggestion = "Watch sodium and pair with lean protein."
  }
  "pasta" = @{
    protein = 20.0; carbs = 65.0; fat = 18.0; sodium = 900.0
    summary = "Pasta-style main dish."
    suggestion = "Choose lighter sauce and add vegetables."
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
  if ($p.carbs -ge 75) { $tags.Add("higher carbs") }
  if ($p.fat -ge 24) { $tags.Add("higher fat") }
  if ($p.sodium -ge 1200) { $tags.Add("higher sodium") }
  if ($p.protein -ge 28) { $tags.Add("good protein") }
  if ($tags.Count -eq 0) { $tags.Add("balanced") }
  return @($tags | Select-Object -Unique | Select-Object -First 3)
}

function Build-Items([string]$category) {
  if ($category -eq "legacy_batch_200") { return @("main ingredient", "carbs", "sauce") }
  if ($category -eq "rice_noodle") { return @("rice/noodle", "protein source", "sauce") }
  if ($category -eq "noodle_soup") { return @("noodle", "broth", "protein source") }
  if ($category -eq "taiwan_snack") { return @("main ingredient", "sauce") }
  if ($category -eq "home_dish") { return @("main dish", "seasoning") }
  if ($category -eq "dessert") { return @("dessert base", "sweetener") }
  if ($category -eq "soup") { return @("broth", "main ingredient") }
  if ($category -eq "pasta") { return @("pasta", "sauce", "protein source") }
  return @("main ingredient")
}

function To-JsonArrayString([object[]]$items) {
  $json = ConvertTo-Json -InputObject @($items) -Compress
  if (-not $json.TrimStart().StartsWith("[")) {
    $json = "[{0}]" -f $json
  }
  return $json
}

function Add-AliasRow(
  [ref]$aliasRows,
  [System.Collections.Generic.HashSet[string]]$aliasSeen,
  [string]$foodName,
  [string]$lang,
  [string]$alias
) {
  if ($null -eq $alias) { return }
  $token = $alias.Trim()
  if ([string]::IsNullOrWhiteSpace($token)) { return }
  if ($token.Length -lt 2) { return }
  if ($token -match "^[\W_]+$") { return }
  $key = ("{0}|{1}|{2}" -f $foodName.Trim(), $lang.Trim(), $token).ToLowerInvariant()
  if (-not $aliasSeen.Add($key)) { return }
  $aliasRows.Value += [PSCustomObject]@{
    food_name = $foodName.Trim()
    lang = $lang.Trim()
    alias = $token
  }
}

function Get-ZhAliasCandidates([string]$foodName) {
  $n = if ($null -eq $foodName) { "" } else { $foodName.Trim() }
  if ([string]::IsNullOrWhiteSpace($n)) { return @() }
  $result = New-Object System.Collections.Generic.List[string]
  $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

  function Add-Local([string]$s, [ref]$resultRef, [System.Collections.Generic.HashSet[string]]$seenRef) {
    if ($null -eq $s) { return }
    $v = $s.Trim()
    if ([string]::IsNullOrWhiteSpace($v)) { return }
    if ($v.Length -lt 2) { return }
    if (-not $seenRef.Add($v)) { return }
    $resultRef.Value.Add($v) > $null
  }

  Add-Local $n ([ref]$result) $seen
  $compact = [regex]::Replace($n, "\s+", "")
  Add-Local $compact ([ref]$result) $seen

  $len = $compact.Length
  if ($len -ge 2) { Add-Local $compact.Substring(0, 2) ([ref]$result) $seen }
  if ($len -ge 3) { Add-Local $compact.Substring(0, 3) ([ref]$result) $seen }
  if ($len -ge 4) { Add-Local $compact.Substring(0, 4) ([ref]$result) $seen }
  if ($len -ge 3) { Add-Local $compact.Substring(0, $len - 1) ([ref]$result) $seen }
  if ($len -ge 4) { Add-Local $compact.Substring(0, $len - 2) ([ref]$result) $seen }
  if ($len -ge 5) { Add-Local $compact.Substring(0, $len - 3) ([ref]$result) $seen }

  return @($result)
}

function Build-CatalogRows([object[]]$srcRows) {
  $rows = @()
  foreach ($row in $srcRows) {
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

    $foodItemsJson = To-JsonArrayString $items
    $tagsJson = To-JsonArrayString $tags
    $macrosJson = ConvertTo-Json -InputObject @{
      protein = $profile.protein
      carbs = $profile.carbs
      fat = $profile.fat
      sodium = $profile.sodium
    } -Compress

    $rows += [PSCustomObject]@{
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
  return @($rows)
}

function Build-AliasRows([object[]]$srcRows) {
  $aliasRows = @()
  $aliasSeen = [System.Collections.Generic.HashSet[string]]::new()

  foreach ($row in $srcRows) {
    $foodName = [string]$row.food_name
    Add-AliasRow ([ref]$aliasRows) $aliasSeen $foodName "zh-TW" $foodName

    foreach ($a in (Get-ZhAliasCandidates $foodName)) {
      Add-AliasRow ([ref]$aliasRows) $aliasSeen $foodName "zh-TW" $a
    }

    Add-AliasRow ([ref]$aliasRows) $aliasSeen $foodName "zh-TW" ([string]$row.alias_zh)
    Add-AliasRow ([ref]$aliasRows) $aliasSeen $foodName "en" ([string]$row.alias_en)
  }

  return @($aliasRows)
}

function Write-CatalogSql([string]$path, [object[]]$catalogRows, [string]$priority) {
  $sql = @()
  $sql += "-- Import priority-$priority foods into public.food_catalog."
  $sql += "-- Safe to run multiple times."
  $sql += "begin;"
  $sql += ""
  $sql += "with seed("
  $sql += "  lang,"
  $sql += "  food_name,"
  $sql += "  canonical_name,"
  $sql += "  calorie_range,"
  $sql += "  macros,"
  $sql += "  food_items,"
  $sql += "  judgement_tags,"
  $sql += "  dish_summary,"
  $sql += "  suggestion,"
  $sql += "  is_beverage,"
  $sql += "  is_food,"
  $sql += "  is_active,"
  $sql += "  source,"
  $sql += "  verified_level,"
  $sql += "  reference_used,"
  $sql += "  beverage_profile"
  $sql += ") as ("
  $sql += "  values"

  $tuples = @()
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
    $tuples += "    ('$lang', '$foodName', '$canonical', '$calorieRange', '$macros'::jsonb, '$foodItems'::jsonb, '$judgementTags'::jsonb, '$summary', '$suggestion', $isBeverage, $isFood, $isActive, '$source', $verifiedLevel, '$referenceUsed', '$beverageProfile'::jsonb)"
  }
  for ($i = 0; $i -lt $tuples.Count; $i++) {
    if ($i -lt ($tuples.Count - 1)) { $sql += ($tuples[$i] + ",") } else { $sql += $tuples[$i] }
  }

  $sql += "),"
  $sql += "updated as ("
  $sql += "  update public.food_catalog fc"
  $sql += "  set"
  $sql += "    canonical_name = s.canonical_name,"
  $sql += "    calorie_range = s.calorie_range,"
  $sql += "    macros = s.macros,"
  $sql += "    food_items = s.food_items,"
  $sql += "    judgement_tags = s.judgement_tags,"
  $sql += "    dish_summary = s.dish_summary,"
  $sql += "    suggestion = s.suggestion,"
  $sql += "    is_beverage = s.is_beverage,"
  $sql += "    is_food = s.is_food,"
  $sql += "    is_active = s.is_active,"
  $sql += "    source = s.source,"
  $sql += "    verified_level = s.verified_level,"
  $sql += "    reference_used = s.reference_used,"
  $sql += "    beverage_profile = s.beverage_profile"
  $sql += "  from seed s"
  $sql += "  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))"
  $sql += "    and coalesce(fc.lang, 'zh-TW') = s.lang"
  $sql += "    and coalesce(fc.is_active, true) = true"
  $sql += "  returning fc.id"
  $sql += ")"
  $sql += "insert into public.food_catalog ("
  $sql += "  lang, food_name, canonical_name, calorie_range, macros, food_items,"
  $sql += "  judgement_tags, dish_summary, suggestion, is_beverage, is_food, is_active,"
  $sql += "  source, verified_level, reference_used, beverage_profile"
  $sql += ")"
  $sql += "select"
  $sql += "  s.lang, s.food_name, s.canonical_name, s.calorie_range, s.macros, s.food_items,"
  $sql += "  s.judgement_tags, s.dish_summary, s.suggestion, s.is_beverage, s.is_food, s.is_active,"
  $sql += "  s.source, s.verified_level, s.reference_used, s.beverage_profile"
  $sql += "from seed s"
  $sql += "where not exists ("
  $sql += "  select 1"
  $sql += "  from public.food_catalog fc"
  $sql += "  where lower(btrim(fc.food_name)) = lower(btrim(s.food_name))"
  $sql += "    and coalesce(fc.lang, 'zh-TW') = s.lang"
  $sql += "    and coalesce(fc.is_active, true) = true"
  $sql += ");"
  $sql += ""
  $sql += "commit;"

  Set-Content -Path $path -Value ($sql -join [Environment]::NewLine) -Encoding UTF8
}

function Write-AliasSql([string]$path, [object[]]$aliasRows, [string]$priority) {
  $sql = @()
  $sql += "-- Import aliases for priority-$priority foods."
  $sql += "-- Run after catalog import."
  $sql += "begin;"
  $sql += ""
  $sql += "with alias_seed(food_name, alias_lang, alias) as ("
  $sql += "  values"

  $tuples = @()
  foreach ($a in $aliasRows) {
    $fn = ([string]$a.food_name).Replace("'", "''")
    $lg = ([string]$a.lang).Replace("'", "''")
    $al = ([string]$a.alias).Replace("'", "''")
    $tuples += "    ('$fn', '$lg', '$al')"
  }
  for ($i = 0; $i -lt $tuples.Count; $i++) {
    if ($i -lt ($tuples.Count - 1)) { $sql += ($tuples[$i] + ",") } else { $sql += $tuples[$i] }
  }

  $sql += ")"
  $sql += "insert into public.food_aliases (food_id, lang, alias)"
  $sql += "select"
  $sql += "  fc.id,"
  $sql += "  a.alias_lang,"
  $sql += "  a.alias"
  $sql += "from alias_seed a"
  $sql += "join public.food_catalog fc"
  $sql += "  on lower(btrim(fc.food_name)) = lower(btrim(a.food_name))"
  $sql += " and coalesce(fc.lang, 'zh-TW') = 'zh-TW'"
  $sql += " and coalesce(fc.is_active, true) = true"
  $sql += "where not exists ("
  $sql += "  select 1"
  $sql += "  from public.food_aliases fa"
  $sql += "  where fa.food_id = fc.id"
  $sql += "    and lower(btrim(fa.lang)) = lower(btrim(a.alias_lang))"
  $sql += "    and lower(btrim(fa.alias)) = lower(btrim(a.alias))"
  $sql += ");"
  $sql += ""
  $sql += "commit;"

  Set-Content -Path $path -Value ($sql -join [Environment]::NewLine) -Encoding UTF8
}

foreach ($priority in $Priorities) {
  $rows = @($allRows | Where-Object { $_.priority -eq $priority })
  if ($rows.Count -eq 0) {
    Write-Host ("skip priority={0} (no rows)" -f $priority)
    continue
  }

  $catalogRows = Build-CatalogRows $rows
  $aliasRows = Build-AliasRows $rows

  $catalogCsv = "backend/sql/food_catalog_priority{0}_import_draft.csv" -f $priority
  $aliasCsv = "backend/sql/food_aliases_priority{0}_import_draft.csv" -f $priority
  $catalogSql = "backend/sql/food_catalog_priority{0}_import.sql" -f $priority
  $aliasSql = "backend/sql/food_aliases_priority{0}_import.sql" -f $priority

  $catalogRows | Export-Csv $catalogCsv -NoTypeInformation -Encoding UTF8
  $aliasRows | Export-Csv $aliasCsv -NoTypeInformation -Encoding UTF8
  Write-CatalogSql $catalogSql $catalogRows $priority
  Write-AliasSql $aliasSql $aliasRows $priority

  Write-Host ("priority={0} catalog_rows={1}" -f $priority, $catalogRows.Count)
  Write-Host ("priority={0} alias_rows={1}" -f $priority, $aliasRows.Count)
  Write-Host ("priority={0} catalog_csv={1}" -f $priority, $catalogCsv)
  Write-Host ("priority={0} alias_csv={1}" -f $priority, $aliasCsv)
  Write-Host ("priority={0} catalog_sql={1}" -f $priority, $catalogSql)
  Write-Host ("priority={0} alias_sql={1}" -f $priority, $aliasSql)
}
