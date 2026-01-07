import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import '../models/analysis_result.dart';
import '../models/meal_entry.dart';
import '../services/api_service.dart';
import '../storage/meal_store.dart';
import '../storage/settings_store.dart';

const String kDefaultApiBaseUrl = 'https://sussex-oscar-southern-scanning.trycloudflare.com';
const String kDefaultPlateAsset = 'assets/plates/plate_default.png';

class AppState extends ChangeNotifier {
  AppState()
      : _api = ApiService(baseUrl: _resolveBaseUrl()),
        _store = createMealStore(),
        _settings = createSettingsStore();

  ApiService _api;
  final MealStore _store;
  final SettingsStore _settings;
  final List<MealEntry> entries = [];
  DateTime _selectedDate = _dateOnly(DateTime.now());
  final UserProfile profile = UserProfile.initial();
  final Map<String, Map<String, String>> _dayOverrides = {};
  final Map<String, Map<String, String>> _mealOverrides = {};
  final Map<String, String> _meta = {};
  final Map<String, Timer> _analysisTimers = {};
  final Map<String, bool> _analysisTimerForce = {};
  final Map<String, DateTime> _mealInteractionAt = {};
  Timer? _autoFinalizeTimer;

  String buildAiContext() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recent = entries.where((entry) => entry.time.isAfter(cutoff)).toList();
    if (recent.isEmpty) return '';
    recent.sort((a, b) => b.time.compareTo(a.time));
    final last = recent.first;
    final lastName = last.overrideFoodName ?? last.result?.foodName ?? last.filename;
    final lastSummary = last.result?.dishSummary ?? '';
    final protein = _scoreToLevelPlain(_aggregateMacroScorePlain(recent, 'protein'));
    final carbs = _scoreToLevelPlain(_aggregateMacroScorePlain(recent, 'carbs'));
    final fat = _scoreToLevelPlain(_aggregateMacroScorePlain(recent, 'fat'));
    final sodium = _scoreToLevelPlain(_aggregateMacroScorePlain(recent, 'sodium'));
    return [
      'last_meal_type=${_mealTypeKey(last.type)}',
      'last_meal_name=$lastName',
      if (lastSummary.trim().isNotEmpty) 'last_meal_summary=$lastSummary',
      'recent_7d_macros=protein:$protein, carbs:$carbs, fat:$fat, sodium:$sodium',
      'recent_7d_meal_count=${recent.length}',
    ].join('\n');
  }

  Future<QuickCaptureAnalysis?> analyzeQuickCapture(
    XFile file,
    String locale, {
    String? historyContext,
  }) async {
    final originalBytes = await file.readAsBytes();
    final time = await _resolveImageTime(file, originalBytes);
    final mealType = resolveMealType(time);
    final bytes = _compressImageBytes(originalBytes);
    final filename = file.name.isNotEmpty ? file.name : 'upload.jpg';
    final result = await _api.analyzeImage(
      bytes,
      filename,
      lang: locale,
      context: historyContext,
      mealType: _mealTypeKey(mealType),
      mealPhotoCount: 1,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      age: profile.age,
      goal: profile.goal,
      planSpeed: profile.planSpeed,
      adviceMode: 'current_meal',
    );
    return QuickCaptureAnalysis(
      file: file,
      originalBytes: originalBytes,
      imageBytes: bytes,
      time: time,
      mealType: mealType,
      result: result,
    );
  }

  Future<QuickCaptureAnalysis> reanalyzeQuickCapture(
    QuickCaptureAnalysis analysis,
    String locale, {
    String? historyContext,
    String? foodName,
  }) async {
    final filename = analysis.file.name.isNotEmpty ? analysis.file.name : 'upload.jpg';
    final result = await _api.analyzeImage(
      analysis.imageBytes,
      filename,
      lang: locale,
      context: historyContext,
      foodName: foodName,
      mealType: _mealTypeKey(analysis.mealType),
      mealPhotoCount: 1,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      age: profile.age,
      goal: profile.goal,
      planSpeed: profile.planSpeed,
      adviceMode: 'current_meal',
    );
    return QuickCaptureAnalysis(
      file: analysis.file,
      originalBytes: analysis.originalBytes,
      imageBytes: analysis.imageBytes,
      time: analysis.time,
      mealType: analysis.mealType,
      result: result,
    );
  }

  Future<MealEntry?> saveQuickCapture(
    QuickCaptureAnalysis analysis, {
    String? note,
  }) async {
    final mealId = _assignMealId(analysis.time, analysis.mealType);
    final entry = MealEntry(
      id: _newId(),
      imageBytes: analysis.imageBytes,
      filename: analysis.file.name.isNotEmpty ? analysis.file.name : 'upload.jpg',
      time: analysis.time,
      type: analysis.mealType,
      portionPercent: 100,
      mealId: mealId,
      note: note,
      imageHash: _hashBytes(analysis.originalBytes),
    );
    entry.result = analysis.result;
    entry.lastAnalyzedNote = (note ?? '').trim();
    entry.lastAnalyzedFoodName = entry.overrideFoodName ?? '';
    entries.insert(0, entry);
    markMealInteraction(entry.mealId ?? entry.id);
    _selectedDate = _dateOnly(entry.time);
    notifyListeners();
    await _store.upsert(entry);
    return entry;
  }

  Future<void> init() async {
    await _store.init();
    await _settings.init();
    final profileMap = await _settings.loadProfile();
    if (profileMap != null) {
      _applyProfile(profileMap);
    }
    final overrides = await _settings.loadOverrides();
    if (overrides != null) {
      _loadOverrides(overrides);
    }
    _api = ApiService(baseUrl: profile.apiBaseUrl.isEmpty ? kDefaultApiBaseUrl : profile.apiBaseUrl);
    final loaded = await _store.loadAll();
    entries
      ..clear()
      ..addAll(loaded);
    bool changed = false;
    for (final entry in entries) {
      if (entry.mealId == null || entry.mealId!.isEmpty) {
        entry.mealId = entry.id;
        changed = true;
      }
      if (entry.portionPercent <= 0) {
        entry.portionPercent = 100;
        changed = true;
      }
    }
    if (changed) {
      for (final entry in entries) {
        await _store.upsert(entry);
      }
    }
    _scheduleAutoFinalize();
    notifyListeners();
  }

  MealEntry? get latestEntryAny => entries.isNotEmpty ? entries.first : null;

  DateTime get selectedDate => _selectedDate;

  List<MealEntry> entriesForDate(DateTime date) {
    final target = _dateOnly(date);
    return entries.where((entry) => _isSameDate(entry.time, target)).toList();
  }

  List<MealEntry> get entriesForSelectedDate => entriesForDate(_selectedDate);

  MealEntry? get latestEntryForSelectedDate {
    final list = entriesForSelectedDate;
    return list.isNotEmpty ? list.first : null;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = _dateOnly(date);
    notifyListeners();
  }

  void shiftSelectedDate(int days) {
    setSelectedDate(_selectedDate.add(Duration(days: days)));
  }

  String dailyCalorieRangeLabel(AppLocalizations t) {
    return dailyCalorieRangeLabelForDate(_selectedDate, t);
  }

  String dailyCalorieRangeLabelForDate(DateTime date, AppLocalizations t) {
    return _dailyCalorieRangeLabelForDate(date, t);
  }

  String _dailyCalorieRangeLabelForDate(DateTime date, AppLocalizations t) {
    final summary = buildDaySummary(date, t);
    if (summary != null && summary.calorieRange != t.calorieUnknown) {
      return summary.calorieRange;
    }
    int minSum = 0;
    int maxSum = 0;
    bool hasRange = false;
    final groups = <List<MealEntry>>[
      ...mealGroupsForDate(date, MealType.breakfast),
      ...mealGroupsForDate(date, MealType.lunch),
      ...mealGroupsForDate(date, MealType.dinner),
      ...mealGroupsForDate(date, MealType.lateSnack),
      ...mealGroupsForDate(date, MealType.other),
    ];
    for (final group in groups) {
      final summary = buildMealSummary(group, t);
      if (summary == null) continue;
      final range = _parseCalorieRange(summary.calorieRange);
      if (range == null) continue;
      minSum += range[0];
      maxSum += range[1];
      hasRange = true;
    }
    return hasRange ? '$minSum-$maxSum kcal' : t.calorieUnknown;
  }

  String todayStatusLabel(AppLocalizations t) {
    final entry = latestEntryForSelectedDate;
    if (entry == null || entry.result == null) return t.suggestTodayHint;
    final fat = entry.result!.macros['fat'] ?? '';
    final carbs = entry.result!.macros['carbs'] ?? '';
    final oily = fat.contains(t.levelHigh) || fat.toLowerCase().contains('high');
    final carbHigh = carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high');
    if (oily && carbHigh) return t.suggestTodayOilyCarb;
    if (oily) return t.suggestTodayOily;
    if (carbHigh) return t.suggestTodayCarb;
    return t.suggestTodayOk;
  }

  String todaySummary(AppLocalizations t) {
    final entry = latestEntryForSelectedDate;
    if (entry == null || entry.result == null) return t.summaryEmpty;
    final fat = entry.result!.macros['fat'] ?? '';
    final protein = entry.result!.macros['protein'] ?? '';
    final carbs = entry.result!.macros['carbs'] ?? '';
    final oily = fat.contains(t.levelHigh) || fat.toLowerCase().contains('high');
    final proteinOk = protein.contains(t.levelMedium) ||
        protein.contains(t.levelHigh) ||
        protein.toLowerCase().contains('medium') ||
        protein.toLowerCase().contains('high');
    final carbHigh = carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high');
    if (oily && carbHigh) return t.summaryOilyCarb;
    if (oily) return t.summaryOily;
    if (carbHigh) return t.summaryCarb;
    if (proteinOk) return t.summaryProteinOk;
    return t.summaryNeutral;
  }

  String daySummaryText(DateTime date, AppLocalizations t) {
    final override = _dayOverrides[_dayKey(date)];
    final manual = override?['summary'];
    if (manual != null && manual.trim().isNotEmpty) return manual;
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return t.summaryEmpty;
    final fatScore = _aggregateMacroScore(dayEntries, 'fat', t);
    final carbScore = _aggregateMacroScore(dayEntries, 'carbs', t);
    final proteinScore = _aggregateMacroScore(dayEntries, 'protein', t);
    final oily = fatScore >= 2.4;
    final carbHigh = carbScore >= 2.4;
    final proteinOk = proteinScore >= 2.0;
    if (oily && carbHigh) return t.summaryOilyCarb;
    if (oily) return t.summaryOily;
    if (carbHigh) return t.summaryCarb;
    if (proteinOk) return t.summaryProteinOk;
    return t.summaryNeutral;
  }

  String dayTomorrowAdvice(DateTime date, AppLocalizations t) {
    final override = _dayOverrides[_dayKey(date)];
    final manual = override?['tomorrow_advice'];
    if (manual != null && manual.trim().isNotEmpty) return manual;
    final summary = buildDaySummary(date, t);
    return summary?.advice ?? t.nextMealHint;
  }

  Future<void> finalizeDay(DateTime date, String locale, AppLocalizations t) async {
    final groups = mealGroupsForDateAll(date);
    if (groups.isEmpty) return;
    final meals = <Map<String, dynamic>>[];
    for (final group in groups) {
      final summary = buildMealSummary(group, t);
      final dishSummaries = <String>[];
      for (final entry in group) {
        final summaryText = entry.result?.dishSummary?.trim();
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
          continue;
        }
        final fallback = entry.overrideFoodName ?? entry.result?.foodName ?? '';
        if (fallback.isNotEmpty) {
          dishSummaries.add(fallback);
        }
      }
      meals.add({
        'meal_type': _mealTypeKey(group.first.type),
        'calorie_range': summary?.calorieRange ?? '',
        'dish_summaries': dishSummaries,
      });
    }
    final payload = {
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'lang': locale,
      'meals': meals,
      'profile': {
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'age': profile.age,
        'goal': profile.goal,
        'plan_speed': profile.planSpeed,
      },
    };
    try {
      final response = await _api.summarizeDay(payload);
      final summaryText = (response['day_summary'] as String?) ?? '';
      final adviceText = (response['tomorrow_advice'] as String?) ?? '';
      await updateDayOverride(
        date,
        summary: summaryText,
        tomorrowAdvice: adviceText,
      );
    } catch (_) {
      // Keep existing summary if summarize fails
    }
  }

  Future<void> autoFinalizeToday() async {
    final locale = _localeFromProfile();
    final t = lookupAppLocalizations(locale);
    final todayKey = _dayKey(DateTime.now());
    if (_meta['last_auto_finalize'] == todayKey) {
      _scheduleAutoFinalize();
      return;
    }
    await finalizeDay(DateTime.now(), locale.toLanguageTag(), t);
    _meta['last_auto_finalize'] = todayKey;
    await _saveOverrides();
    _scheduleAutoFinalize();
  }

  String dayMealLabels(DateTime date, AppLocalizations t) {
    final groups = mealGroupsForDateAll(date);
    if (groups.isEmpty) return t.mealCountEmpty;
    final types = <MealType>{};
    for (final group in groups) {
      if (group.isNotEmpty) {
        types.add(group.first.type);
      }
    }
    final labels = <String>[];
    for (final type in MealType.values) {
      if (!types.contains(type)) continue;
      labels.add(_mealTypeLabel(type, t));
    }
    return labels.join('、');
  }

  MealAdvice mealAdviceForGroup(List<MealEntry> group, AppLocalizations t) {
    if (group.isEmpty) return MealAdvice.defaults(t);
    final key = _mealKey(group.first.mealId ?? group.first.id);
    final override = _mealOverrides[key];
    if (override == null) return MealAdvice.defaults(t);
    return MealAdvice(
      selfCook: override['self_cook'] ?? t.nextSelfCookHint,
      convenience: override['convenience'] ?? t.nextConvenienceHint,
      bento: override['bento'] ?? t.nextBentoHint,
      other: override['other'] ?? t.nextOtherHint,
    );
  }

  Future<void> updateDayOverride(DateTime date, {String? summary, String? tomorrowAdvice}) async {
    final key = _dayKey(date);
    _dayOverrides.putIfAbsent(key, () => {});
    if (summary != null) {
      final value = summary.trim();
      if (value.isEmpty) {
        _dayOverrides[key]!.remove('summary');
      } else {
        _dayOverrides[key]!['summary'] = value;
      }
    }
    if (tomorrowAdvice != null) {
      final value = tomorrowAdvice.trim();
      if (value.isEmpty) {
        _dayOverrides[key]!.remove('tomorrow_advice');
      } else {
        _dayOverrides[key]!['tomorrow_advice'] = value;
      }
    }
    if (_dayOverrides[key]!.isEmpty) {
      _dayOverrides.remove(key);
    }
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> updateMealAdvice(String mealId, MealAdvice advice) async {
    final key = _mealKey(mealId);
    _mealOverrides[key] = {
      'self_cook': advice.selfCook.trim(),
      'convenience': advice.convenience.trim(),
      'bento': advice.bento.trim(),
      'other': advice.other.trim(),
    };
    markMealInteraction(mealId);
    notifyListeners();
    await _saveOverrides();
    final locale = profile.language;
    for (final entry in entriesForMealId(mealId)) {
      _scheduleAnalyze(entry, locale, force: true);
    }
  }

  static String _resolveBaseUrl() {
    return kDefaultApiBaseUrl;
  }

  void updateApiBaseUrl(String url) {
    _api = ApiService(baseUrl: url);
    notifyListeners();
  }

  MealType resolveMealType(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour <= 10) return MealType.breakfast;
    if (hour >= 11 && hour <= 14) return MealType.lunch;
    if (hour >= 17 && hour <= 20) return MealType.dinner;
    if (hour >= 21 || hour <= 2) return MealType.lateSnack;
    return MealType.other;
  }

  void markMealInteraction(String mealId) {
    _mealInteractionAt[mealId] = DateTime.now();
  }

  DateTime? mealInteractionAt(String mealId) => _mealInteractionAt[mealId];

  String _mealTypeKey(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.lunch:
        return 'lunch';
      case MealType.dinner:
        return 'dinner';
      case MealType.lateSnack:
        return 'late_snack';
      case MealType.other:
        return 'other';
    }
  }

  String _mealTypeLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.lunch:
        return t.lunch;
      case MealType.dinner:
        return t.dinner;
      case MealType.lateSnack:
        return t.lateSnack;
      case MealType.other:
        return t.other;
    }
  }

  String _assignMealId(DateTime time, MealType type) {
    final targetDate = _dateOnly(time);
    Duration? bestDiff;
    String? bestId;
    for (final entry in entries) {
      if (entry.type != type) continue;
      if (!_isSameDate(entry.time, targetDate)) continue;
      final diff = (entry.time.difference(time)).abs();
      if (diff > const Duration(hours: 2)) continue;
      if (bestDiff == null || diff < bestDiff) {
        bestDiff = diff;
        bestId = entry.mealId;
      }
    }
    return bestId ?? _newId();
  }

  List<List<MealEntry>> mealGroupsForDate(DateTime date, MealType type) {
    final target = _dateOnly(date);
    final groups = <String, List<MealEntry>>{};
    for (final entry in entries) {
      if (entry.type != type) continue;
      if (!_isSameDate(entry.time, target)) continue;
      final key = entry.mealId ?? entry.id;
      groups.putIfAbsent(key, () => []).add(entry);
    }
    final result = groups.values.toList();
    for (final group in result) {
      group.sort((a, b) => b.time.compareTo(a.time));
    }
    result.sort((a, b) => a.first.time.compareTo(b.first.time));
    return result.reversed.toList();
  }

  List<List<MealEntry>> mealGroupsForDateAll(DateTime date) {
    final target = _dateOnly(date);
    final groups = <String, List<MealEntry>>{};
    for (final entry in entries) {
      if (!_isSameDate(entry.time, target)) continue;
      final key = entry.mealId ?? entry.id;
      groups.putIfAbsent(key, () => []).add(entry);
    }
    final result = groups.values.toList();
    for (final group in result) {
      group.sort((a, b) => b.time.compareTo(a.time));
    }
    result.sort((a, b) => a.first.time.compareTo(b.first.time));
    return result.reversed.toList();
  }

  List<MealEntry> entriesForMeal(MealEntry entry) {
    final key = entry.mealId ?? entry.id;
    return entries.where((e) => (e.mealId ?? e.id) == key).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  List<MealEntry> entriesForMealId(String mealId) {
    return entries.where((e) => (e.mealId ?? e.id) == mealId).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  MealSummary? buildMealSummary(List<MealEntry> group, AppLocalizations t) {
    double totalWeight = 0;
    double minSum = 0;
    double maxSum = 0;
    double proteinScore = 0;
    double carbScore = 0;
    double fatScore = 0;
    double sodiumScore = 0;

    for (final entry in group) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _portionWeight(entry.portionPercent);
      totalWeight += weight;
      final range = _parseCalorieRange(result.calorieRange);
      if (range != null) {
        minSum += range[0] * weight;
        maxSum += range[1] * weight;
      }
      proteinScore += _levelScore(result.macros['protein'] ?? '', t) * weight;
      carbScore += _levelScore(result.macros['carbs'] ?? '', t) * weight;
      fatScore += _levelScore(result.macros['fat'] ?? '', t) * weight;
      sodiumScore += _levelScore(result.macros['sodium'] ?? '', t) * weight;
    }

    if (totalWeight == 0) return null;
    final macros = <String, String>{
      'protein': _scoreToLevel(proteinScore / totalWeight, t),
      'carbs': _scoreToLevel(carbScore / totalWeight, t),
      'fat': _scoreToLevel(fatScore / totalWeight, t),
      'sodium': _scoreToLevel(sodiumScore / totalWeight, t),
    };
    final dishSummary = _buildMealDishSummary(group);
    final advice = dishSummary.isNotEmpty ? dishSummary : _buildMealAdvice(macros, t);
    final calorieRange = minSum > 0 && maxSum > 0 ? '${minSum.round()}-${maxSum.round()} kcal' : t.calorieUnknown;
    return MealSummary(calorieRange: calorieRange, macros: macros, advice: advice);
  }

  MealSummary? buildDaySummary(DateTime date, AppLocalizations t) {
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return null;
    double totalWeight = 0;
    double minSum = 0;
    double maxSum = 0;
    double proteinScore = 0;
    double carbScore = 0;
    double fatScore = 0;
    double sodiumScore = 0;

    for (final entry in dayEntries) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _portionWeight(entry.portionPercent);
      totalWeight += weight;
      final range = _parseCalorieRange(result.calorieRange);
      if (range != null) {
        minSum += range[0] * weight;
        maxSum += range[1] * weight;
      }
      proteinScore += _levelScore(result.macros['protein'] ?? '', t) * weight;
      carbScore += _levelScore(result.macros['carbs'] ?? '', t) * weight;
      fatScore += _levelScore(result.macros['fat'] ?? '', t) * weight;
      sodiumScore += _levelScore(result.macros['sodium'] ?? '', t) * weight;
    }

    if (totalWeight == 0) return null;
    final macros = <String, String>{
      'protein': _scoreToLevel(proteinScore / totalWeight, t),
      'carbs': _scoreToLevel(carbScore / totalWeight, t),
      'fat': _scoreToLevel(fatScore / totalWeight, t),
      'sodium': _scoreToLevel(sodiumScore / totalWeight, t),
    };
    final advice = _buildMealAdvice(macros, t);
    final calorieRange = minSum > 0 && maxSum > 0 ? '${minSum.round()}-${maxSum.round()} kcal' : t.calorieUnknown;
    return MealSummary(calorieRange: calorieRange, macros: macros, advice: advice);
  }

  Future<MealEntry?> addEntryFromFiles(
    List<XFile> files,
    String locale, {
    String? note,
    MealType? fixedType,
  }) async {
    if (files.isEmpty) return null;
    if (files.length == 1) {
      return addEntry(files.first, locale, note: note, fixedType: fixedType);
    }
    final List<MealEntry> created = [];
    DateTime? anchorTime;
    final List<Uint8List> collageBytes = [];
    for (final file in files) {
      final originalBytes = await file.readAsBytes();
      final time = await _resolveImageTime(file, originalBytes);
      anchorTime ??= time;
      final bytes = _compressImageBytes(originalBytes);
      collageBytes.add(bytes);
      final filename = file.name.isNotEmpty ? file.name : 'upload.jpg';
      final mealType = fixedType ?? resolveMealType(time);
      final mealId = fixedType != null ? _assignMealId(time, fixedType) : _assignMealId(time, mealType);
      final entry = MealEntry(
        id: _newId(),
        imageBytes: bytes,
        filename: filename,
        time: time,
        type: mealType,
        portionPercent: 100,
        mealId: mealId,
        note: note,
        imageHash: _hashBytes(originalBytes),
      );
      created.add(entry);
      entries.insert(0, entry);
      markMealInteraction(entry.mealId ?? entry.id);
    }
    if (anchorTime != null) {
      _selectedDate = _dateOnly(anchorTime);
    }
    notifyListeners();
    for (final entry in created) {
      await _store.upsert(entry);
    }
    if (created.isNotEmpty) {
      await _analyzeMealGroup(created.first.mealId ?? created.first.id, locale, imagesOverride: collageBytes);
    }
    return created.isNotEmpty ? created.first : null;
  }

  Future<MealEntry?> addEntry(
    XFile xfile,
    String locale, {
    String? note,
    MealType? fixedType,
  }) async {
    final originalBytes = await xfile.readAsBytes();
    final time = await _resolveImageTime(xfile, originalBytes);
    final bytes = _compressImageBytes(originalBytes);
    final filename = xfile.name.isNotEmpty ? xfile.name : 'upload.jpg';
    final imageHash = _hashBytes(originalBytes);
    final mealType = fixedType ?? resolveMealType(time);
    final mealId = _assignMealId(time, mealType);
    final entry = MealEntry(
      id: _newId(),
      imageBytes: bytes,
      filename: filename,
      time: time,
      type: mealType,
      portionPercent: 100,
      mealId: mealId,
      note: note,
      imageHash: imageHash,
    );
    entries.insert(0, entry);
    markMealInteraction(entry.mealId ?? entry.id);
    _selectedDate = _dateOnly(entry.time);
    notifyListeners();
    await _store.upsert(entry);
    final anchor = _findMealAnchor(entry);
    if (anchor != null && anchor.result != null) {
      entry.result = anchor.result;
      entry.error = null;
      entry.lastAnalyzedNote = anchor.lastAnalyzedNote;
      entry.lastAnalyzedFoodName = anchor.lastAnalyzedFoodName;
      await _store.upsert(entry);
      notifyListeners();
      return entry;
    }
    await _analyzeEntry(entry, locale);
    return entry;
  }

  Future<void> updateEntryNote(MealEntry entry, String note, String locale) async {
    entry.note = note.trim().isEmpty ? null : note.trim();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    await _store.upsert(entry);
    _scheduleAnalyze(entry, locale);
  }

  void updateEntryTime(MealEntry entry, DateTime time) {
    entry.time = time;
    entry.type = resolveMealType(time);
    entry.mealId = _assignMealId(time, entry.type);
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    _store.upsert(entry);
  }

  void updateEntryPortionPercent(MealEntry entry, int percent) {
    entry.portionPercent = percent.clamp(10, 100);
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    _store.upsert(entry);
    _scheduleAnalyze(entry, profile.language, force: true);
  }

  Future<String> exportData() async {
    return _store.exportJson();
  }

  Future<void> clearAll() async {
    entries.clear();
    notifyListeners();
    await _store.clearAll();
  }

  Future<void> updateEntryFoodName(MealEntry entry, String foodName, String locale) async {
    entry.overrideFoodName = foodName.trim().isEmpty ? null : foodName.trim();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    await _store.upsert(entry);
    _scheduleAnalyze(entry, locale);
  }

  void removeEntry(MealEntry entry) {
    entries.remove(entry);
    notifyListeners();
    _store.delete(entry.id);
  }

  void updateProfile(UserProfile updated) {
    profile
      ..name = updated.name
      ..email = updated.email
      ..heightCm = updated.heightCm
      ..weightKg = updated.weightKg
      ..age = updated.age
      ..goal = updated.goal
      ..planSpeed = updated.planSpeed
      ..lunchReminderEnabled = updated.lunchReminderEnabled
      ..dinnerReminderEnabled = updated.dinnerReminderEnabled
      ..lunchReminderTime = updated.lunchReminderTime
      ..dinnerReminderTime = updated.dinnerReminderTime
      ..language = updated.language
      ..apiBaseUrl = updated.apiBaseUrl
      ..plateAsset = updated.plateAsset
      ..nutritionChartStyle = updated.nutritionChartStyle;
    notifyListeners();
    // ignore: unawaited_futures
    _saveProfile();
  }

  void updateField(void Function(UserProfile profile) updater) {
    updater(profile);
    notifyListeners();
    // ignore: unawaited_futures
    _saveProfile();
  }

  Future<void> _analyzeEntry(MealEntry entry, String locale, {bool force = false}) async {
    final noteKey = entry.note ?? '';
    final nameKey = entry.overrideFoodName ?? '';
    if (!force &&
        entry.result != null &&
        entry.lastAnalyzedNote == noteKey &&
        entry.lastAnalyzedFoodName == nameKey) {
      return;
    }
    entry.loading = true;
    entry.error = null;
    entry.result = null;
    notifyListeners();

    try {
      final mealTypeKey = _mealTypeKey(entry.type);
      final mealId = entry.mealId ?? entry.id;
      final mealPhotoCount = entriesForMealId(mealId).length;
      final AnalysisResult res = await _api.analyzeImage(
        entry.imageBytes,
        entry.filename,
        lang: locale,
        foodName: entry.overrideFoodName,
        note: entry.note,
        portionPercent: entry.portionPercent,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        age: profile.age,
        goal: profile.goal,
        planSpeed: profile.planSpeed,
        mealType: mealTypeKey,
        mealPhotoCount: mealPhotoCount,
      );
      entry.result = res;
      entry.lastAnalyzedNote = noteKey;
      entry.lastAnalyzedFoodName = nameKey;
    } catch (e) {
      entry.error = e.toString();
    } finally {
      entry.loading = false;
      notifyListeners();
      await _store.upsert(entry);
    }
  }

  Future<DateTime> _resolveImageTime(XFile xfile, List<int> bytes) async {
    final exifTime = await _extractExifTime(bytes);
    if (exifTime != null) return exifTime;
    final filenameTime = _parseFilenameDate(xfile.name);
    if (filenameTime != null) return filenameTime;
    try {
      final lastModified = await xfile.lastModified();
      return lastModified;
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<DateTime?> _extractExifTime(List<int> bytes) async {
    try {
      final data = await readExifFromBytes(bytes);
      final candidates = [
        'EXIF DateTimeOriginal',
        'EXIF DateTimeDigitized',
        'Image DateTime',
      ];
      for (final key in candidates) {
        final tag = data[key];
        if (tag == null) continue;
        final parsed = _parseExifDate(tag.printable);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      // Ignore EXIF errors and fallback to file time.
    }
    return null;
  }

  DateTime? _parseFilenameDate(String filename) {
    final match = RegExp(r'(20\\d{2})[-_]?([01]\\d)[-_]?([0-3]\\d)').firstMatch(filename);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if ([year, month, day].any((v) => v == null)) return null;
    return DateTime(year!, month!, day!);
  }

  Uint8List _compressImageBytes(List<int> bytes) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return Uint8List.fromList(bytes);
    final maxDim = decoded.width > decoded.height ? decoded.width : decoded.height;
    final scale = maxDim > 1024 ? 1024 / maxDim : 1.0;
    final targetWidth = (decoded.width * scale).round();
    final targetHeight = (decoded.height * scale).round();
    final resized = scale < 1.0 ? img.copyResize(decoded, width: targetWidth, height: targetHeight) : decoded;
    final jpg = img.encodeJpg(resized, quality: 70);
    return Uint8List.fromList(jpg);
  }

  void _scheduleAnalyze(MealEntry entry, String locale, {bool force = false}) {
    final key = entry.mealId ?? entry.id;
    _analysisTimers[key]?.cancel();
    if (force) {
      _analysisTimerForce[key] = true;
    }
    _analysisTimers[key] = Timer(const Duration(minutes: 1), () {
      final doForce = _analysisTimerForce.remove(key) ?? false;
      _analysisTimers.remove(key);
      // ignore: discarded_futures
      _analyzeMealGroup(key, locale, force: doForce);
    });
  }

  Future<void> _analyzeMealGroup(
    String mealId,
    String locale, {
    List<Uint8List>? imagesOverride,
    bool force = false,
  }) async {
    final group = entriesForMealId(mealId);
    if (group.isEmpty) return;
    final mealTypeKey = _mealTypeKey(group.first.type);
    final mealPhotoCount = group.length;
    final bytesList = imagesOverride ?? group.map((e) => e.imageBytes).toList();
    final collageBytes = _buildCollageBytes(bytesList);
    final filename = 'meal-collage.jpg';
    final notes = group.map((e) => e.note).whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final note = notes.isEmpty ? null : notes.join(' / ');
    final overrides = group.map((e) => e.overrideFoodName).whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final foodName = overrides.length == 1 ? overrides.first : null;
    final portion = (group.map((e) => e.portionPercent).reduce((a, b) => a + b) / group.length).round();

    for (final entry in group) {
      final noteKey = entry.note ?? '';
      final nameKey = entry.overrideFoodName ?? '';
      if (!force &&
          entry.result != null &&
          entry.lastAnalyzedNote == noteKey &&
          entry.lastAnalyzedFoodName == nameKey) {
        continue;
      }
      entry.loading = true;
      entry.error = null;
    }
    notifyListeners();

    try {
      final AnalysisResult res = await _api.analyzeImage(
        collageBytes,
        filename,
        lang: locale,
        foodName: foodName,
        note: note,
        portionPercent: portion,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        age: profile.age,
        goal: profile.goal,
        planSpeed: profile.planSpeed,
        mealType: mealTypeKey,
        mealPhotoCount: mealPhotoCount,
      );
      for (final entry in group) {
        entry.result = res;
        entry.lastAnalyzedNote = entry.note ?? '';
        entry.lastAnalyzedFoodName = entry.overrideFoodName ?? '';
        entry.loading = false;
        entry.error = null;
        await _store.upsert(entry);
      }
    } catch (e) {
      for (final entry in group) {
        entry.loading = false;
        entry.error = e.toString();
        await _store.upsert(entry);
      }
    } finally {
      notifyListeners();
    }
  }

  Uint8List _buildCollageBytes(List<Uint8List> originals) {
    if (originals.isEmpty) return Uint8List(0);
    final decoded = <img.Image>[];
    for (final bytes in originals) {
      final image = img.decodeImage(bytes);
      if (image != null) {
        decoded.add(image);
      }
      if (decoded.length >= 4) break;
    }
    if (decoded.isEmpty) {
      return _compressImageBytes(originals.first);
    }

    const int canvasSize = 1024;
    const int grid = 2;
    final int cellSize = canvasSize ~/ grid;
    final canvas = img.Image(width: canvasSize, height: canvasSize);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    for (var index = 0; index < decoded.length; index++) {
      final image = decoded[index];
      final resized = img.copyResize(
        image,
        width: cellSize,
        height: cellSize,
        interpolation: img.Interpolation.average,
      );
      final dx = (index % grid) * cellSize;
      final dy = (index ~/ grid) * cellSize;
      img.compositeImage(canvas, resized, dstX: dx, dstY: dy);
    }

    final jpg = img.encodeJpg(canvas, quality: 70);
    return Uint8List.fromList(jpg);
  }

  String _hashBytes(List<int> bytes) {
    return sha1.convert(bytes).toString();
  }

  double _aggregateMacroScore(List<MealEntry> dayEntries, String key, AppLocalizations t) {
    double totalWeight = 0;
    double score = 0;
    for (final entry in dayEntries) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _portionWeight(entry.portionPercent);
      totalWeight += weight;
      score += _levelScore(result.macros[key] ?? '', t) * weight;
    }
    if (totalWeight == 0) return 0;
    return score / totalWeight;
  }

  double _aggregateMacroScorePlain(List<MealEntry> dayEntries, String key) {
    double totalWeight = 0;
    double score = 0;
    for (final entry in dayEntries) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _portionWeight(entry.portionPercent);
      totalWeight += weight;
      score += _levelScorePlain(result.macros[key] ?? '') * weight;
    }
    if (totalWeight == 0) return 0;
    return score / totalWeight;
  }

  MealEntry? _findMealAnchor(MealEntry entry) {
    for (final existing in entries) {
      if (existing.id == entry.id) continue;
      if (existing.imageHash != null && existing.imageHash == entry.imageHash && existing.result != null) {
        return existing;
      }
    }
    return null;
  }

  DateTime? _parseExifDate(String value) {
    final match = RegExp(r'(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})').firstMatch(value);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    final second = int.tryParse(match.group(6)!);
    if ([year, month, day, hour, minute, second].any((v) => v == null)) return null;
    return DateTime(year!, month!, day!, hour!, minute!, second!);
  }

  static DateTime _dateOnly(DateTime time) {
    return DateTime(time.year, time.month, time.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<int>? _parseCalorieRange(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(value);
    if (match == null) return null;
    final minVal = int.tryParse(match.group(1)!);
    final maxVal = int.tryParse(match.group(2)!);
    if (minVal == null || maxVal == null) return null;
    return [minVal, maxVal];
  }

  double _portionWeight(int percent) {
    final safe = percent.clamp(10, 100);
    return safe / 100.0;
  }

  double _levelScore(String value, AppLocalizations t) {
    final lower = value.toLowerCase();
    if (lower.contains(t.levelHigh) || lower.contains('high')) return 3.0;
    if (lower.contains(t.levelLow) || lower.contains('low')) return 1.0;
    return 2.0;
  }

  double _levelScorePlain(String value) {
    final lower = value.toLowerCase();
    if (value.contains('高') || lower.contains('high')) return 3.0;
    if (value.contains('低') || lower.contains('low')) return 1.0;
    return 2.0;
  }

  String _scoreToLevel(double score, AppLocalizations t) {
    if (score <= 1.6) return t.levelLow;
    if (score >= 2.4) return t.levelHigh;
    return t.levelMedium;
  }

  String _scoreToLevelPlain(double score) {
    if (score <= 1.6) return 'low';
    if (score >= 2.4) return 'high';
    return 'medium';
  }

  String _buildMealAdvice(Map<String, String> macros, AppLocalizations t) {
    final advice = <String>[];
    final protein = macros['protein'] ?? '';
    final fat = macros['fat'] ?? '';
    final carbs = macros['carbs'] ?? '';
    final sodium = macros['sodium'] ?? '';
    if (protein.contains(t.levelLow) || protein.toLowerCase().contains('low')) advice.add(t.dietitianProteinLow);
    if (fat.contains(t.levelHigh) || fat.toLowerCase().contains('high')) advice.add(t.dietitianFatHigh);
    if (carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high')) advice.add(t.dietitianCarbHigh);
    if (sodium.contains(t.levelHigh) || sodium.toLowerCase().contains('high')) advice.add(t.dietitianSodiumHigh);
    final line = advice.isEmpty ? t.dietitianBalanced : advice.take(2).join('、');
    final goalLower = profile.goal.toLowerCase();
    final loseFat = profile.goal == t.goalLoseFat ||
        goalLower.contains('減脂') ||
        goalLower.contains('lose');
    final goalHint = loseFat ? t.goalAdviceLoseFat : t.goalAdviceMaintain;
    return '${t.dietitianPrefix}$line ${goalHint}';
  }

  String _buildMealDishSummary(List<MealEntry> group) {
    final summaries = <String>{};
    for (final entry in group) {
      final text = entry.result?.dishSummary?.trim();
      if (text == null || text.isEmpty) continue;
      summaries.add(text);
    }
    if (summaries.isEmpty) return '';
    return summaries.take(2).join('、');
  }

  String _newId() {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 31);
    return '$seed-$rand';
  }

  String _dayKey(DateTime date) {
    final d = _dateOnly(date);
    return 'day:${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _mealKey(String mealId) => 'meal:$mealId';

  void _loadOverrides(Map<String, dynamic> overrides) {
    final day = overrides['day'] as Map<String, dynamic>?;
    final meal = overrides['meal'] as Map<String, dynamic>?;
    final meta = overrides['meta'] as Map<String, dynamic>?;
    if (day != null) {
      day.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _dayOverrides[key] = value.map((k, v) => MapEntry(k, v.toString()));
        }
      });
    }
    if (meal != null) {
      meal.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _mealOverrides[key] = value.map((k, v) => MapEntry(k, v.toString()));
        }
      });
    }
    if (meta != null) {
      meta.forEach((key, value) {
        _meta[key] = value.toString();
      });
    }
  }

  Future<void> _saveOverrides() async {
    await _settings.saveOverrides({
      'day': _dayOverrides,
      'meal': _mealOverrides,
      'meta': _meta,
    });
  }

  Locale _localeFromProfile() {
    return profile.language == 'en' ? const Locale('en') : const Locale('zh', 'TW');
  }

  void _scheduleAutoFinalize() {
    _autoFinalizeTimer?.cancel();
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, 21, 0);
    final next = now.isAfter(target) ? target.add(const Duration(days: 1)) : target;
    final delay = next.difference(now);
    _autoFinalizeTimer = Timer(delay, () {
      // ignore: discarded_futures
      autoFinalizeToday();
    });
  }

  Future<void> _saveProfile() async {
    await _settings.saveProfile(_profileToMap());
  }

  Map<String, dynamic> _profileToMap() {
    return {
      'name': profile.name,
      'email': profile.email,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'age': profile.age,
      'goal': profile.goal,
      'plan_speed': profile.planSpeed,
      'lunch_reminder_enabled': profile.lunchReminderEnabled,
      'dinner_reminder_enabled': profile.dinnerReminderEnabled,
      'lunch_reminder_time': _timeToString(profile.lunchReminderTime),
      'dinner_reminder_time': _timeToString(profile.dinnerReminderTime),
      'language': profile.language,
      'api_base_url': profile.apiBaseUrl,
      'plate_asset': profile.plateAsset,
      'nutrition_chart': profile.nutritionChartStyle,
    };
  }

  void _applyProfile(Map<String, dynamic> data) {
    profile
      ..name = (data['name'] as String?) ?? profile.name
      ..email = (data['email'] as String?) ?? profile.email
      ..heightCm = _parseInt(data['height_cm'], profile.heightCm)
      ..weightKg = _parseInt(data['weight_kg'], profile.weightKg)
      ..age = _parseInt(data['age'], profile.age)
      ..goal = (data['goal'] as String?) ?? profile.goal
      ..planSpeed = (data['plan_speed'] as String?) ?? profile.planSpeed
      ..lunchReminderEnabled = (data['lunch_reminder_enabled'] as bool?) ?? profile.lunchReminderEnabled
      ..dinnerReminderEnabled = (data['dinner_reminder_enabled'] as bool?) ?? profile.dinnerReminderEnabled
      ..lunchReminderTime = _parseTime(data['lunch_reminder_time'] as String?, profile.lunchReminderTime)
      ..dinnerReminderTime = _parseTime(data['dinner_reminder_time'] as String?, profile.dinnerReminderTime)
      ..language = (data['language'] as String?) ?? profile.language
      ..apiBaseUrl = (data['api_base_url'] as String?) ?? profile.apiBaseUrl
      ..plateAsset = (data['plate_asset'] as String?) ?? profile.plateAsset
      ..nutritionChartStyle = (data['nutrition_chart'] as String?) ?? profile.nutritionChartStyle;
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  String _timeToString(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _parseTime(String? value, TimeOfDay fallback) {
    if (value == null || !value.contains(':')) return fallback;
    final parts = value.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (hour == null || minute == null) return fallback;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

class MealSummary {
  MealSummary({
    required this.calorieRange,
    required this.macros,
    required this.advice,
  });

  final String calorieRange;
  final Map<String, String> macros;
  final String advice;
}

class MealAdvice {
  MealAdvice({
    required this.selfCook,
    required this.convenience,
    required this.bento,
    required this.other,
  });

  final String selfCook;
  final String convenience;
  final String bento;
  final String other;

  static MealAdvice defaults(AppLocalizations t) {
    return MealAdvice(
      selfCook: t.nextSelfCookHint,
      convenience: t.nextConvenienceHint,
      bento: t.nextBentoHint,
      other: t.nextOtherHint,
    );
  }
}

class QuickCaptureAnalysis {
  QuickCaptureAnalysis({
    required this.file,
    required this.originalBytes,
    required this.imageBytes,
    required this.time,
    required this.mealType,
    required this.result,
  });

  final XFile file;
  final List<int> originalBytes;
  final Uint8List imageBytes;
  final DateTime time;
  final MealType mealType;
  final AnalysisResult result;
}

class UserProfile {
  UserProfile({
    required this.name,
    required this.email,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.goal,
    required this.planSpeed,
    required this.lunchReminderEnabled,
    required this.dinnerReminderEnabled,
    required this.lunchReminderTime,
    required this.dinnerReminderTime,
    required this.language,
    required this.apiBaseUrl,
    required this.plateAsset,
    required this.nutritionChartStyle,
  });

  String name;
  String email;
  int heightCm;
  int weightKg;
  int age;
  String goal;
  String planSpeed;
  bool lunchReminderEnabled;
  bool dinnerReminderEnabled;
  TimeOfDay lunchReminderTime;
  TimeOfDay dinnerReminderTime;
  String language;
  String apiBaseUrl;
  String plateAsset;
  String nutritionChartStyle;

  factory UserProfile.initial() {
    return UserProfile(
      name: '小明',
      email: 'xiaoming123@gmail.com',
      heightCm: 170,
      weightKg: 72,
      age: 30,
      goal: '減脂',
      planSpeed: '穩定',
      lunchReminderEnabled: true,
      dinnerReminderEnabled: true,
      lunchReminderTime: const TimeOfDay(hour: 12, minute: 15),
      dinnerReminderTime: const TimeOfDay(hour: 18, minute: 45),
      language: 'zh-TW',
      apiBaseUrl: kDefaultApiBaseUrl,
      plateAsset: kDefaultPlateAsset,
      nutritionChartStyle: 'radar',
    );
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    return scope!.notifier!;
  }
}
