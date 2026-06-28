enum FoodNameSuggestionSource {
  custom,
  catalog,
  beverage,
}

class FoodNameSuggestion {
  const FoodNameSuggestion({
    required this.name,
    required this.source,
    this.customFoodId,
    this.catalogFoodId,
  });

  final String name;
  final FoodNameSuggestionSource source;
  final String? customFoodId;
  final String? catalogFoodId;

  bool get isCustom => source == FoodNameSuggestionSource.custom;
}

class FoodNameInputResult {
  const FoodNameInputResult({
    required this.name,
    this.selectedSuggestion,
  });

  final String name;
  final FoodNameSuggestion? selectedSuggestion;
}
