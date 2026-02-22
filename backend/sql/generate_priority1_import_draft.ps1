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

  [PSCustomObject]@{
    food_name = $foodName
    canonical_name = $foodName
    calorie_range = (Build-Range -protein $profile.protein -carbs $profile.carbs -fat $profile.fat)
    protein_g = $profile.protein
    carbs_g = $profile.carbs
    fat_g = $profile.fat
    sodium_mg = $profile.sodium
    dish_summary = $profile.summary
    suggestion = $profile.suggestion
    food_items_json = $foodItemsJson
    judgement_tags_json = $tagsJson
    is_beverage = "false"
    is_food = "true"
    beverage_base_ml = ""
    beverage_full_sugar_carbs = ""
    beverage_default_sugar_ratio = ""
    beverage_sugar_adjustable = ""
    beverage_profile_json = "{}"
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

Write-Host ("catalog_rows={0}" -f $catalogRows.Count)
Write-Host ("alias_rows={0}" -f $aliasRows.Count)
