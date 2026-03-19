import 'dart:math';

class NameLookupService {
  const NameLookupService._();

  static String normalizeFoodLookupText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String catalogLangFromLocale(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('en')) return 'en';
    return 'zh-TW';
  }

  static double nameSuggestionScore(String value, String normalizedQuery) {
    final normalized = normalizeFoodLookupText(value);
    if (normalized.isEmpty || normalizedQuery.isEmpty) return 0;
    final compact = normalized.replaceAll(' ', '');
    final queryCompact = normalizedQuery.replaceAll(' ', '');
    if (normalized == normalizedQuery || compact == queryCompact) return 10;
    if (normalized.startsWith(normalizedQuery) ||
        compact.startsWith(queryCompact)) {
      return 8;
    }
    if (normalized.contains(normalizedQuery) ||
        compact.contains(queryCompact)) {
      return 6;
    }
    return 0;
  }

  static double catalogMatchScore(Map<String, dynamic> item) {
    final raw = item['match_score'];
    if (raw is num) return raw.toDouble();
    return 0;
  }

  static double catalogSuggestionScore(
    Map<String, dynamic> item,
    String normalizedQuery,
  ) {
    final foodName = (item['food_name'] ?? '').toString();
    final alias = (item['alias'] ?? '').toString();
    final nameScore = max(
      nameSuggestionScore(foodName, normalizedQuery),
      nameSuggestionScore(alias, normalizedQuery),
    );
    return (nameScore * 10) + catalogMatchScore(item);
  }

  static Map<String, dynamic>? bestCatalogFoodMatch(
    String query,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return null;
    final normalizedQuery = normalizeFoodLookupText(query);
    final compactQuery = normalizedQuery.replaceAll(' ', '');

    double containsCoverage(String targetCompact) {
      if (compactQuery.isEmpty || targetCompact.isEmpty) return 0;
      if (compactQuery.length < 2) return 0;
      if (targetCompact.length < 2) return 0;
      if (compactQuery.contains(targetCompact)) {
        return targetCompact.length / compactQuery.length;
      }
      if (targetCompact.contains(compactQuery)) {
        return compactQuery.length / targetCompact.length;
      }
      return 0;
    }

    Map<String, dynamic>? bestPrefix;
    double bestPrefixScore = -1;
    Map<String, dynamic>? bestContains;
    double bestContainsScore = -1;
    double bestContainsCoverage = -1;
    for (final item in items) {
      final alias = normalizeFoodLookupText((item['alias'] as String?) ?? '');
      final foodName =
          normalizeFoodLookupText((item['food_name'] as String?) ?? '');
      final aliasCompact = alias.replaceAll(' ', '');
      final foodCompact = foodName.replaceAll(' ', '');
      final score = catalogMatchScore(item);
      if (alias == normalizedQuery || foodName == normalizedQuery) {
        return item;
      }
      // Prefix matching: supports both "query starts with alias" and
      // "alias starts with query" so type-ahead can catch partial terms.
      final startsWith = (alias.isNotEmpty &&
              (alias.startsWith(normalizedQuery) ||
                  aliasCompact.startsWith(compactQuery) ||
                  normalizedQuery.startsWith(alias) ||
                  compactQuery.startsWith(aliasCompact))) ||
          (foodName.isNotEmpty &&
              (foodName.startsWith(normalizedQuery) ||
                  foodCompact.startsWith(compactQuery) ||
                  normalizedQuery.startsWith(foodName) ||
                  compactQuery.startsWith(foodCompact)));
      if (startsWith && score > bestPrefixScore) {
        bestPrefix = item;
        bestPrefixScore = score;
      }

      final containsLike = (alias.isNotEmpty &&
              (normalizedQuery.contains(alias) ||
                  alias.contains(normalizedQuery) ||
                  compactQuery.contains(aliasCompact) ||
                  aliasCompact.contains(compactQuery))) ||
          (foodName.isNotEmpty &&
              (normalizedQuery.contains(foodName) ||
                  foodName.contains(normalizedQuery) ||
                  compactQuery.contains(foodCompact) ||
                  foodCompact.contains(compactQuery)));
      if (!containsLike) continue;

      final coverage = max(
        containsCoverage(aliasCompact),
        containsCoverage(foodCompact),
      );
      if (coverage <= 0) continue;
      if (coverage > bestContainsCoverage ||
          (coverage == bestContainsCoverage && score > bestContainsScore)) {
        bestContains = item;
        bestContainsScore = score;
        bestContainsCoverage = coverage;
      }
    }
    if (bestPrefix != null && bestPrefixScore >= 3.5) {
      return bestPrefix;
    }
    if (bestContains != null &&
        bestContainsScore >= 5.0 &&
        bestContainsCoverage >= 0.45) {
      return bestContains;
    }
    return null;
  }
}
