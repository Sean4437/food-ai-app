import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storage_client/storage_client.dart';
import '../models/analysis_result.dart';
import '../models/meal_entry.dart';
import '../models/label_result.dart';
import '../models/custom_food.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../config/supabase_config.dart';
import '../storage/meal_store.dart';
import '../storage/settings_store.dart';

const String kDefaultApiBaseUrl = 'https://effectively-wild-oecd-weddings.trycloudflare.com';
const List<String> kDeprecatedApiBaseUrls = [
  'https://sussex-oscar-southern-scanning.trycloudflare.com',
];
const String kDefaultPlateAsset = 'assets/plates/plate_Japanese_02.png';
const String kDefaultThemeAsset = 'assets/themes/theme_clean.json';
const double kDefaultTextScale = 1.0;
const String _kMacroUnitMetaKey = 'macro_unit';
const String _kSettingsUpdatedAtKey = 'settings_updated_at';
const String _kMacroUnitGrams = 'grams';
const String _kMacroUnitPercent = 'percent';
const double _kMacroBaselineProteinG = 30;
const double _kMacroBaselineCarbsG = 80;
const double _kMacroBaselineFatG = 25;
const double _kMacroBaselineSodiumMg = 2300;
const int _kSmallPortionThreshold = 35;
const String _kNamePlaceholderBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/Pi3n1wAAAABJRU5ErkJggg==';

class AppState extends ChangeNotifier {
  AppState()
      : _api = ApiService(baseUrl: _resolveBaseUrl()),
        _store = createMealStore(),
        _settings = createSettingsStore();

  ApiService _api;
  final SupabaseService _supabase = SupabaseService();
  final MealStore _store;
  final SettingsStore _settings;
  final List<MealEntry> entries = [];
  static final Uint8List _namePlaceholderBytes = Uint8List.fromList(base64Decode(_kNamePlaceholderBase64));
  bool _trialExpired = false;
  bool _trialChecked = false;
  bool _whitelisted = false;
  DateTime? _trialEnd;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  final UserProfile profile = UserProfile.initial();
  final Map<String, Map<String, String>> _dayOverrides = {};
  final Map<String, Map<String, String>> _mealOverrides = {};
  final Map<String, Map<String, String>> _weekOverrides = {};
  final Map<String, String> _meta = {};
  final Map<String, Map<String, dynamic>> _deletedEntries = {};
  final Map<String, Map<String, dynamic>> _deletedCustomFoods = {};
  final Set<String> _failedMealSyncIds = {};
  final Set<String> _failedMealDeleteSyncIds = {};
  final Set<String> _failedCustomFoodSyncIds = {};
  final Set<String> _failedCustomFoodDeleteSyncIds = {};
  final List<CustomFood> customFoods = [];
  SyncReport? _lastSyncReport;
  final Map<String, Timer> _analysisTimers = {};
  final Map<String, bool> _analysisTimerForce = {};
  final Map<String, String> _analysisTimerReason = {};
  final Map<String, DateTime> _mealInteractionAt = {};
  final Map<String, Timer> _mealAdviceTimers = {};
  final Set<String> _mealAdviceLoading = {};
  Timer? _autoFinalizeTimer;
  Timer? _autoWeeklyTimer;
  bool _syncing = false;

  bool get isSupabaseSignedIn => _supabase.isSignedIn;
  bool get syncInProgress => _syncing;
  SyncReport? get lastSyncReport => _lastSyncReport;

  String? get supabaseUserEmail => _supabase.currentUser?.email;

  String? _accessToken() {
    return _supabase.client.auth.currentSession?.accessToken;
  }

  Future<void> refreshAccessStatus() async {
    if (!isSupabaseSignedIn) {
      _trialChecked = false;
      _trialExpired = false;
      _whitelisted = false;
      _trialEnd = null;
      notifyListeners();
      return;
    }
    try {
      final response = await _api.accessStatus(accessToken: _accessToken());
      _trialChecked = true;
      _whitelisted = response['whitelisted'] == true;
      final active = response['trial_active'] == true || _whitelisted;
      _trialExpired = !active;
      final endRaw = response['trial_end'] as String?;
      _trialEnd = endRaw == null ? null : DateTime.tryParse(endRaw);
      notifyListeners();
    } catch (_) {
      _trialChecked = true;
      _trialExpired = false;
      _whitelisted = false;
      _trialEnd = null;
      notifyListeners();
    }
  }

  bool get trialExpired => _trialChecked && _trialExpired;

  bool get trialChecked => _trialChecked;

  bool get isWhitelisted => _whitelisted;

  DateTime? get trialEndAt => _trialEnd;

  String buildAiContext() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recent = entries.where((entry) => entry.time.isAfter(cutoff)).toList();
    if (recent.isEmpty) return '';
    recent.sort((a, b) => b.time.compareTo(a.time));
    final last = recent.first;
    final lastName = last.overrideFoodName ?? last.result?.foodName ?? last.filename;
    final t = lookupAppLocalizations(_localeFromProfile());
    final lastSummary = _entryDishSummary(last, t) ?? '';
    final protein = _aggregateMacroPercentPlain(recent, 'protein').round();
    final carbs = _aggregateMacroPercentPlain(recent, 'carbs').round();
    final fat = _aggregateMacroPercentPlain(recent, 'fat').round();
    final sodium = _aggregateMacroPercentPlain(recent, 'sodium').round();
    final recentMealIds = <String>{};
    for (final entry in recent) {
      recentMealIds.add(entry.mealId ?? entry.id);
    }
    return [
      'last_meal_type=${_mealTypeKey(last.type)}',
      'last_meal_name=$lastName',
      if (lastSummary.trim().isNotEmpty) 'last_meal_summary=$lastSummary',
      'recent_7d_macros=protein:$protein, carbs:$carbs, fat:$fat, sodium:$sodium',
      'recent_7d_meal_count=${recentMealIds.length}',
    ].join('\n');
  }

  String dailyActivityLevel(DateTime date) {
    final key = _activityKey(date);
    return _meta[key] ?? profile.activityLevel;
  }

  String dailyExerciseType(DateTime date) {
    final key = _exerciseTypeKey(date);
    return _meta[key] ?? 'none';
  }

  int dailyExerciseMinutes(DateTime date) {
    final key = _exerciseMinutesKey(date);
    final raw = _meta[key];
    final parsed = int.tryParse(raw ?? '');
    return parsed == null || parsed < 0 ? 30 : parsed;
  }

  double dailyExerciseCalories(DateTime date) {
    final type = dailyExerciseType(date);
    if (type == 'none') return 0;
    final weight = profile.weightKg;
    if (weight <= 0) return 0;
    final minutes = dailyExerciseMinutes(date);
    if (minutes <= 0) return 0;
    final hours = minutes / 60.0;
    return _exerciseMet(type) * weight * hours;
  }

  Future<void> updateDailyActivity(DateTime date, String level) async {
    final key = _activityKey(date);
    if (level == profile.activityLevel) {
      _meta.remove(key);
    } else {
      _meta[key] = level;
    }
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> updateDailyExerciseType(DateTime date, String type) async {
    final key = _exerciseTypeKey(date);
    if (type == 'none') {
      _meta.remove(key);
    } else {
      _meta[key] = type;
    }
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> updateDailyExerciseMinutes(DateTime date, int minutes) async {
    final key = _exerciseMinutesKey(date);
    final value = minutes.clamp(0, 360);
    _meta[key] = value.toString();
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveOverrides();
  }

  String exerciseLabel(String type, AppLocalizations t) {
    switch (type) {
      case 'walking':
        return t.exerciseWalking;
      case 'jogging':
        return t.exerciseJogging;
      case 'cycling':
        return t.exerciseCycling;
      case 'swimming':
        return t.exerciseSwimming;
      case 'strength':
        return t.exerciseStrength;
      case 'yoga':
        return t.exerciseYoga;
      case 'hiit':
        return t.exerciseHiit;
      case 'basketball':
        return t.exerciseBasketball;
      case 'hiking':
        return t.exerciseHiking;
      default:
        return t.exerciseNoExercise;
    }
  }

  String activityLabel(String level, AppLocalizations t) {
    switch (level) {
      case 'sedentary':
        return t.activitySedentary;
      case 'light':
        return t.activityLight;
      case 'moderate':
        return t.activityModerate;
      case 'high':
        return t.activityHigh;
      default:
        return t.activityLight;
    }
  }

  String mealTypeLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.brunch:
        return t.brunch;
      case MealType.lunch:
        return t.lunch;
      case MealType.afternoonTea:
        return t.afternoonTea;
      case MealType.dinner:
        return t.dinner;
      case MealType.lateSnack:
        return t.lateSnack;
      case MealType.other:
        return t.other;
    }
  }

  String? targetCalorieRangeValue(DateTime date) {
    final weight = profile.weightKg;
    final height = profile.heightCm;
    final age = profile.age;
    if (weight <= 0 || height <= 0 || age <= 0) return null;
    final gender = profile.gender;
    double s;
    if (gender == 'male') {
      s = 5;
    } else if (gender == 'female') {
      s = -161;
    } else {
      s = -78;
    }
    final bmr = 10 * weight + 6.25 * height - 5 * age + s;
    final activity = dailyActivityLevel(date);
    final factor = _activityFactor(activity);
    double target = bmr * factor;
    final goal = profile.goal;
    final plan = profile.planSpeed;
    final isMaintain = goal.contains('維持') || goal.toLowerCase().contains('maintain');
    if (!isMaintain) {
      final isGentle = plan.contains('保守') || plan.toLowerCase().contains('gentle');
      target -= isGentle ? 300 : 500;
    }
    target += dailyExerciseCalories(date);
    final min = max(1200, (target - 150).round());
    final maxCal = max(min, (target + 150).round());
    return '${_roundTo50(min)}-${_roundTo50(maxCal)} kcal';
  }

  String targetCalorieRangeLabel(DateTime date, AppLocalizations t) {
    final value = targetCalorieRangeValue(date);
    return value ?? t.targetCalorieUnknown;
  }

  String dailyCalorieDeltaLabel(DateTime date, AppLocalizations t) {
    final actualRange = _dailyCalorieRangeNumbers(date);
    final targetRange = _parseCalorieRange(targetCalorieRangeValue(date) ?? '');
    if (actualRange == null || targetRange == null) return t.deltaUnknown;
    final actualMid = (actualRange[0] + actualRange[1]) / 2;
    final targetMid = (targetRange[0] + targetRange[1]) / 2;
    final delta = actualMid - targetMid;
    final amount = delta.abs().round();
    if (amount == 0) return t.deltaOk;
    if (delta > 0) return t.deltaSurplus(amount);
    return t.deltaDeficit(amount);
  }

  double? dailyCalorieDeltaValue(DateTime date) {
    final actualRange = _dailyCalorieRangeNumbers(date);
    final targetRange = _parseCalorieRange(targetCalorieRangeValue(date) ?? '');
    if (actualRange == null || targetRange == null) return null;
    final actualMid = (actualRange[0] + actualRange[1]) / 2;
    final targetMid = (targetRange[0] + targetRange[1]) / 2;
    return actualMid - targetMid;
  }

  double? targetCalorieMid(DateTime date) {
    final range = _parseCalorieRange(targetCalorieRangeValue(date) ?? '');
    if (range == null) return null;
    return (range[0] + range[1]) / 2;
  }

  double? calorieRangeMid(String? rangeText) {
    final range = _parseCalorieRange(rangeText);
    if (range == null) return null;
    return (range[0] + range[1]) / 2;
  }

  double dailyConsumedCalorieMid(DateTime date, {String? excludeEntryId}) {
    double sum = 0;
    bool hasRange = false;
    for (final entry in entriesForDate(date)) {
      if (excludeEntryId != null && entry.id == excludeEntryId) continue;
      final range = _parseCalorieRange(entry.overrideCalorieRange ?? entry.result?.calorieRange);
      if (range == null) continue;
      final weight = _entryPortionFactor(entry);
      final mid = ((range[0] + range[1]) / 2) * weight;
      sum += mid;
      hasRange = true;
    }
    return hasRange ? sum : 0;
  }

  int? exerciseMinutesForCalories(double calories, String type) {
    if (calories <= 0) return null;
    if (type == 'none') return null;
    final weight = profile.weightKg;
    if (weight <= 0) return null;
    final met = _exerciseMet(type);
    if (met <= 0) return null;
    final minutes = (calories / (met * weight)) * 60.0;
    if (!minutes.isFinite || minutes <= 0) return null;
    return minutes.ceil();
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
      accessToken: _accessToken(),
      lang: locale,
      context: historyContext,
      mealType: _mealTypeKey(mealType),
      mealPhotoCount: 1,
      analyzeReason: 'quick_capture',
      containerType: profile.containerType,
      containerSize: profile.containerSize,
      containerDepth: profile.containerDepth,
      containerDiameterCm: profile.containerDiameterCm,
      containerCapacityMl: profile.containerCapacityMl,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      age: profile.age,
      gender: profile.gender,
      tone: profile.tone,
      persona: profile.persona,
      activityLevel: dailyActivityLevel(time),
      targetCalorieRange: targetCalorieRangeValue(time),
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
    String? containerType,
    String? containerSize,
    int? portionPercent,
  }) async {
    final filename = analysis.file.name.isNotEmpty ? analysis.file.name : 'upload.jpg';
    final selectedContainerType = containerType ?? profile.containerType;
    final selectedContainerSize = containerSize ?? profile.containerSize;
    final result = await _api.analyzeImage(
      analysis.imageBytes,
      filename,
      accessToken: _accessToken(),
      lang: locale,
      context: historyContext,
      foodName: foodName,
      portionPercent: portionPercent,
      mealType: _mealTypeKey(analysis.mealType),
      mealPhotoCount: 1,
      analyzeReason: 'quick_capture_manual',
      containerType: selectedContainerType,
      containerSize: selectedContainerSize,
      containerDepth: profile.containerDepth,
      containerDiameterCm: profile.containerDiameterCm,
      containerCapacityMl: profile.containerCapacityMl,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      age: profile.age,
      gender: profile.gender,
      tone: profile.tone,
      persona: profile.persona,
      activityLevel: dailyActivityLevel(analysis.time),
      targetCalorieRange: targetCalorieRangeValue(analysis.time),
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
    MealEntry? existing,
    int? portionPercent,
    String? containerType,
    String? containerSize,
    String? overrideCalorieRange,
  }) async {
    final now = DateTime.now().toUtc();
    final filename = analysis.file.name.isNotEmpty ? analysis.file.name : 'upload.jpg';
    final imageHash = _hashBytes(analysis.originalBytes);
    MealEntry entry;
    if (existing != null) {
      entry = existing.copyWith(
        imageBytes: analysis.imageBytes,
        filename: filename,
        time: analysis.time,
        type: analysis.mealType,
        note: note,
        imageHash: imageHash,
        portionPercent: portionPercent ?? existing.portionPercent,
        containerType: containerType ?? existing.containerType,
        containerSize: containerSize ?? existing.containerSize,
        overrideCalorieRange: overrideCalorieRange ?? existing.overrideCalorieRange,
        result: _resolveNutritionResult(analysis.result),
        updatedAt: now,
        lastAnalyzedNote: (note ?? '').trim(),
        lastAnalyzedFoodName: existing.overrideFoodName ?? '',
        lastAnalyzedAt: DateTime.now().toIso8601String(),
        lastAnalyzeReason: 'quick_capture_manual',
      );
      entry.mealId ??= _assignMealId(entry.time, entry.type);
      final index = entries.indexWhere((item) => item.id == entry.id);
      if (index != -1) {
        entries[index] = entry;
      } else {
        entries.insert(0, entry);
      }
    } else {
      final mealId = _assignMealId(analysis.time, analysis.mealType);
      entry = MealEntry(
        id: _newId(),
        imageBytes: analysis.imageBytes,
        filename: filename,
        time: analysis.time,
        type: analysis.mealType,
        portionPercent: portionPercent ?? 100,
        containerType: containerType,
        containerSize: containerSize,
        overrideCalorieRange: overrideCalorieRange,
        updatedAt: now,
        mealId: mealId,
        note: note,
        imageHash: imageHash,
      );
      entry.result = _resolveNutritionResult(analysis.result);
      entry.lastAnalyzedNote = (note ?? '').trim();
      entry.lastAnalyzedFoodName = entry.overrideFoodName ?? '';
      entry.lastAnalyzedAt = DateTime.now().toIso8601String();
      entry.lastAnalyzeReason = 'quick_capture';
      entries.insert(0, entry);
    }
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
    final didMigrateApi = _migrateApiBaseUrlIfNeeded();
    bool profileChanged = false;
    if (profile.nutritionValueMode != 'amount') {
      profile.nutritionValueMode = 'amount';
      profileChanged = true;
    }
    final overrides = await _settings.loadOverrides();
    if (overrides != null) {
      _loadOverrides(overrides);
    }
    if (_meta[_kSettingsUpdatedAtKey] == null || _meta[_kSettingsUpdatedAtKey]!.isEmpty) {
      _meta[_kSettingsUpdatedAtKey] = DateTime.now().toUtc().toIso8601String();
      await _saveOverrides();
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
      if (entry.updatedAt == null) {
        entry.updatedAt = entry.time.toUtc();
        changed = true;
      }
    }
    if (changed) {
      for (final entry in entries) {
        await _store.upsert(entry);
      }
    }
    final migratedMacros = _maybeMigrateMacrosToGrams();
    if (migratedMacros) {
      for (final entry in entries) {
        await _store.upsert(entry);
      }
      await _saveOverrides();
    } else if (_meta[_kMacroUnitMetaKey] != _kMacroUnitGrams) {
      _meta[_kMacroUnitMetaKey] = _kMacroUnitGrams;
      await _saveOverrides();
    }
    if (didMigrateApi || profileChanged) {
      await _saveProfile();
    }
    _scheduleAutoFinalize();
    _scheduleAutoFinalizeWeek();
    await _maybeFinalizeWeekOnLaunch();
    // Warm plate asset cache on startup (web uses network for assets).
    precachePlateAsset();
    if (isSupabaseSignedIn) {
      // Do not block app startup on network calls.
      scheduleMicrotask(() async {
        await refreshAccessStatus();
        await _runAutoSync();
      });
    }
    notifyListeners();
  }

  Future<void> _runAutoSync() async {
    if (!isSupabaseSignedIn) return;
    if (syncInProgress) return;
    setSyncInProgress(true);
    try {
      await syncAuto();
    } catch (_) {
      // Silent auto sync failure.
    } finally {
      setSyncInProgress(false);
    }
  }

  Future<void> precachePlateAsset() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    final context = binding.renderViewElement;
    if (context == null) return;
    final asset = profile.plateAsset.isEmpty ? kDefaultPlateAsset : profile.plateAsset;
    try {
      await precacheImage(AssetImage(asset), context);
    } catch (_) {}
  }

  Future<void> _maybeFinalizeWeekOnLaunch() async {
    final now = DateTime.now();
    if (!isWeeklySummaryReady(now)) {
      return;
    }
    final weekStart = _weekStartFor(now);
    final weekKey = _weekKey(weekStart);
    if (_meta['last_auto_week'] == weekKey) {
      return;
    }
    if (_weekOverrides.containsKey(weekKey)) {
      return;
    }
    final locale = _localeFromProfile();
    final t = lookupAppLocalizations(locale);
    await finalizeWeek(now, locale.toLanguageTag(), t);
    _meta['last_auto_week'] = weekKey;
    await _saveOverrides();
  }

  Future<void> addCustomFoodFromEntry(MealEntry entry, AppLocalizations t) async {
    final now = DateTime.now();
    final result = entry.result;
    if (result == null) return;
    final food = CustomFood(
      id: _newId(),
      name: entry.overrideFoodName ?? result.foodName,
      summary: result.dishSummary ?? '',
      calorieRange: result.calorieRange,
      suggestion: result.suggestion,
      macros: Map<String, double>.from(result.macros),
      imageBytes: entry.imageBytes,
      createdAt: now,
      updatedAt: now,
    );
    customFoods.insert(0, food);
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> upsertCustomFood(CustomFood food) async {
    final index = customFoods.indexWhere((item) => item.id == food.id);
    if (index == -1) {
      customFoods.insert(0, food);
    } else {
      customFoods[index] = food;
    }
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> deleteCustomFood(CustomFood food) async {
    final now = DateTime.now().toUtc();
    _deletedCustomFoods[food.id] = {
      ...food.toJson(),
      'deleted_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    customFoods.removeWhere((item) => item.id == food.id);
    notifyListeners();
    await _saveOverrides();
  }

  Future<MealEntry> saveCustomFoodUsage(
    CustomFood food,
    DateTime time,
    MealType type,
  ) async {
    final mealId = _assignMealId(time, type);
    final entry = MealEntry(
      id: _newId(),
      imageBytes: food.imageBytes,
      filename: 'custom.png',
      time: time,
      type: type,
      portionPercent: 100,
      updatedAt: DateTime.now().toUtc(),
      mealId: mealId,
      imageHash: _hashBytes(food.imageBytes),
    );
    entry.result = AnalysisResult(
      foodName: food.name,
      calorieRange: food.calorieRange,
      macros: Map<String, double>.from(food.macros),
      dishSummary: food.summary,
      suggestion: food.suggestion,
      tier: 'custom',
      source: 'custom',
      nutritionSource: 'custom',
    );
    entry.lastAnalyzedAt = DateTime.now().toIso8601String();
    entry.lastAnalyzeReason = 'custom_use';
    entries.insert(0, entry);
    markMealInteraction(entry.mealId ?? entry.id);
    _selectedDate = _dateOnly(entry.time);
    notifyListeners();
    await _store.upsert(entry);
    return entry;
  }

  Future<MealEntry> analyzeNameAndSave(
    String foodName,
    String locale, {
    String? historyContext,
  }) async {
    final trimmed = foodName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Food name is empty');
    }
    final now = DateTime.now();
    final mealType = resolveMealType(now);
    final mealId = _assignMealId(now, mealType);

    CustomFood? matched;
    for (final item in customFoods) {
      if (item.name.trim() == trimmed) {
        matched = item;
        break;
      }
    }
    if (matched != null) {
      return saveCustomFoodUsage(matched, now, mealType);
    }

    final result = await _api.analyzeName(
      trimmed,
      accessToken: _accessToken(),
      lang: locale,
      context: historyContext,
      mealType: _mealTypeKey(mealType),
      portionPercent: 100,
      adviceMode: 'current_meal',
      containerType: profile.containerType,
      containerSize: profile.containerSize,
      containerDepth: profile.containerDepth,
      containerDiameterCm: profile.containerDiameterCm,
      containerCapacityMl: profile.containerCapacityMl,
      profile: {
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'age': profile.age,
        'gender': profile.gender,
        'container_type': profile.containerType,
        'container_size': profile.containerSize,
        'container_depth': profile.containerDepth,
        'container_diameter_cm': profile.containerDiameterCm,
        'container_capacity_ml': profile.containerCapacityMl,
        'tone': profile.tone,
        'persona': profile.persona,
        'activity_level': dailyActivityLevel(now),
        'target_calorie_range': targetCalorieRangeValue(now),
        'goal': profile.goal,
        'plan_speed': profile.planSpeed,
      },
    );

    final entry = MealEntry(
      id: _newId(),
      imageBytes: _namePlaceholderBytes,
      filename: 'name_only.png',
      time: now,
      type: mealType,
      portionPercent: 100,
      updatedAt: DateTime.now().toUtc(),
      mealId: mealId,
      imageHash: _hashBytes(_namePlaceholderBytes),
      lastAnalyzedFoodName: trimmed,
    );
    entry.result = _resolveNutritionResult(result);
    entry.lastAnalyzedAt = DateTime.now().toIso8601String();
    entry.lastAnalyzeReason = 'name_only';
    entries.insert(0, entry);
    markMealInteraction(mealId);
    _selectedDate = _dateOnly(now);
    notifyListeners();
    await _store.upsert(entry);
    return entry;
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

  String entryCalorieRangeLabel(MealEntry entry, AppLocalizations t) {
    final baseRange = entry.overrideCalorieRange ?? entry.result?.calorieRange ?? '';
    final parsed = _parseCalorieRange(baseRange);
    if (parsed == null) return t.calorieUnknown;
    final weight = _entryPortionFactor(entry);
    final minVal = (parsed[0] * weight).round();
    final maxVal = (parsed[1] * weight).round();
    return '$minVal-$maxVal kcal';
  }

  double? entryCalorieMid(MealEntry entry) {
    final baseRange = entry.overrideCalorieRange ?? entry.result?.calorieRange;
    final parsed = _parseCalorieRange(baseRange);
    if (parsed == null) return null;
    final weight = _entryPortionFactor(entry);
    return ((parsed[0] + parsed[1]) / 2) * weight;
  }

  String _dailyCalorieRangeLabelForDate(DateTime date, AppLocalizations t) {
    final summary = buildDaySummary(date, t);
    if (summary != null && summary.calorieRange != t.calorieUnknown) {
      return summary.calorieRange;
    }
    final range = _dailyCalorieRangeNumbers(date);
    if (range != null) {
      return '${range[0]}-${range[1]} kcal';
    }
    int minSum = 0;
    int maxSum = 0;
    bool hasRange = false;
    final groups = <List<MealEntry>>[
      ...mealGroupsForDate(date, MealType.breakfast),
      ...mealGroupsForDate(date, MealType.brunch),
      ...mealGroupsForDate(date, MealType.lunch),
      ...mealGroupsForDate(date, MealType.afternoonTea),
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

  List<int>? _dailyCalorieRangeNumbers(DateTime date) {
    int minSum = 0;
    int maxSum = 0;
    bool hasRange = false;
    final groups = <List<MealEntry>>[
      ...mealGroupsForDate(date, MealType.breakfast),
      ...mealGroupsForDate(date, MealType.brunch),
      ...mealGroupsForDate(date, MealType.lunch),
      ...mealGroupsForDate(date, MealType.afternoonTea),
      ...mealGroupsForDate(date, MealType.dinner),
      ...mealGroupsForDate(date, MealType.lateSnack),
      ...mealGroupsForDate(date, MealType.other),
    ];
    for (final group in groups) {
      final summary = buildMealSummary(group, lookupAppLocalizations(_localeFromProfile()));
      if (summary == null) continue;
      final range = _parseCalorieRange(summary.calorieRange);
      if (range == null) continue;
      minSum += range[0];
      maxSum += range[1];
      hasRange = true;
    }
    if (!hasRange) return null;
    return [minSum, maxSum];
  }

  String todayStatusLabel(AppLocalizations t) {
    final entry = latestEntryForSelectedDate;
    if (entry == null || entry.result == null) return t.suggestTodayHint;
    final fat = macroPercentFromResult(entry.result!, 'fat');
    final carbs = macroPercentFromResult(entry.result!, 'carbs');
    final oily = _isHigh(fat);
    final carbHigh = _isHigh(carbs);
    if (oily && carbHigh) return t.suggestTodayOilyCarb;
    if (oily) return t.suggestTodayOily;
    if (carbHigh) return t.suggestTodayCarb;
    return t.suggestTodayOk;
  }

  String todaySummary(AppLocalizations t) {
    final entry = latestEntryForSelectedDate;
    if (entry == null || entry.result == null) return t.summaryEmpty;
    final fat = macroPercentFromResult(entry.result!, 'fat');
    final protein = macroPercentFromResult(entry.result!, 'protein');
    final carbs = macroPercentFromResult(entry.result!, 'carbs');
    final oily = _isHigh(fat);
    final proteinOk = _isProteinOk(protein);
    final carbHigh = _isHigh(carbs);
    if (oily && carbHigh) return t.summaryOilyCarb;
    if (oily) return t.summaryOily;
    if (carbHigh) return t.summaryCarb;
    if (proteinOk) return t.summaryProteinOk;
    return t.summaryNeutral;
  }

  bool isDailySummaryReady(DateTime date) {
    final key = _dayKey(date);
    if (_dayOverrides.containsKey(key)) return true;
    final today = _dateOnly(DateTime.now());
    if (_isSameDate(date, today)) {
      final now = TimeOfDay.now();
      final target = profile.dailySummaryTime;
      return (now.hour > target.hour) || (now.hour == target.hour && now.minute >= target.minute);
    }
    return date.isBefore(today);
  }

  bool isWeeklySummaryReady(DateTime date) {
    final key = _weekKey(_weekStartFor(date));
    if (_weekOverrides.containsKey(key)) return true;
    final today = _dateOnly(DateTime.now());
    if (date.isAfter(today)) return false;
    final weekday = profile.weeklySummaryWeekday;
    final target = _weekStartFor(today).add(Duration(days: weekday - 1));
    if (_isSameDate(today, target)) {
      final now = TimeOfDay.now();
      final t = profile.dailySummaryTime;
      return (now.hour > t.hour) || (now.hour == t.hour && now.minute >= t.minute);
    }
    return today.isAfter(target);
  }

  String dailySummaryPendingText(AppLocalizations t) {
    return t.summaryPendingAt(_timeToString(profile.dailySummaryTime));
  }

  String weeklySummaryPendingText(AppLocalizations t) {
    final weekdayLabel = _weekdayLabel(profile.weeklySummaryWeekday, t);
    return t.weekSummaryPendingAt(weekdayLabel, _timeToString(profile.dailySummaryTime));
  }

  String daySummaryText(DateTime date, AppLocalizations t) {
    final override = _dayOverrides[_dayKey(date)];
    final manual = override?['summary'];
    if (manual != null && manual.trim().isNotEmpty) return manual;
    if (!isDailySummaryReady(date)) return dailySummaryPendingText(t);
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
    if (!isDailySummaryReady(date)) return dailySummaryPendingText(t);
    final summary = buildDaySummary(date, t);
    return summary?.advice ?? t.nextMealHint;
  }

  String weekSummaryText(DateTime date, AppLocalizations t) {
    final key = _weekKey(_weekStartFor(date));
    final override = _weekOverrides[key];
    final manual = override?['week_summary'];
    if (manual != null && manual.trim().isNotEmpty) return manual;
    if (!isWeeklySummaryReady(date)) return weeklySummaryPendingText(t);
    return t.summaryEmpty;
  }

  String nextWeekAdviceText(DateTime date, AppLocalizations t) {
    final key = _weekKey(_weekStartFor(date));
    final override = _weekOverrides[key];
    final manual = override?['next_week_advice'];
    if (manual != null && manual.trim().isNotEmpty) return manual;
    if (!isWeeklySummaryReady(date)) return weeklySummaryPendingText(t);
    return t.nextMealHint;
  }

  Future<void> finalizeDay(DateTime date, String locale, AppLocalizations t) async {
    final groups = mealGroupsForDateAll(date);
    if (groups.isEmpty) return;
    final meals = <Map<String, dynamic>>[];
    for (final group in groups) {
      final summary = buildMealSummary(group, t);
      final dishSummaries = <String>[];
      for (final entry in group) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
        }
      }
      if (dishSummaries.length > 3) {
        dishSummaries
          ..clear()
          ..add(t.multiItemsLabel);
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
        'day_calorie_range': _dailyCalorieRangeLabelForDate(date, t),
        'day_meal_count': groups.length,
        'profile': {
          'height_cm': profile.heightCm,
          'weight_kg': profile.weightKg,
          'age': profile.age,
          'gender': profile.gender,
          'tone': profile.tone,
          'persona': profile.persona,
          'activity_level': dailyActivityLevel(date),
          'target_calorie_range': targetCalorieRangeValue(date),
          'goal': profile.goal,
          'plan_speed': profile.planSpeed,
        },
      };
    try {
      final response = await _api.summarizeDay(payload, _accessToken());
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
    _meta[_dayLockKey(date)] = 'true';
    for (final entry in entriesForDate(date)) {
      final key = entry.id;
      _analysisTimers[key]?.cancel();
      _analysisTimers.remove(key);
      _analysisTimerForce.remove(key);
      _analysisTimerReason.remove(key);
    }
    await _saveOverrides();
    await _maybeFinalizeWeekForDate(date, locale, t);
  }

  Future<void> _maybeFinalizeWeekForDate(DateTime date, String locale, AppLocalizations t) async {
    final normalized = _dateOnly(date);
    final weekStart = _weekStartFor(normalized);
    final weekKey = _weekKey(weekStart);
    if (_weekOverrides.containsKey(weekKey)) {
      return;
    }
    final targetDate = weekStart.add(Duration(days: profile.weeklySummaryWeekday - 1));
    if (normalized.isBefore(targetDate)) {
      return;
    }
    if (_meta['last_auto_week'] == weekKey) {
      return;
    }
    await finalizeWeek(normalized, locale, t);
    _meta['last_auto_week'] = weekKey;
    await _saveOverrides();
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
    await _runAutoSync();
    _scheduleAutoFinalize();
  }

  Future<void> finalizeWeek(DateTime date, String locale, AppLocalizations t) async {
    final weekStart = _weekStartFor(date);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final days = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final daySummary = buildDaySummary(day, t);
      if (daySummary == null) continue;
      final entriesFor = entriesForDate(day);
      final groups = mealGroupsForDateAll(day);
      final dayMealSummaries = <String>[];
      for (final group in groups) {
        if (group.isEmpty) continue;
        final summary = buildMealSummary(group, t);
        final dishSummaries = <String>[];
        for (final entry in group) {
          final summaryText = _entryDishSummary(entry, t);
          if (summaryText != null && summaryText.isNotEmpty) {
            dishSummaries.add(summaryText);
          }
        }
        if (dishSummaries.length > 3) {
          dishSummaries
            ..clear()
            ..add(t.multiItemsLabel);
        }
        final label = _mealTypeLabel(group.first.type, t);
        final rangeText = summary?.calorieRange ?? t.calorieUnknown;
        final dishText = dishSummaries.isEmpty ? '' : dishSummaries.join(' / ');
        final parts = <String>[label];
        if (rangeText.isNotEmpty) parts.add(rangeText);
        if (dishText.isNotEmpty) parts.add(dishText);
        dayMealSummaries.add(parts.join(' · '));
      }
      days.add({
        'date': '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        'calorie_range': daySummary.calorieRange,
        'day_summary': daySummary.advice,
        'meal_count': groups.length,
        'meal_entry_count': entriesFor.length,
        'day_meal_summaries': dayMealSummaries,
      });
    }
    if (days.isEmpty) return;
      final payload = {
        'week_start': '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}',
        'week_end': '${weekEnd.year.toString().padLeft(4, '0')}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}',
        'lang': locale,
        'days': days,
        'profile': {
          'height_cm': profile.heightCm,
          'weight_kg': profile.weightKg,
          'age': profile.age,
          'gender': profile.gender,
          'tone': profile.tone,
          'persona': profile.persona,
          'activity_level': profile.activityLevel,
          'target_calorie_range': targetCalorieRangeValue(weekStart),
          'goal': profile.goal,
          'plan_speed': profile.planSpeed,
        },
      };
    try {
      final response = await _api.summarizeWeek(payload, _accessToken());
      final summaryText = (response['week_summary'] as String?) ?? '';
      final adviceText = (response['next_week_advice'] as String?) ?? '';
      await updateWeekOverride(
        weekStart,
        weekSummary: summaryText,
        nextWeekAdvice: adviceText,
      );
    } catch (_) {
      // Keep existing summary if summarize fails
    }
  }

  Future<void> autoFinalizeWeek() async {
    final locale = _localeFromProfile();
    final t = lookupAppLocalizations(locale);
    final weekKey = _weekKey(_weekStartFor(DateTime.now()));
    if (_meta['last_auto_week'] == weekKey) {
      _scheduleAutoFinalizeWeek();
      return;
    }
    await finalizeWeek(DateTime.now(), locale.toLanguageTag(), t);
    _meta['last_auto_week'] = weekKey;
    await _saveOverrides();
    _scheduleAutoFinalizeWeek();
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

  Future<void> ensureMealAdviceForGroup(
    List<MealEntry> group,
    AppLocalizations t,
    String locale,
  ) async {
    if (group.isEmpty) return;
    final mealId = group.first.mealId ?? group.first.id;
    final key = _mealKey(mealId);
    if (_mealOverrides.containsKey(key)) return;
    if (_mealAdviceLoading.contains(mealId)) return;
    _mealAdviceLoading.add(mealId);
    try {
      final mealDate = _dateOnly(group.first.time);
      final delta = dailyCalorieDeltaValue(mealDate);
      final isDinner = group.first.type == MealType.dinner;
      final nearOrOverTarget = delta != null && delta >= -100;
      if (isDinner && nearOrOverTarget) {
        final advice = MealAdvice(
          selfCook: t.noLateSnackSelfCook,
          convenience: t.noLateSnackConvenience,
          bento: t.noLateSnackBento,
          other: t.noLateSnackOther,
        );
        await updateMealAdvice(mealId, advice, reanalyzeEntries: false);
        return;
      }
      final dayGroups = mealGroupsForDateAll(mealDate);
      final summary = buildMealSummary(group, t);
      final dishSummaries = <String>[];
      for (final entry in group) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
        }
      }
      final collapsedSummaries = _collapseDishSummaries(dishSummaries, t);
      final dayMealSummaries = <String>[];
      for (final dayGroup in dayGroups) {
        if (dayGroup.isEmpty) continue;
        final daySummary = buildMealSummary(dayGroup, t);
        final dayDishSummaries = <String>[];
        for (final entry in dayGroup) {
          final summaryText = _entryDishSummary(entry, t);
          if (summaryText != null && summaryText.isNotEmpty) {
            dayDishSummaries.add(summaryText);
          }
        }
        final label = _mealTypeLabel(dayGroup.first.type, t);
        final rangeText = daySummary?.calorieRange ?? t.calorieUnknown;
        final collapsedDaySummaries = _collapseDishSummaries(dayDishSummaries, t);
        final dishText = collapsedDaySummaries.isEmpty ? '' : collapsedDaySummaries.join(' / ');
        final parts = <String>[label];
        if (rangeText.isNotEmpty) parts.add(rangeText);
        if (dishText.isNotEmpty) parts.add(dishText);
        dayMealSummaries.add(parts.join(' · '));
      }
      final payload = {
        'meal_type': _mealTypeKey(group.first.type),
        'calorie_range': summary?.calorieRange ?? '',
        'dish_summaries': collapsedSummaries,
        'day_calorie_range': _dailyCalorieRangeLabelForDate(mealDate, t),
        'day_meal_count': dayGroups.length,
        'day_meal_summaries': dayMealSummaries,
        'lang': locale,
        'profile': {
          'height_cm': profile.heightCm,
          'weight_kg': profile.weightKg,
          'age': profile.age,
          'gender': profile.gender,
          'tone': profile.tone,
          'persona': profile.persona,
          'activity_level': dailyActivityLevel(group.first.time),
          'target_calorie_range': targetCalorieRangeValue(group.first.time),
          'goal': profile.goal,
          'plan_speed': profile.planSpeed,
        },
      };
      final response = await _api.suggestMeal(payload, _accessToken());
      final advice = MealAdvice(
        selfCook: (response['self_cook'] as String?) ?? t.nextSelfCookHint,
        convenience: (response['convenience'] as String?) ?? t.nextConvenienceHint,
        bento: (response['bento'] as String?) ?? t.nextBentoHint,
        other: (response['other'] as String?) ?? t.nextOtherHint,
      );
      await updateMealAdvice(mealId, advice, reanalyzeEntries: false);
    } catch (_) {
      // Keep defaults if suggestion fails.
    } finally {
      _mealAdviceLoading.remove(mealId);
    }
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
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> updateWeekOverride(DateTime weekStart, {String? weekSummary, String? nextWeekAdvice}) async {
    final key = _weekKey(weekStart);
    _weekOverrides.putIfAbsent(key, () => {});
    if (weekSummary != null) {
      final value = weekSummary.trim();
      if (value.isEmpty) {
        _weekOverrides[key]!.remove('week_summary');
      } else {
        _weekOverrides[key]!['week_summary'] = value;
      }
    }
    if (nextWeekAdvice != null) {
      final value = nextWeekAdvice.trim();
      if (value.isEmpty) {
        _weekOverrides[key]!.remove('next_week_advice');
      } else {
        _weekOverrides[key]!['next_week_advice'] = value;
      }
    }
    if (_weekOverrides[key]!.isEmpty) {
      _weekOverrides.remove(key);
    }
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveOverrides();
  }

  Future<void> updateMealAdvice(String mealId, MealAdvice advice, {bool reanalyzeEntries = true}) async {
    final key = _mealKey(mealId);
    _mealOverrides[key] = {
      'self_cook': advice.selfCook.trim(),
      'convenience': advice.convenience.trim(),
      'bento': advice.bento.trim(),
      'other': advice.other.trim(),
    };
    _touchSettingsUpdatedAt();
    markMealInteraction(mealId);
    notifyListeners();
    await _saveOverrides();
    if (reanalyzeEntries) {
      final locale = profile.language;
      for (final entry in entriesForMealId(mealId)) {
        _scheduleAnalyze(entry, locale, force: true, reason: 'meal_advice_changed');
      }
    }
  }

  static String _resolveBaseUrl() {
    return kDefaultApiBaseUrl;
  }

  static String _normalizeApiBaseUrl(String url) {
    return url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  bool _migrateApiBaseUrlIfNeeded() {
    if (profile.apiBaseUrl.isEmpty) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
      return true;
    }
    final normalized = _normalizeApiBaseUrl(profile.apiBaseUrl);
    final normalizedDefault = _normalizeApiBaseUrl(kDefaultApiBaseUrl);
    if (normalized.contains('trycloudflare.com') && normalized != normalizedDefault) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
      return true;
    }
    final deprecatedNormalized = kDeprecatedApiBaseUrls.map(_normalizeApiBaseUrl);
    if (deprecatedNormalized.contains(normalized)) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
      return true;
    }
    if (normalized != profile.apiBaseUrl) {
      profile.apiBaseUrl = normalized;
      return true;
    }
    return false;
  }

  void updateApiBaseUrl(String url) {
    final normalized = _normalizeApiBaseUrl(url);
    _api = ApiService(baseUrl: normalized);
    notifyListeners();
  }

  MealType resolveMealType(DateTime time) {
    final current = TimeOfDay.fromDateTime(time);
    if (_inRange(profile.breakfastStart, profile.breakfastEnd, current)) return MealType.breakfast;
    if (_inRange(profile.brunchStart, profile.brunchEnd, current)) return MealType.brunch;
    if (_inRange(profile.lunchStart, profile.lunchEnd, current)) return MealType.lunch;
    if (_inRange(profile.afternoonTeaStart, profile.afternoonTeaEnd, current)) return MealType.afternoonTea;
    if (_inRange(profile.dinnerStart, profile.dinnerEnd, current)) return MealType.dinner;
    if (_inRange(profile.lateSnackStart, profile.lateSnackEnd, current)) return MealType.lateSnack;
    return MealType.other;
  }

  bool _inRange(TimeOfDay start, TimeOfDay end, TimeOfDay value) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final valueMinutes = value.hour * 60 + value.minute;
    if (startMinutes <= endMinutes) {
      return valueMinutes >= startMinutes && valueMinutes <= endMinutes;
    }
    return valueMinutes >= startMinutes || valueMinutes <= endMinutes;
  }

  void markMealInteraction(String mealId) {
    _mealInteractionAt[mealId] = DateTime.now();
  }

  DateTime? mealInteractionAt(String mealId) => _mealInteractionAt[mealId];

  String _mealTypeKey(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'breakfast';
      case MealType.brunch:
        return 'brunch';
      case MealType.lunch:
        return 'lunch';
      case MealType.afternoonTea:
        return 'afternoon_tea';
      case MealType.dinner:
        return 'dinner';
      case MealType.lateSnack:
        return 'late_snack';
      case MealType.other:
        return 'other';
    }
  }

  MealType _mealTypeFromKey(String value) {
    switch (value) {
      case 'breakfast':
        return MealType.breakfast;
      case 'brunch':
        return MealType.brunch;
      case 'lunch':
        return MealType.lunch;
      case 'afternoon_tea':
        return MealType.afternoonTea;
      case 'dinner':
        return MealType.dinner;
      case 'late_snack':
        return MealType.lateSnack;
      case 'other':
      default:
        return MealType.other;
    }
  }

  String _mealTypeLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.brunch:
        return t.brunch;
      case MealType.lunch:
        return t.lunch;
      case MealType.afternoonTea:
        return t.afternoonTea;
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

  Map<MealType, List<List<MealEntry>>> mealGroupsByTypeForDate(DateTime date) {
    final target = _dateOnly(date);
    final grouped = <MealType, Map<String, List<MealEntry>>>{};
    for (final type in MealType.values) {
      grouped[type] = <String, List<MealEntry>>{};
    }
    for (final entry in entries) {
      if (!_isSameDate(entry.time, target)) continue;
      final groups = grouped[entry.type]!;
      final key = entry.mealId ?? entry.id;
      groups.putIfAbsent(key, () => []).add(entry);
    }
    final result = <MealType, List<List<MealEntry>>>{};
    grouped.forEach((type, groups) {
      final list = groups.values.toList();
      for (final group in list) {
        group.sort((a, b) => b.time.compareTo(a.time));
      }
      list.sort((a, b) => a.first.time.compareTo(b.first.time));
      result[type] = list.reversed.toList();
    });
    return result;
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
    double proteinSum = 0;
    double carbSum = 0;
    double fatSum = 0;
    double sodiumSum = 0;

    for (final entry in group) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _entryPortionFactor(entry);
      totalWeight += weight;
      final range = _parseCalorieRange(entry.overrideCalorieRange ?? result.calorieRange);
      if (range != null) {
        minSum += range[0] * weight;
        maxSum += range[1] * weight;
      }
      proteinSum += (result.macros['protein'] ?? 0) * weight;
      carbSum += (result.macros['carbs'] ?? 0) * weight;
      fatSum += (result.macros['fat'] ?? 0) * weight;
      sodiumSum += (result.macros['sodium'] ?? 0) * weight;
    }

    if (totalWeight == 0) return null;
    final macros = <String, double>{
      'protein': proteinSum,
      'carbs': carbSum,
      'fat': fatSum,
      'sodium': sodiumSum,
    };
    final dishSummary = _buildMealDishSummary(group, t);
    final calorieRange = minSum > 0 && maxSum > 0 ? '${minSum.round()}-${maxSum.round()} kcal' : t.calorieUnknown;
    final advice = (dishSummary.isNotEmpty && dishSummary != t.multiItemsLabel)
        ? dishSummary
        : _buildMealAdvice(macros, calorieRange, t);
    return MealSummary(calorieRange: calorieRange, macros: macros, advice: advice);
  }

  MealSummary? buildDaySummary(DateTime date, AppLocalizations t) {
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return null;
    double totalWeight = 0;
    double minSum = 0;
    double maxSum = 0;
    double proteinSum = 0;
    double carbSum = 0;
    double fatSum = 0;
    double sodiumSum = 0;

    for (final entry in dayEntries) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _entryPortionFactor(entry);
      totalWeight += weight;
      final range = _parseCalorieRange(entry.overrideCalorieRange ?? result.calorieRange);
      if (range != null) {
        minSum += range[0] * weight;
        maxSum += range[1] * weight;
      }
      proteinSum += (result.macros['protein'] ?? 0) * weight;
      carbSum += (result.macros['carbs'] ?? 0) * weight;
      fatSum += (result.macros['fat'] ?? 0) * weight;
      sodiumSum += (result.macros['sodium'] ?? 0) * weight;
    }

    if (totalWeight == 0) return null;
    final macros = <String, double>{
      'protein': proteinSum,
      'carbs': carbSum,
      'fat': fatSum,
      'sodium': sodiumSum,
    };
    final calorieRange = minSum > 0 && maxSum > 0 ? '${minSum.round()}-${maxSum.round()} kcal' : t.calorieUnknown;
    final advice = _buildMealAdvice(macros, calorieRange, t);
    return MealSummary(calorieRange: calorieRange, macros: macros, advice: advice);
  }

  Future<MealEntry?> addEntryFromFiles(
    List<XFile> files,
    String locale, {
    String? note,
    MealType? fixedType,
    DateTime? overrideTime,
  }) async {
    if (files.isEmpty) return null;
    if (files.length == 1) {
      return addEntry(files.first, locale, note: note, fixedType: fixedType, overrideTime: overrideTime);
    }
    final List<MealEntry> created = [];
    DateTime? anchorTime;
    for (final file in files) {
      final originalBytes = await file.readAsBytes();
      final time = overrideTime ?? await _resolveImageTime(file, originalBytes);
      anchorTime ??= time;
      final bytes = _compressImageBytes(originalBytes);
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
        updatedAt: DateTime.now().toUtc(),
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
    for (final entry in created) {
      await _analyzeEntry(entry, locale, reason: 'new_entry');
    }
    return created.isNotEmpty ? created.first : null;
  }

  Future<MealEntry?> addEntry(
    XFile xfile,
    String locale, {
    String? note,
    MealType? fixedType,
    DateTime? overrideTime,
  }) async {
    final originalBytes = await xfile.readAsBytes();
    final time = overrideTime ?? await _resolveImageTime(xfile, originalBytes);
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
      updatedAt: DateTime.now().toUtc(),
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
      entry.lastAnalyzedAt = anchor.lastAnalyzedAt;
      entry.lastAnalyzeReason = anchor.lastAnalyzeReason;
      await _store.upsert(entry);
      notifyListeners();
      return entry;
    }
    await _analyzeEntry(entry, locale, reason: 'new_entry');
    return entry;
  }

  Future<void> updateEntryNote(MealEntry entry, String note, String locale) async {
    entry.note = note.trim().isEmpty ? null : note.trim();
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    await _store.upsert(entry);
    _scheduleAnalyze(entry, locale, reason: 'note_changed');
  }

  void updateEntryTime(MealEntry entry, DateTime time) {
    final oldMealId = entry.mealId ?? entry.id;
    final oldDate = _dateOnly(entry.time);
    final locale = profile.language;
    entry.time = time;
    entry.type = resolveMealType(time);
    entry.mealId = _assignMealId(time, entry.type);
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    _store.upsert(entry);
    if (oldMealId != (entry.mealId ?? entry.id)) {
      final oldKey = _mealKey(oldMealId);
      if (_mealOverrides.containsKey(oldKey)) {
        _mealOverrides.remove(oldKey);
      }
      final newKey = _mealKey(entry.mealId ?? entry.id);
      if (_mealOverrides.containsKey(newKey)) {
        _mealOverrides.remove(newKey);
      }
      _saveOverrides();
      // Recompute advice for the old meal group if it still exists.
      final oldGroup = entriesForMealId(oldMealId);
      if (oldGroup.isNotEmpty) {
        // ignore: discarded_futures
        _scheduleMealAdviceRefresh(oldMealId, locale);
      }
    }
    _scheduleAnalyze(entry, locale, force: true, reason: 'time_changed');
    _refreshDaySummaryForDate(oldDate, locale);
    _refreshDaySummaryForDate(_dateOnly(entry.time), locale);
  }

  void updateEntryPortionPercent(MealEntry entry, int percent) {
    final next = percent.clamp(10, 200);
    if (next == entry.portionPercent) {
      return;
    }
    entry.portionPercent = next;
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    _store.upsert(entry);
  }

  void updateEntryContainer(MealEntry entry, String? type, String? size) {
    final nextType = (type ?? '').trim().isEmpty ? null : type!.trim();
    final nextSize = (size ?? '').trim().isEmpty ? null : size!.trim();
    if (nextType == entry.containerType && nextSize == entry.containerSize) {
      return;
    }
    entry.containerType = nextType;
    entry.containerSize = nextSize;
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    _store.upsert(entry);
  }

  void updateEntryCalorieOverride(MealEntry entry, String? range) {
    final cleaned = (range ?? '').trim();
    final next = cleaned.isEmpty ? null : cleaned;
    if (next == entry.overrideCalorieRange) {
      return;
    }
    entry.overrideCalorieRange = next;
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    notifyListeners();
    _store.upsert(entry);
  }

  Future<void> addLabelToEntry(MealEntry entry, XFile file, String locale) async {
    entry.loading = true;
    entry.error = null;
    notifyListeners();
    try {
      final originalBytes = await file.readAsBytes();
      final bytes = _compressImageBytes(originalBytes);
      final filename = file.name.isNotEmpty ? file.name : 'label.jpg';
      final labelResult = await _api.analyzeLabel(
        bytes,
        filename,
        accessToken: _accessToken(),
        lang: locale,
      );
      entry.labelImageBytes = bytes;
      entry.labelFilename = filename;
      entry.labelResult = labelResult;
      entry.updatedAt = DateTime.now().toUtc();
      if (entry.result != null) {
        final custom = _findCustomFoodByName(entry.overrideFoodName);
        entry.result = _resolveNutritionResult(entry.result!, custom: custom, label: labelResult);
      } else {
        final fallbackName = (entry.overrideFoodName ?? '').trim().isNotEmpty
            ? entry.overrideFoodName!.trim()
            : (labelResult.labelName ?? '').trim().isNotEmpty
                ? labelResult.labelName!.trim()
                : entry.filename;
        entry.result = AnalysisResult(
          foodName: fallbackName,
          calorieRange: labelResult.calorieRange,
          macros: labelResult.macros,
          dishSummary: '',
          suggestion: '',
          tier: 'label',
          source: 'label',
          nutritionSource: 'label',
          confidence: labelResult.confidence,
          isBeverage: labelResult.isBeverage,
        );
      }
      await _store.upsert(entry);
      notifyListeners();
      await _analyzeEntry(entry, locale, force: true, reason: 'label_added');
    } catch (e) {
      entry.error = e.toString();
    } finally {
      entry.loading = false;
      notifyListeners();
      await _store.upsert(entry);
    }
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
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    final custom = _findCustomFoodByName(entry.overrideFoodName);
    if (entry.result != null) {
      entry.result = _resolveNutritionResult(entry.result!, custom: custom, label: entry.labelResult);
    }
    notifyListeners();
    await _store.upsert(entry);
    _scheduleAnalyze(entry, locale, reason: 'name_changed');
  }

  void removeEntry(MealEntry entry) {
    final mealId = entry.mealId ?? entry.id;
    final date = _dateOnly(entry.time);
    final now = DateTime.now().toUtc();
    _deletedEntries[entry.id] = {
      'id': entry.id,
      'time': entry.time.toIso8601String(),
      'type': _mealTypeKey(entry.type),
      'filename': entry.filename,
      'deleted_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    entries.remove(entry);
    notifyListeners();
    // ignore: discarded_futures
    _store.delete(entry.id);
    // ignore: discarded_futures
    _saveOverrides();

    final mealKey = _mealKey(mealId);
    if (_mealOverrides.containsKey(mealKey)) {
      _mealOverrides.remove(mealKey);
      // ignore: discarded_futures
      _saveOverrides();
    }

    if (entriesForMealId(mealId).isNotEmpty) {
      // ignore: discarded_futures
      _refreshMealAdviceForMealId(mealId, profile.language);
    }
    // Recompute day summary if the day was finalized or has overrides.
    // ignore: discarded_futures
    _refreshDaySummaryForDate(date, profile.language);
  }

  void updateProfile(UserProfile updated) {
    profile
      ..name = updated.name
      ..email = updated.email
      ..gender = updated.gender
      ..containerType = updated.containerType
      ..containerSize = updated.containerSize
      ..containerDepth = updated.containerDepth
      ..containerDiameterCm = updated.containerDiameterCm
      ..containerCapacityMl = updated.containerCapacityMl
      ..tone = updated.tone
      ..persona = updated.persona
      ..activityLevel = updated.activityLevel
      ..heightCm = updated.heightCm
      ..weightKg = updated.weightKg
      ..age = updated.age
      ..goal = updated.goal
      ..planSpeed = updated.planSpeed
      ..dailySummaryTime = updated.dailySummaryTime
      ..weeklySummaryWeekday = updated.weeklySummaryWeekday
      ..lunchReminderEnabled = updated.lunchReminderEnabled
      ..dinnerReminderEnabled = updated.dinnerReminderEnabled
      ..lunchReminderTime = updated.lunchReminderTime
      ..dinnerReminderTime = updated.dinnerReminderTime
      ..language = updated.language
      ..apiBaseUrl = updated.apiBaseUrl
      ..plateAsset = updated.plateAsset
      ..themeAsset = updated.themeAsset
      ..textScale = updated.textScale
      ..nutritionChartStyle = updated.nutritionChartStyle
      ..glowEnabled = updated.glowEnabled;
    notifyListeners();
    _touchSettingsUpdatedAt();
    // ignore: unawaited_futures
    _saveProfile();
    // ignore: unawaited_futures
    _saveOverrides();
  }

  void updateField(void Function(UserProfile profile) updater) {
    updater(profile);
    notifyListeners();
    _scheduleAutoFinalize();
    _scheduleAutoFinalizeWeek();
    _touchSettingsUpdatedAt();
    // ignore: unawaited_futures
    _saveProfile();
    // ignore: unawaited_futures
    _saveOverrides();
  }

  void updateMealTimeField(void Function(UserProfile profile) updater) {
    updater(profile);
    notifyListeners();
    _scheduleAutoFinalize();
    _scheduleAutoFinalizeWeek();
    _touchSettingsUpdatedAt();
    // ignore: unawaited_futures
    _saveProfile();
    // ignore: unawaited_futures
    _saveOverrides();
    // ignore: unawaited_futures
    _reassignMealTypesForAllEntries();
  }

  Future<void> _analyzeEntry(
    MealEntry entry,
    String locale, {
    bool force = false,
    String reason = 'auto',
  }) async {
    final noteKey = entry.note ?? '';
    final nameKey = entry.overrideFoodName ?? '';
    if (!force &&
        entry.result != null &&
        entry.lastAnalyzedNote == noteKey &&
        entry.lastAnalyzedFoodName == nameKey) {
      return;
    }
    const allowedWhenLocked = {
      'manual',
      'portion_changed',
      'name_changed',
      'note_changed',
      'label_added',
      'new_entry',
      'quick_capture',
      'quick_capture_manual',
      'time_changed',
    };
    if (_isDayLocked(entry.time) && !allowedWhenLocked.contains(reason)) {
      return;
    }
    entry.loading = true;
    entry.error = null;
    notifyListeners();

    try {
      final mealTypeKey = _mealTypeKey(entry.type);
      final containerType = entry.containerType ?? profile.containerType;
      final containerSize = entry.containerSize ?? profile.containerSize;
      final AnalysisResult res = await _api.analyzeImage(
        entry.imageBytes,
        entry.filename,
        accessToken: _accessToken(),
        lang: locale,
        foodName: entry.overrideFoodName,
        note: entry.note,
        labelContext: _buildLabelContext(entry.labelResult),
        portionPercent: entry.portionPercent,
        analyzeReason: reason,
        containerType: containerType,
        containerSize: containerSize,
        containerDepth: profile.containerDepth,
        containerDiameterCm: profile.containerDiameterCm,
        containerCapacityMl: profile.containerCapacityMl,
        heightCm: profile.heightCm,
        weightKg: profile.weightKg,
        age: profile.age,
        gender: profile.gender,
        tone: profile.tone,
        persona: profile.persona,
        activityLevel: dailyActivityLevel(entry.time),
        targetCalorieRange: targetCalorieRangeValue(entry.time),
        goal: profile.goal,
        planSpeed: profile.planSpeed,
        mealType: mealTypeKey,
        mealPhotoCount: 1,
        forceReanalyze: force,
      );
      final custom = _findCustomFoodByName(entry.overrideFoodName);
      entry.result = _resolveNutritionResult(res, custom: custom, label: entry.labelResult);
      entry.lastAnalyzedNote = noteKey;
      entry.lastAnalyzedFoodName = nameKey;
      entry.lastAnalyzedAt = DateTime.now().toIso8601String();
      entry.lastAnalyzeReason = reason;
      entry.updatedAt = DateTime.now().toUtc();
    } catch (e) {
      entry.error = e.toString();
    } finally {
      entry.loading = false;
      notifyListeners();
      await _store.upsert(entry);
      const refreshMealAdviceReasons = {
        'manual',
        'name_changed',
        'note_changed',
        'label_added',
        'portion_changed',
        'time_changed',
      };
      if (force && entry.error == null && refreshMealAdviceReasons.contains(reason)) {
        await _refreshMealAdviceForEntry(entry, locale);
      }
      const refreshDaySummaryReasons = {
        'manual',
        'name_changed',
        'note_changed',
        'label_added',
        'portion_changed',
        'time_changed',
      };
      if (entry.error == null && refreshDaySummaryReasons.contains(reason)) {
        await _refreshDaySummaryForEntry(entry, locale);
      }
    }
  }

  Future<void> removeLabelFromEntry(MealEntry entry, String locale) async {
    entry.loading = true;
    entry.error = null;
    notifyListeners();
    entry.labelImageBytes = null;
    entry.labelFilename = null;
    entry.labelResult = null;
    await _store.upsert(entry);
    notifyListeners();
    await _analyzeEntry(entry, locale, force: true, reason: 'label_removed');
    entry.loading = false;
    notifyListeners();
    await _store.upsert(entry);
  }

  Future<void> _refreshMealAdviceForEntry(MealEntry entry, String locale) async {
    final mealId = entry.mealId ?? entry.id;
    _scheduleMealAdviceRefresh(mealId, locale);
  }

  void _scheduleMealAdviceRefresh(String mealId, String locale) {
    _mealAdviceTimers[mealId]?.cancel();
    _mealAdviceTimers[mealId] = Timer(const Duration(seconds: 60), () {
      _mealAdviceTimers.remove(mealId);
      // ignore: discarded_futures
      _refreshMealAdviceForMealId(mealId, locale);
    });
  }

  Future<void> _refreshMealAdviceForMealId(String mealId, String locale) async {
    final key = _mealKey(mealId);
    if (_mealOverrides.containsKey(key)) {
      _mealOverrides.remove(key);
      await _saveOverrides();
    }
    final t = lookupAppLocalizations(Locale.fromSubtags(languageCode: locale.split('-').first));
    final group = entriesForMealId(mealId);
    if (group.isEmpty) return;
    await ensureMealAdviceForGroup(group, t, locale);
  }

  Future<void> _refreshDaySummaryForEntry(MealEntry entry, String locale) async {
    final date = _dateOnly(entry.time);
    final t = lookupAppLocalizations(Locale.fromSubtags(languageCode: locale.split('-').first));
    await _refreshDaySummaryForDate(date, locale, t: t);
  }

  Future<void> _refreshDaySummaryForDate(DateTime date, String locale, {AppLocalizations? t}) async {
    final key = _dayKey(date);
    if (!_isDayLocked(date) && !_dayOverrides.containsKey(key)) {
      return;
    }
    final resolved = t ?? lookupAppLocalizations(Locale.fromSubtags(languageCode: locale.split('-').first));
    await finalizeDay(date, locale, resolved);
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

  void _scheduleAnalyze(
    MealEntry entry,
    String locale, {
    bool force = false,
    String reason = 'auto',
  }) {
    final key = entry.id;
    _analysisTimers[key]?.cancel();
    if (force) {
      _analysisTimerForce[key] = true;
    }
    _analysisTimerReason[key] = reason;
    _analysisTimers[key] = Timer(const Duration(minutes: 1), () {
      final doForce = _analysisTimerForce.remove(key) ?? false;
      final analyzeReason = _analysisTimerReason.remove(key) ?? reason;
      _analysisTimers.remove(key);
      // ignore: discarded_futures
      _analyzeEntry(entry, locale, force: doForce, reason: analyzeReason);
    });
  }

  Future<void> reanalyzeEntry(MealEntry entry, String locale) async {
    await _analyzeEntry(entry, locale, force: true, reason: 'manual');
  }

  String _hashBytes(List<int> bytes) {
    return sha1.convert(bytes).toString();
  }

  double _macroBaselineForKey(String key) {
    switch (key) {
      case 'protein':
        return _kMacroBaselineProteinG;
      case 'carbs':
        return _kMacroBaselineCarbsG;
      case 'fat':
        return _kMacroBaselineFatG;
      case 'sodium':
        return _kMacroBaselineSodiumMg;
      default:
        return 0;
    }
  }

  double _macroPercentFromGramsValue(
    double grams,
    String key, {
    double? calories,
    double baselineMultiplier = 1.0,
  }) {
    if (key == 'sodium') {
      final baseline = _kMacroBaselineSodiumMg * baselineMultiplier;
      if (baseline <= 0) return 0;
      return (grams / baseline) * 100;
    }
    if (calories != null && calories > 0) {
      final kcal = key == 'fat' ? grams * 9 : grams * 4;
      return (kcal / calories) * 100;
    }
    final baseline = _macroBaselineForKey(key) * baselineMultiplier;
    if (baseline <= 0) return 0;
    return (grams / baseline) * 100;
  }

  Map<String, double> _macroPercentMapFromGrams(Map<String, double> grams, String? calorieRange,
      {double baselineMultiplier = 1.0}) {
    final calories = calorieRangeMid(calorieRange);
    return {
      'protein': _macroPercentFromGramsValue(grams['protein'] ?? 0, 'protein',
          calories: calories, baselineMultiplier: baselineMultiplier),
      'carbs': _macroPercentFromGramsValue(grams['carbs'] ?? 0, 'carbs',
          calories: calories, baselineMultiplier: baselineMultiplier),
      'fat': _macroPercentFromGramsValue(grams['fat'] ?? 0, 'fat',
          calories: calories, baselineMultiplier: baselineMultiplier),
      'sodium': _macroPercentFromGramsValue(grams['sodium'] ?? 0, 'sodium',
          calories: calories, baselineMultiplier: baselineMultiplier),
    };
  }

  double macroPercentFromResult(AnalysisResult result, String key) {
    return _macroPercentFromGramsValue(
      result.macros[key] ?? 0,
      key,
      calories: calorieRangeMid(result.calorieRange),
    );
  }

  Map<String, double> _percentMacrosToGrams(Map<String, double> percentMacros) {
    final protein = (percentMacros['protein'] ?? 0) / 100;
    final carbs = (percentMacros['carbs'] ?? 0) / 100;
    final fat = (percentMacros['fat'] ?? 0) / 100;
    final sodium = (percentMacros['sodium'] ?? 0) / 100;
    return {
      'protein': _kMacroBaselineProteinG * protein,
      'carbs': _kMacroBaselineCarbsG * carbs,
      'fat': _kMacroBaselineFatG * fat,
      'sodium': _kMacroBaselineSodiumMg * sodium,
    };
  }

  bool _maybeMigrateMacrosToGrams() {
    final unit = _meta[_kMacroUnitMetaKey];
    if (unit == _kMacroUnitGrams) {
      return false;
    }
    bool looksLikeGrams = false;
    bool checkMacros(Map<String, double> macros) {
      if (macros.isEmpty) return false;
      final protein = macros['protein'] ?? 0;
      final carbs = macros['carbs'] ?? 0;
      final fat = macros['fat'] ?? 0;
      final sodium = macros['sodium'] ?? 0;
      return protein > 100 || carbs > 100 || fat > 100 || sodium > 120;
    }
    for (final entry in entries) {
      if (entry.result != null && checkMacros(entry.result!.macros)) {
        looksLikeGrams = true;
        break;
      }
      if (entry.labelResult != null && checkMacros(entry.labelResult!.macros)) {
        looksLikeGrams = true;
        break;
      }
    }
    if (!looksLikeGrams) {
      for (final food in customFoods) {
        if (checkMacros(food.macros)) {
          looksLikeGrams = true;
          break;
        }
      }
    }
    if (looksLikeGrams) {
      _meta[_kMacroUnitMetaKey] = _kMacroUnitGrams;
      return false;
    }
    bool changed = false;
    for (final entry in entries) {
      final result = entry.result;
      if (result != null && result.macros.isNotEmpty) {
        entry.result = AnalysisResult(
          foodName: result.foodName,
          calorieRange: result.calorieRange,
          macros: _percentMacrosToGrams(result.macros),
          foodItems: result.foodItems,
          judgementTags: result.judgementTags,
          dishSummary: result.dishSummary,
          suggestion: result.suggestion,
          tier: result.tier,
          source: result.source,
          nutritionSource: result.nutritionSource,
          aiOriginalCalorieRange: result.aiOriginalCalorieRange,
          aiOriginalMacros: result.aiOriginalMacros == null ? null : _percentMacrosToGrams(result.aiOriginalMacros!),
          costEstimateUsd: result.costEstimateUsd,
          confidence: result.confidence,
          isBeverage: result.isBeverage,
        );
        changed = true;
      }
      final label = entry.labelResult;
      if (label != null && label.macros.isNotEmpty) {
        entry.labelResult = LabelResult(
          labelName: label.labelName,
          calorieRange: label.calorieRange,
          macros: _percentMacrosToGrams(label.macros),
          isBeverage: label.isBeverage,
          confidence: label.confidence,
        );
        changed = true;
      }
    }
    for (final food in customFoods) {
      if (food.macros.isNotEmpty) {
        food.macros = _percentMacrosToGrams(food.macros);
        changed = true;
      }
    }
    _meta[_kMacroUnitMetaKey] = _kMacroUnitGrams;
    return changed;
  }

  double _aggregateMacroScore(List<MealEntry> dayEntries, String key, AppLocalizations t) {
    double totalWeight = 0;
    double score = 0;
    for (final entry in dayEntries) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _entryPortionFactor(entry);
      final calories = calorieRangeMid(result.calorieRange);
      totalWeight += weight;
      final percent = _macroPercentFromGramsValue(
        result.macros[key] ?? 0,
        key,
        calories: calories,
        baselineMultiplier: 1.0,
      );
      score += _levelScorePercent(percent) * weight;
    }
    if (totalWeight == 0) return 0;
    return score / totalWeight;
  }

  double _aggregateMacroPercentPlain(List<MealEntry> dayEntries, String key) {
    double totalWeight = 0;
    double gramsSum = 0;
    double caloriesSum = 0;
    bool hasCalories = false;
    for (final entry in dayEntries) {
      final result = entry.result;
      if (result == null) continue;
      final weight = _entryPortionFactor(entry);
      totalWeight += weight;
      gramsSum += (result.macros[key] ?? 0) * weight;
      final calories = calorieRangeMid(result.calorieRange);
      if (calories != null && calories > 0) {
        caloriesSum += calories * weight;
        hasCalories = true;
      }
    }
    if (totalWeight == 0) return 0;
    final calories = hasCalories ? caloriesSum : null;
    return _macroPercentFromGramsValue(
      gramsSum,
      key,
      calories: calories,
      baselineMultiplier: totalWeight,
    );
  }

  String? _buildLabelContext(LabelResult? labelResult) {
    if (labelResult == null) return null;
    final calories = labelResult.calorieRange.trim();
    final macros = labelResult.macros;
    if (calories.isEmpty && macros.isEmpty) return null;
    final parts = <String>[];
    if (calories.isNotEmpty) {
      parts.add('calorie_range=$calories');
    }
    if (macros.isNotEmpty) {
      parts.add(
        'macros=protein_g:${macros['protein']?.round() ?? 0}, carbs_g:${macros['carbs']?.round() ?? 0}, fat_g:${macros['fat']?.round() ?? 0}, sodium_mg:${macros['sodium']?.round() ?? 0}',
      );
    }
    if (labelResult.labelName != null && labelResult.labelName!.trim().isNotEmpty) {
      parts.add('label_name=${labelResult.labelName!.trim()}');
    }
    return 'nutrition_label: ${parts.join(' | ')}';
  }

  CustomFood? _findCustomFoodByName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    for (final item in customFoods) {
      if (item.name.trim() == trimmed) {
        return item;
      }
    }
    return null;
  }

  AnalysisResult _resolveNutritionResult(
    AnalysisResult base, {
    CustomFood? custom,
    LabelResult? label,
  }) {
    final originalCalories = base.aiOriginalCalorieRange ?? base.calorieRange;
    final originalMacros = base.aiOriginalMacros ?? base.macros;
    final isBeverage = base.isBeverage;
    if (custom != null) {
      final customName = custom.name.trim();
      return AnalysisResult(
        foodName: customName.isEmpty ? base.foodName : customName,
        calorieRange: custom.calorieRange,
        macros: Map<String, double>.from(custom.macros),
        foodItems: base.foodItems,
        judgementTags: base.judgementTags,
        dishSummary: custom.summary.trim().isNotEmpty ? custom.summary : base.dishSummary,
        suggestion: custom.suggestion.trim().isNotEmpty ? custom.suggestion : base.suggestion,
        tier: base.tier,
        source: base.source,
        nutritionSource: 'custom',
        aiOriginalCalorieRange: originalCalories,
        aiOriginalMacros: Map<String, double>.from(originalMacros),
        costEstimateUsd: base.costEstimateUsd,
        confidence: base.confidence,
        isBeverage: isBeverage,
      );
    }
    if (label != null) {
      final calorieRange = label.calorieRange.trim().isNotEmpty ? label.calorieRange : base.calorieRange;
      final macros = label.macros.isNotEmpty ? label.macros : base.macros;
      return AnalysisResult(
        foodName: base.foodName,
        calorieRange: calorieRange,
        macros: macros,
        foodItems: base.foodItems,
        judgementTags: base.judgementTags,
        dishSummary: base.dishSummary,
        suggestion: base.suggestion,
        tier: base.tier,
        source: base.source,
        nutritionSource: 'label',
        aiOriginalCalorieRange: originalCalories,
        aiOriginalMacros: Map<String, double>.from(originalMacros),
        costEstimateUsd: base.costEstimateUsd,
        confidence: base.confidence,
        isBeverage: label.isBeverage ?? isBeverage,
      );
    }
    final resolvedSource = base.nutritionSource ??
        (base.source == 'label'
            ? 'label'
            : base.source == 'custom'
                ? 'custom'
                : 'ai');
    return AnalysisResult(
      foodName: base.foodName,
      calorieRange: base.calorieRange,
      macros: base.macros,
      foodItems: base.foodItems,
      judgementTags: base.judgementTags,
      dishSummary: base.dishSummary,
      suggestion: base.suggestion,
      tier: base.tier,
      source: base.source,
      nutritionSource: resolvedSource,
      aiOriginalCalorieRange: base.aiOriginalCalorieRange,
      aiOriginalMacros: base.aiOriginalMacros == null ? null : Map<String, double>.from(base.aiOriginalMacros!),
      costEstimateUsd: base.costEstimateUsd,
      confidence: base.confidence,
      isBeverage: isBeverage,
    );
  }

  MealEntry? _findMealAnchor(MealEntry entry) {
    if ((entry.note ?? '').trim().isNotEmpty) return null;
    if ((entry.overrideFoodName ?? '').trim().isNotEmpty) return null;
    for (final existing in entries) {
      if (existing.id == entry.id) continue;
      if (existing.imageHash == null || existing.imageHash != entry.imageHash) continue;
      if (existing.result == null) continue;
      if ((existing.overrideFoodName ?? '').trim().isNotEmpty) continue;
      if ((existing.note ?? '').trim().isNotEmpty) continue;
      return existing;
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
    final rangeMatch = RegExp(r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)').firstMatch(value);
    if (rangeMatch != null) {
      final minVal = double.tryParse(rangeMatch.group(1)!);
      final maxVal = double.tryParse(rangeMatch.group(2)!);
      if (minVal == null || maxVal == null) return null;
      return [minVal.round(), maxVal.round()];
    }
    final singleMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    if (singleMatch == null) return null;
    final singleVal = double.tryParse(singleMatch.group(1)!);
    if (singleVal == null) return null;
    final rounded = singleVal.round();
    return [rounded, rounded];
  }

  double _portionWeight(int percent) {
    final safe = percent.clamp(10, 200);
    return safe / 100.0;
  }

  double _entryPortionFactor(MealEntry entry) {
    final portion = _portionWeight(entry.portionPercent);
    final sizeRaw = (entry.containerSize ?? '').trim();
    final typeRaw = (entry.containerType ?? '').trim();
    final size = sizeRaw.isEmpty ? profile.containerSize : sizeRaw;
    final type = typeRaw.isEmpty ? profile.containerType : typeRaw;
    return portion * _containerSizeFactorFor(size) * _containerTypeFactorFor(type);
  }

  double _containerSizeFactorFor(String? size) {
    final value = (size ?? '').toLowerCase();
    switch (value) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      case 'medium':
      default:
        return 1.0;
    }
  }

  double _containerTypeFactorFor(String? type) {
    final value = (type ?? '').toLowerCase();
    switch (value) {
      case 'plate':
        return 1.1;
      case 'box':
        return 1.05;
      case 'cup':
        return 0.9;
      case 'bowl':
      case 'unknown':
      default:
        return 1.0;
    }
  }

  Future<void> _reassignMealTypesForAllEntries() async {
    if (entries.isEmpty) return;
    final affectedMealIds = <String>{};
    final affectedDates = <DateTime>{};
    for (final entry in entries) {
      final oldMealId = entry.mealId ?? entry.id;
      final oldDate = _dateOnly(entry.time);
      final newType = resolveMealType(entry.time);
      final newMealId = _assignMealId(entry.time, newType);
      if (entry.type == newType && oldMealId == newMealId) {
        continue;
      }
      entry.type = newType;
      entry.mealId = newMealId;
      affectedMealIds.add(oldMealId);
      affectedMealIds.add(newMealId);
      affectedDates.add(oldDate);
      affectedDates.add(_dateOnly(entry.time));
      await _store.upsert(entry);
    }
    if (affectedMealIds.isNotEmpty) {
      for (final mealId in affectedMealIds) {
        _mealOverrides.remove(_mealKey(mealId));
      }
      await _saveOverrides();
      for (final mealId in affectedMealIds) {
        if (entriesForMealId(mealId).isNotEmpty) {
          // ignore: discarded_futures
          _refreshMealAdviceForMealId(mealId, profile.language);
        }
      }
    }
    for (final date in affectedDates) {
      // ignore: discarded_futures
      _refreshDaySummaryForDate(date, profile.language);
    }
  }

  Map<String, double> scaledMacrosForEntry(MealEntry entry) {
    final macros = entry.result?.macros;
    if (macros == null) return {};
    final weight = _entryPortionFactor(entry);
    return {
      'protein': (macros['protein'] ?? 0) * weight,
      'carbs': (macros['carbs'] ?? 0) * weight,
      'fat': (macros['fat'] ?? 0) * weight,
      'sodium': (macros['sodium'] ?? 0) * weight,
    };
  }

  double _levelScorePercent(double value) {
    if (value >= 70) return 3.0;
    if (value <= 35) return 1.0;
    return 2.0;
  }

  bool _isHigh(double value) => value >= 70;
  bool _isLow(double value) => value <= 35;
  bool _isProteinOk(double value) => value >= 45;

  String _scoreToLevel(double score, AppLocalizations t) {
    if (score <= 1.6) return t.levelLow;
    if (score >= 2.4) return t.levelHigh;
    return t.levelMedium;
  }

  String _buildMealAdvice(Map<String, double> macros, String calorieRange, AppLocalizations t) {
    final advice = <String>[];
    final percentMap = _macroPercentMapFromGrams(macros, calorieRange);
    final protein = percentMap['protein'] ?? 0;
    final fat = percentMap['fat'] ?? 0;
    final carbs = percentMap['carbs'] ?? 0;
    final sodium = percentMap['sodium'] ?? 0;
    if (_isLow(protein)) advice.add(t.dietitianProteinLow);
    if (_isHigh(fat)) advice.add(t.dietitianFatHigh);
    if (_isHigh(carbs)) advice.add(t.dietitianCarbHigh);
    if (_isHigh(sodium)) advice.add(t.dietitianSodiumHigh);
    final line = advice.isEmpty ? t.dietitianBalanced : advice.take(2).join('、');
    final goalLower = profile.goal.toLowerCase();
    final loseFat = profile.goal == t.goalLoseFat ||
        goalLower.contains('減脂') ||
        goalLower.contains('lose');
    final goalHint = loseFat ? t.goalAdviceLoseFat : t.goalAdviceMaintain;
    return '${t.dietitianPrefix}$line ${goalHint}';
  }

  bool _isSmallPortion(MealEntry entry) {
    return entry.portionPercent <= _kSmallPortionThreshold;
  }

  String _portionNoteSeparator(AppLocalizations t) {
    return t.localeName.startsWith('en') ? ', ' : '，';
  }

  String _applyPortionNote(String text, MealEntry entry, AppLocalizations t) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_isSmallPortion(entry)) return trimmed;
    if (trimmed.contains(t.smallPortionNote)) return trimmed;
    return '${t.smallPortionNote}${_portionNoteSeparator(t)}$trimmed';
  }

  String? _entryDishSummary(MealEntry entry, AppLocalizations t) {
    final summaryText = entry.result?.dishSummary?.trim();
    if (summaryText != null && summaryText.isNotEmpty) {
      return _applyPortionNote(summaryText, entry, t);
    }
    final fallback = entry.overrideFoodName ?? entry.result?.foodName ?? '';
    if (fallback.trim().isEmpty) return null;
    return _applyPortionNote(fallback.trim(), entry, t);
  }

  String _buildMealDishSummary(List<MealEntry> group, AppLocalizations t) {
    final summaries = <String>[];
    final seen = <String>{};
    for (final entry in group) {
      final text = _entryDishSummary(entry, t);
      if (text == null || text.isEmpty) continue;
      if (seen.add(text)) {
        summaries.add(text);
      }
    }
    if (summaries.isEmpty) return '';
    if (summaries.length > 3) return t.multiItemsLabel;
    return summaries.join('、');
  }

  List<String> _collapseDishSummaries(List<String> items, AppLocalizations t, {int maxItems = 3}) {
    if (items.length > maxItems) {
      return [t.multiItemsLabel];
    }
    return items;
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

  String _dayLockKey(DateTime date) {
    final d = _dateOnly(date);
    return 'day_finalized:${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool _isDayLocked(DateTime date) {
    return _meta.containsKey(_dayLockKey(date));
  }

  String _exerciseTypeKey(DateTime date) {
    final d = _dateOnly(date);
    return 'exercise_type:${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _exerciseMinutesKey(DateTime date) {
    final d = _dateOnly(date);
    return 'exercise_minutes:${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _activityKey(DateTime date) {
    final d = _dateOnly(date);
    return 'activity:${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _mealKey(String mealId) => 'meal:$mealId';

  void _loadOverrides(Map<String, dynamic> overrides) {
    final day = overrides['day'] as Map<String, dynamic>?;
    final meal = overrides['meal'] as Map<String, dynamic>?;
    final week = overrides['week'] as Map<String, dynamic>?;
    final meta = overrides['meta'] as Map<String, dynamic>?;
    final deleted = overrides['deleted_entries'] as Map<String, dynamic>?;
    final deletedCustom = overrides['deleted_custom_foods'] as Map<String, dynamic>?;
    final failedMeals = overrides['failed_meal_sync_ids'];
    final failedMealDeletes = overrides['failed_meal_delete_sync_ids'];
    final failedCustomFoods = overrides['failed_custom_food_sync_ids'];
    final failedCustomDeletes = overrides['failed_custom_food_delete_sync_ids'];
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
    if (week != null) {
      week.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _weekOverrides[key] = value.map((k, v) => MapEntry(k, v.toString()));
        }
      });
    }
    if (meta != null) {
      meta.forEach((key, value) {
        _meta[key] = value.toString();
      });
    }
    _deletedEntries.clear();
    if (deleted != null) {
      deleted.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _deletedEntries[key] = Map<String, dynamic>.from(value);
        }
      });
    }
    _deletedCustomFoods.clear();
    if (deletedCustom != null) {
      deletedCustom.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _deletedCustomFoods[key] = Map<String, dynamic>.from(value);
        }
      });
    }
    _failedMealSyncIds
      ..clear()
      ..addAll(_parseIdList(failedMeals));
    _failedMealDeleteSyncIds
      ..clear()
      ..addAll(_parseIdList(failedMealDeletes));
    _failedCustomFoodSyncIds
      ..clear()
      ..addAll(_parseIdList(failedCustomFoods));
    _failedCustomFoodDeleteSyncIds
      ..clear()
      ..addAll(_parseIdList(failedCustomDeletes));
    final custom = overrides['custom_foods'];
    customFoods.clear();
    if (custom is List) {
      for (final item in custom) {
        if (item is Map<String, dynamic>) {
          try {
            customFoods.add(CustomFood.fromJson(item));
          } catch (_) {}
        }
      }
    }
  }

  Future<MealAdvice> suggestNowMealAdvice(AppLocalizations t, String locale) async {
    final now = DateTime.now();
    final mealType = resolveMealType(now);
    final mealDate = _dateOnly(now);
    final dayGroups = mealGroupsForDateAll(mealDate);
    final daySummary = buildDaySummary(mealDate, t);
    final consumedKcal = dailyConsumedCalorieMid(mealDate).round();
    final targetMid = targetCalorieMid(mealDate);
    final remainingKcal = targetMid == null ? null : (targetMid - consumedKcal).round();
    Map<String, double>? lastMealMacros;
    if (dayGroups.isNotEmpty) {
      final lastGroup = dayGroups.first;
      final lastSummary = buildMealSummary(lastGroup, t);
      lastMealMacros = lastSummary?.macros;
    }
    final recentAdvice = _collectRecentMealAdvice(mealDate, t);
    final dishSummaries = <String>[];
    for (final dayGroup in dayGroups) {
      for (final entry in dayGroup) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
        }
      }
    }
    final collapsedSummaries = _collapseDishSummaries(dishSummaries, t);
    final dayMealSummaries = <String>[];
    for (final dayGroup in dayGroups) {
      if (dayGroup.isEmpty) continue;
      final daySummary = buildMealSummary(dayGroup, t);
      final dayDishSummaries = <String>[];
      for (final entry in dayGroup) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dayDishSummaries.add(summaryText);
        }
      }
      final label = _mealTypeLabel(dayGroup.first.type, t);
      final rangeText = daySummary?.calorieRange ?? t.calorieUnknown;
      final collapsedDaySummaries = _collapseDishSummaries(dayDishSummaries, t);
      final dishText = collapsedDaySummaries.isEmpty ? '' : collapsedDaySummaries.join(' / ');
      final parts = <String>[label];
      if (rangeText.isNotEmpty) parts.add(rangeText);
      if (dishText.isNotEmpty) parts.add(dishText);
      dayMealSummaries.add(parts.join(' · '));
    }
    final payload = {
      'meal_type': _mealTypeKey(mealType),
      'calorie_range': '',
      'dish_summaries': collapsedSummaries,
      'day_calorie_range': _dailyCalorieRangeLabelForDate(mealDate, t),
      'day_meal_count': dayGroups.length,
      'day_meal_summaries': dayMealSummaries,
      'today_consumed_kcal': consumedKcal > 0 ? consumedKcal : null,
      'today_remaining_kcal': remainingKcal,
      'today_macros': daySummary?.macros.isNotEmpty == true ? _roundMacros(daySummary!.macros) : null,
      'last_meal_macros': lastMealMacros == null || lastMealMacros.isEmpty ? null : _roundMacros(lastMealMacros),
      'recent_advice': recentAdvice.isEmpty ? null : recentAdvice,
      'lang': locale,
      'profile': {
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'age': profile.age,
        'gender': profile.gender,
        'container_type': profile.containerType,
        'container_size': profile.containerSize,
        'container_depth': profile.containerDepth,
        'container_diameter_cm': profile.containerDiameterCm,
        'container_capacity_ml': profile.containerCapacityMl,
        'diet_type': profile.dietType,
        'diet_note': profile.dietNote,
        'tone': profile.tone,
        'persona': profile.persona,
        'activity_level': dailyActivityLevel(now),
        'target_calorie_range': targetCalorieRangeValue(now),
        'goal': profile.goal,
        'plan_speed': profile.planSpeed,
      },
    };
    try {
      final response = await _api.suggestMeal(payload, _accessToken());
      return MealAdvice(
        selfCook: (response['self_cook'] as String?) ?? t.nextSelfCookHint,
        convenience: (response['convenience'] as String?) ?? t.nextConvenienceHint,
        bento: (response['bento'] as String?) ?? t.nextBentoHint,
        other: (response['other'] as String?) ?? t.nextOtherHint,
      );
    } catch (_) {
      return MealAdvice.defaults(t);
    }
  }

  Map<String, int> _roundMacros(Map<String, double> macros) {
    return {
      'protein': (macros['protein'] ?? 0).round(),
      'carbs': (macros['carbs'] ?? 0).round(),
      'fat': (macros['fat'] ?? 0).round(),
      'sodium': (macros['sodium'] ?? 0).round(),
    };
  }

  List<String> _collectRecentMealAdvice(DateTime date, AppLocalizations t) {
    final defaults = MealAdvice.defaults(t);
    final items = <String>[];
    final seen = <String>{};
    for (int i = 0; i < 7; i++) {
      final day = date.subtract(Duration(days: i));
      final groups = mealGroupsForDateAll(day);
      for (final group in groups) {
        if (group.isEmpty) continue;
        final advice = mealAdviceForGroup(group, t);
        final isDefault = advice.selfCook == defaults.selfCook &&
            advice.convenience == defaults.convenience &&
            advice.bento == defaults.bento &&
            advice.other == defaults.other;
        if (isDefault) continue;
        final text =
            'self_cook:${advice.selfCook} | convenience:${advice.convenience} | bento:${advice.bento} | other:${advice.other}';
        if (seen.add(text)) {
          items.add(text);
        }
        if (items.length >= 12) return items;
      }
    }
    return items;
  }

  Future<void> signUpSupabase(String email, String password, {String? nickname}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) return;
    final trimmedNickname = (nickname ?? '').trim();
    await _supabase.client.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: trimmedNickname.isEmpty ? null : {'nickname': trimmedNickname},
      emailRedirectTo: kSupabaseEmailRedirectUrl,
    );
    if (trimmedNickname.isNotEmpty) {
      updateField((p) => p.name = trimmedNickname);
    }
    _applySupabaseNickname(_supabase.currentUser);
    await refreshAccessStatus();
    notifyListeners();
  }

  Future<void> signInSupabase(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) return;
    await _supabase.client.auth.signInWithPassword(email: trimmedEmail, password: password);
    _applySupabaseNickname(_supabase.currentUser);
    await refreshAccessStatus();
    notifyListeners();
  }

  Future<void> resendVerificationEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return;
    await _supabase.client.auth.resend(
      type: OtpType.signup,
      email: trimmedEmail,
      emailRedirectTo: kSupabaseEmailRedirectUrl,
    );
  }

  Future<void> signOutSupabase() async {
    await _supabase.client.auth.signOut();
    await refreshAccessStatus();
    notifyListeners();
  }

  Future<void> resetSupabasePassword(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return;
    await _supabase.client.auth.resetPasswordForEmail(
      trimmedEmail,
      redirectTo: kSupabaseEmailRedirectUrl,
    );
  }

  Future<void> updateNickname(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return;
    updateField((p) => p.name = trimmed);
    if (!isSupabaseSignedIn) return;
    try {
      await _supabase.client.auth.updateUser(
        UserAttributes(data: {'nickname': trimmed}),
      );
    } catch (_) {}
  }

  void _applySupabaseNickname(User? user) {
    if (user == null) return;
    final data = user.userMetadata ?? const <String, dynamic>{};
    if (data is Map<String, dynamic>) {
      final nickname = data['nickname'];
      if (nickname is String && nickname.trim().isNotEmpty) {
        updateField((p) => p.name = nickname.trim());
      }
    }
  }

  Future<bool> syncToSupabase({SyncReport? report}) async {
    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('Supabase not signed in');
    }
    final since = _localSyncAt();
    final entriesToSync = (since == null
            ? entries
            : entries.where((entry) => entry.updatedAt != null && entry.updatedAt!.isAfter(since)))
        .where((entry) => entry.id.isNotEmpty)
        .toList();
    for (final entry in entries) {
      if (_failedMealSyncIds.contains(entry.id) && !entriesToSync.any((e) => e.id == entry.id)) {
        entriesToSync.add(entry);
      }
    }
    final foodsToSync = (since == null ? customFoods : customFoods.where((food) => food.updatedAt.isAfter(since)))
        .where((food) => food.id.isNotEmpty)
        .toList();
    for (final food in customFoods) {
      if (_failedCustomFoodSyncIds.contains(food.id) && !foodsToSync.any((f) => f.id == food.id)) {
        foodsToSync.add(food);
      }
    }
    final deletionsToSync = _deletedEntries.values.where((value) {
      final raw = value['deleted_at'];
      if (raw is! String || raw.isEmpty) return true;
      final ts = DateTime.tryParse(raw);
      if (ts == null) return true;
      return since == null || ts.isAfter(since);
    }).toList();
    for (final deleted in _deletedEntries.values) {
      final id = deleted['id'];
      if (id is String && _failedMealDeleteSyncIds.contains(id) && !deletionsToSync.contains(deleted)) {
        deletionsToSync.add(deleted);
      }
    }
    final customDeletionsToSync = _deletedCustomFoods.values.where((value) {
      final raw = value['deleted_at'];
      if (raw is! String || raw.isEmpty) return true;
      final ts = DateTime.tryParse(raw);
      if (ts == null) return true;
      return since == null || ts.isAfter(since);
    }).toList();
    for (final deleted in _deletedCustomFoods.values) {
      final id = deleted['id'];
      if (id is String &&
          _failedCustomFoodDeleteSyncIds.contains(id) &&
          !customDeletionsToSync.contains(deleted)) {
        customDeletionsToSync.add(deleted);
      }
    }
    final settingsUpdatedAt = _settingsUpdatedAt();
    final settingsToSync = settingsUpdatedAt != null && (since == null || settingsUpdatedAt.isAfter(since));
    final hasChanges = entriesToSync.isNotEmpty ||
        foodsToSync.isNotEmpty ||
        deletionsToSync.isNotEmpty ||
        customDeletionsToSync.isNotEmpty ||
        settingsToSync;
    if (!hasChanges) return false;
    final client = _supabase.client;
    final mealPayloads = <Map<String, dynamic>>[];
    try {
      for (final entry in entriesToSync) {
        final imageHash = entry.imageHash ?? _hashBytes(entry.imageBytes);
        final imagePath = await _uploadImageIfNeeded(
          bucket: kSupabaseMealImagesBucket,
          path: '${user.id}/meals/$imageHash.jpg',
          bytes: entry.imageBytes,
        );
        String? labelPath;
        if (entry.labelImageBytes != null) {
          final labelHash = _hashBytes(entry.labelImageBytes!);
          labelPath = await _uploadImageIfNeeded(
            bucket: kSupabaseLabelImagesBucket,
            path: '${user.id}/labels/$labelHash.jpg',
            bytes: entry.labelImageBytes!,
          );
        }
        final payload = _mealEntryToRow(entry, user.id, imagePath, labelPath);
        mealPayloads.add(payload);
      }
    } catch (_) {
      _failedMealSyncIds.addAll(entriesToSync.map((e) => e.id));
      await _saveOverrides();
      rethrow;
    }
    for (final deleted in deletionsToSync) {
      mealPayloads.add({
        'id': deleted['id'],
        'user_id': user.id,
        'time': deleted['time'],
        'type': deleted['type'],
        'filename': deleted['filename'],
        'deleted_at': deleted['deleted_at'],
        'updated_at': deleted['updated_at'],
      });
    }
    if (mealPayloads.isNotEmpty) {
      try {
        await client.from(kSupabaseMealsTable).upsert(mealPayloads).select('id');
        _failedMealSyncIds.removeAll(entriesToSync.map((e) => e.id));
        _failedMealDeleteSyncIds.removeAll(
          deletionsToSync.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty),
        );
        if (report != null) {
          report.pushedMeals += entriesToSync.length;
          report.pushedMealDeletes += deletionsToSync.length;
        }
      } catch (_) {
        _failedMealSyncIds.addAll(entriesToSync.map((e) => e.id));
        _failedMealDeleteSyncIds.addAll(
          deletionsToSync.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty),
        );
        await _saveOverrides();
        rethrow;
      }
    }
    final foodPayloads = <Map<String, dynamic>>[];
    try {
      for (final food in foodsToSync) {
        final imageHash = _hashBytes(food.imageBytes);
        final imagePath = await _uploadImageIfNeeded(
          bucket: kSupabaseMealImagesBucket,
          path: '${user.id}/custom/$imageHash.jpg',
          bytes: food.imageBytes,
        );
        final payload = {
          'id': food.id,
          'user_id': user.id,
          'name': food.name,
          'summary': food.summary,
          'calorie_range': food.calorieRange,
          'suggestion': food.suggestion,
          'macros': food.macros,
          'image_path': imagePath,
          'created_at': food.createdAt.toIso8601String(),
          'updated_at': food.updatedAt.toIso8601String(),
          'deleted_at': null,
        };
        foodPayloads.add(payload);
      }
    } catch (_) {
      _failedCustomFoodSyncIds.addAll(foodsToSync.map((e) => e.id));
      await _saveOverrides();
      rethrow;
    }
    if (foodPayloads.isNotEmpty) {
      try {
        await client.from(kSupabaseCustomFoodsTable).upsert(foodPayloads).select('id');
        _failedCustomFoodSyncIds.removeAll(foodsToSync.map((e) => e.id));
        if (report != null) {
          report.pushedCustomFoods += foodsToSync.length;
        }
      } catch (_) {
        _failedCustomFoodSyncIds.addAll(foodsToSync.map((e) => e.id));
        await _saveOverrides();
        rethrow;
      }
    }
    if (customDeletionsToSync.isNotEmpty) {
      final deletePayloads = <Map<String, dynamic>>[];
      try {
        for (final deleted in customDeletionsToSync) {
          final id = deleted['id'];
          if (id is! String || id.isEmpty) continue;
          final imageBytes = _extractCustomFoodBytes(deleted);
          String? imagePath;
          if (imageBytes != null && imageBytes.isNotEmpty) {
            final imageHash = _hashBytes(imageBytes);
            imagePath = await _uploadImageIfNeeded(
              bucket: kSupabaseMealImagesBucket,
              path: '${user.id}/custom/$imageHash.jpg',
              bytes: imageBytes,
            );
          }
          deletePayloads.add({
            'id': id,
            'user_id': user.id,
            'name': (deleted['name'] as String?) ?? '',
            'summary': (deleted['summary'] as String?) ?? '',
            'calorie_range': (deleted['calorie_range'] as String?) ?? '',
            'suggestion': (deleted['suggestion'] as String?) ?? '',
            'macros': deleted['macros'] ?? {},
            'image_path': imagePath,
            'created_at': deleted['created_at'],
            'updated_at': deleted['updated_at'],
            'deleted_at': deleted['deleted_at'],
          });
        }
      } catch (_) {
        _failedCustomFoodDeleteSyncIds.addAll(
          customDeletionsToSync.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty),
        );
        await _saveOverrides();
        rethrow;
      }
      if (deletePayloads.isNotEmpty) {
        try {
          await client.from(kSupabaseCustomFoodsTable).upsert(deletePayloads).select('id');
          _failedCustomFoodDeleteSyncIds.removeAll(
            customDeletionsToSync.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty),
          );
          if (report != null) {
            report.pushedCustomDeletes += deletePayloads.length;
          }
        } catch (_) {
          _failedCustomFoodDeleteSyncIds.addAll(
            customDeletionsToSync.map((e) => (e['id'] ?? '').toString()).where((id) => id.isNotEmpty),
          );
          await _saveOverrides();
          rethrow;
        }
      }
    }
    if (settingsToSync && settingsUpdatedAt != null) {
      final settingsPayload = {
        'user_id': user.id,
        'profile_json': _profileToSyncMap(),
        'overrides_json': _settingsOverridesToSyncMap(),
        'updated_at': settingsUpdatedAt.toIso8601String(),
        'deleted_at': null,
      };
      await client.from(kSupabaseUserSettingsTable).upsert(settingsPayload).select('user_id');
      if (report != null) {
        report.pushedSettings += 1;
      }
    }
    if (deletionsToSync.isNotEmpty) {
      for (final deleted in deletionsToSync) {
        final id = deleted['id'];
        if (id is String) {
          _deletedEntries.remove(id);
        }
      }
    }
    if (customDeletionsToSync.isNotEmpty) {
      for (final deleted in customDeletionsToSync) {
        final id = deleted['id'];
        if (id is String) {
          _deletedCustomFoods.remove(id);
        }
      }
    }
    _meta['last_sync_fingerprint'] = _syncFingerprint();
    await _saveOverrides();
    return hasChanges;
  }

  Future<void> syncFromSupabase({SyncReport? report}) async {
    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('Supabase not signed in');
    }
    final client = _supabase.client;
    final settingsRow = await _fetchRemoteSettingsRow(user.id);
    if (settingsRow != null) {
      final remoteUpdatedAt = DateTime.tryParse(settingsRow['updated_at'] as String? ?? '');
      final localUpdatedAt = _settingsUpdatedAt();
      if (remoteUpdatedAt != null && (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
        final profileJson = settingsRow['profile_json'];
        if (profileJson is Map<String, dynamic>) {
          _applyProfile(profileJson);
        } else if (profileJson is Map) {
          _applyProfile(profileJson.map((k, v) => MapEntry(k.toString(), v)));
        }
        final overridesJson = settingsRow['overrides_json'];
        if (overridesJson is Map<String, dynamic>) {
          _applySettingsOverrides(overridesJson);
        } else if (overridesJson is Map) {
          _applySettingsOverrides(overridesJson.map((k, v) => MapEntry(k.toString(), v)));
        }
        _meta[_kSettingsUpdatedAtKey] = remoteUpdatedAt.toIso8601String();
        await _saveProfile();
        await _saveOverrides();
        _scheduleAutoFinalize();
        _scheduleAutoFinalizeWeek();
        notifyListeners();
        if (report != null) {
          report.pulledSettings += 1;
        }
      }
    }
    final since = _localSyncAt();
    final existingEntries = {
      for (final entry in entries) entry.id: entry,
    };
    final query = client.from(kSupabaseMealsTable).select().eq('user_id', user.id);
    final rows = since == null
        ? await query
        : await query.or('updated_at.gt.${since.toIso8601String()},deleted_at.gt.${since.toIso8601String()}');
    if (rows is List) {
      final remoteIds = <String>{};
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final entryId = row['id'] as String?;
        if (entryId != null) {
          remoteIds.add(entryId);
        }
        final deletedAt = row['deleted_at'] as String?;
        final remoteUpdatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
        if (deletedAt != null && deletedAt.isNotEmpty) {
        if (entryId != null) {
          final existing = existingEntries[entryId];
          if (existing != null &&
              existing.updatedAt != null &&
              remoteUpdatedAt != null &&
              existing.updatedAt!.isAfter(remoteUpdatedAt)) {
            _failedMealSyncIds.add(entryId);
            continue;
          }
          final index = entries.indexWhere((item) => item.id == entryId);
          if (index != -1) {
            entries.removeAt(index);
            // ignore: discarded_futures
            _store.delete(entryId);
            if (report != null) report.pulledMealDeletes += 1;
          }
        }
        continue;
      }
        final existing = entryId == null ? null : existingEntries[entryId];
        if (existing != null &&
            existing.updatedAt != null &&
            remoteUpdatedAt != null &&
            existing.updatedAt!.isAfter(remoteUpdatedAt)) {
          _failedMealSyncIds.add(existing.id);
          continue;
        }
        final imagePath = row['image_path'] as String?;
        final labelPath = row['label_image_path'] as String?;
        Uint8List? imageBytes;
        if (existing != null && existing.imageBytes.isNotEmpty && existing.imageHash == row['image_hash']) {
          imageBytes = existing.imageBytes;
        } else {
          imageBytes = await _downloadImageIfAvailable(
            bucket: kSupabaseMealImagesBucket,
            path: imagePath,
          );
        }
        final resolvedImageBytes = imageBytes ?? _namePlaceholderBytes;
        Uint8List? labelBytes;
        if (existing != null && existing.labelImageBytes != null && labelPath != null && labelPath.isNotEmpty) {
          labelBytes = existing.labelImageBytes;
        } else {
          labelBytes = await _downloadImageIfAvailable(
            bucket: kSupabaseLabelImagesBucket,
            path: labelPath,
          );
        }
        final entry = _mealEntryFromRow(row, resolvedImageBytes, labelBytes);
        final index = entries.indexWhere((item) => item.id == entry.id);
        if (index == -1) {
          entries.insert(0, entry);
          if (report != null) report.pulledMeals += 1;
        } else {
          entries[index] = entry;
          if (report != null) report.pulledMeals += 1;
        }
        await _store.upsert(entry);
      }
      if (since == null) {
        // Remove local entries that no longer exist remotely (full sync only)
        final toRemove = entries.where((e) => !remoteIds.contains(e.id)).toList();
        if (toRemove.isNotEmpty) {
          for (final entry in toRemove) {
            entries.remove(entry);
            // ignore: discarded_futures
            _store.delete(entry.id);
          }
        }
      }
    }
    final existingFoods = {
      for (final food in customFoods) food.id: food,
    };
    final foodQuery = client.from(kSupabaseCustomFoodsTable).select().eq('user_id', user.id);
    final foodRows = since == null
        ? await foodQuery
        : await foodQuery
            .or('updated_at.gt.${since.toIso8601String()},deleted_at.gt.${since.toIso8601String()}');
    if (foodRows is List) {
      final remoteFoodIds = <String>{};
      for (final row in foodRows) {
        if (row is! Map<String, dynamic>) continue;
        final foodId = row['id'] as String?;
        if (foodId != null) {
          remoteFoodIds.add(foodId);
        }
        final deletedAt = row['deleted_at'] as String?;
        final remoteUpdatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
        if (deletedAt != null && deletedAt.isNotEmpty) {
          if (foodId != null) {
            final existing = existingFoods[foodId];
            if (existing != null && remoteUpdatedAt != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
              _failedCustomFoodSyncIds.add(foodId);
              continue;
            }
            if (report != null) report.pulledCustomDeletes += 1;
          }
          continue;
        }
        final existing = foodId == null ? null : existingFoods[foodId];
        if (existing != null && remoteUpdatedAt != null && existing.updatedAt.isAfter(remoteUpdatedAt)) {
          _failedCustomFoodSyncIds.add(existing.id);
          continue;
        }
        final imagePath = row['image_path'] as String?;
        final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
        Uint8List? bytes;
        if (existing != null && updatedAt != null && existing.updatedAt.isAtSameMomentAs(updatedAt)) {
          bytes = existing.imageBytes;
        } else {
          bytes = await _downloadImageIfAvailable(
            bucket: kSupabaseMealImagesBucket,
            path: imagePath,
          );
        }
        if (bytes == null) continue;
        final food = CustomFood(
          id: row['id'] as String,
          name: (row['name'] as String?) ?? '',
          summary: (row['summary'] as String?) ?? '',
          calorieRange: (row['calorie_range'] as String?) ?? '',
          suggestion: (row['suggestion'] as String?) ?? '',
          macros: _parseMacros(row['macros']),
          imageBytes: bytes,
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
        );
        final index = customFoods.indexWhere((item) => item.id == food.id);
        if (index == -1) {
          customFoods.add(food);
          if (report != null) report.pulledCustomFoods += 1;
        } else {
          customFoods[index] = food;
          if (report != null) report.pulledCustomFoods += 1;
        }
      }
      if (since == null) {
        final toRemove = existingFoods.keys.where((id) => !remoteFoodIds.contains(id)).toList();
        if (toRemove.isNotEmpty) {
          for (final id in toRemove) {
            // keep storage in sync; overrides will be saved below
            customFoods.removeWhere((food) => food.id == id);
          }
        }
      }
      notifyListeners();
      await _saveOverrides();
    }
    notifyListeners();
  }

  void setSyncInProgress(bool value) {
    if (_syncing == value) return;
    _syncing = value;
    notifyListeners();
  }

  Future<bool> syncAuto() async {
    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('Supabase not signed in');
    }
    final report = SyncReport();
    final beforeFingerprint = _syncFingerprint();
    final localSyncAt = _localSyncAt();
    final remoteSyncAt = await _fetchRemoteSyncAt(user.id);
    final localSettingsUpdatedAt = _settingsUpdatedAt();
    final remoteSettingsUpdatedAt = await _fetchRemoteSettingsUpdatedAt(user.id);
    final hasLocalSettings = localSettingsUpdatedAt != null;
    final hasLocalData = entries.isNotEmpty || customFoods.isNotEmpty;

    if (remoteSyncAt == null) {
      if (!hasLocalData && !hasLocalSettings) return false;
      final changed = await syncToSupabase(report: report);
      if (changed) {
        final now = DateTime.now().toUtc();
        await _storeRemoteSyncAt(user.id, now);
        await _storeLocalSyncAt(now);
      }
      _lastSyncReport = report;
      return changed;
    }

    bool changed = false;
    // 1) Always push local changes first (if any)
    final pushed = await syncToSupabase(report: report);
    if (pushed) {
      changed = true;
      final now = DateTime.now().toUtc();
      await _storeRemoteSyncAt(user.id, now);
      await _storeLocalSyncAt(now);
    }

    // 2) Then pull remote changes
    final updatedRemoteSyncAt = await _fetchRemoteSyncAt(user.id);
    final shouldPullData =
        updatedRemoteSyncAt != null && (localSyncAt == null || updatedRemoteSyncAt.isAfter(localSyncAt));
    final shouldPullSettings = remoteSettingsUpdatedAt != null &&
        (localSettingsUpdatedAt == null || remoteSettingsUpdatedAt.isAfter(localSettingsUpdatedAt));
    final shouldPull = shouldPullData || shouldPullSettings;
    if (shouldPull) {
      await syncFromSupabase(report: report);
      if (updatedRemoteSyncAt != null && (localSyncAt == null || updatedRemoteSyncAt.isAfter(localSyncAt))) {
        await _storeLocalSyncAt(updatedRemoteSyncAt);
      }
      changed = true;
    }

    // 3) Update fingerprint after sync to avoid stale "no change" state
    _meta['last_sync_fingerprint'] = _syncFingerprint();
    await _saveOverrides();
    _lastSyncReport = report;
    return changed;
  }

  String _syncFingerprint() {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer
        ..write(entry.id)
        ..write('|')
        ..write(entry.time.toIso8601String())
        ..write('|')
        ..write(entry.type.name)
        ..write('|')
        ..write(entry.portionPercent)
        ..write('|')
        ..write(entry.mealId ?? '')
        ..write('|')
        ..write(entry.note ?? '')
        ..write('|')
        ..write(entry.overrideFoodName ?? '')
        ..write('|')
        ..write(entry.imageHash ?? '')
        ..write('|')
        ..write(entry.lastAnalyzedAt ?? '')
        ..write('|')
        ..write(entry.lastAnalyzeReason ?? '')
        ..write('|')
        ..write(entry.result?.calorieRange ?? '')
        ..write('|')
        ..write(entry.result?.suggestion ?? '')
        ..write('|')
        ..write(entry.updatedAt?.toIso8601String() ?? '')
        ..write('||');
    }
    for (final deleted in _deletedEntries.values) {
      buffer
        ..write(deleted['id'] ?? '')
        ..write('|')
        ..write(deleted['deleted_at'] ?? '')
        ..write('|')
        ..write(deleted['updated_at'] ?? '')
        ..write('||');
    }
    for (final deleted in _deletedCustomFoods.values) {
      buffer
        ..write(deleted['id'] ?? '')
        ..write('|')
        ..write(deleted['deleted_at'] ?? '')
        ..write('|')
        ..write(deleted['updated_at'] ?? '')
        ..write('||');
    }
    for (final food in customFoods) {
      buffer
        ..write(food.id)
        ..write('|')
        ..write(food.name)
        ..write('|')
        ..write(food.summary)
        ..write('|')
        ..write(food.calorieRange)
        ..write('|')
        ..write(food.suggestion)
        ..write('|')
        ..write(food.updatedAt.toIso8601String())
        ..write('||');
    }
    final bytes = utf8.encode(buffer.toString());
    return sha1.convert(bytes).toString();
  }

  DateTime? _localSyncAt() {
    final raw = _meta['last_sync_at'];
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _storeLocalSyncAt(DateTime time) async {
    _meta['last_sync_at'] = time.toIso8601String();
    await _saveOverrides();
  }

  Future<DateTime?> _fetchRemoteSyncAt(String userId) async {
    final row = await _supabase.client
        .from('sync_meta')
        .select('last_sync_at')
        .eq('user_id', userId)
        .maybeSingle();
    if (row is! Map<String, dynamic>) return null;
    final raw = row['last_sync_at'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<Map<String, dynamic>?> _fetchRemoteSettingsRow(String userId) async {
    final row = await _supabase.client
        .from(kSupabaseUserSettingsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row is Map<String, dynamic>) return row;
    return null;
  }

  Future<DateTime?> _fetchRemoteSettingsUpdatedAt(String userId) async {
    final row = await _supabase.client
        .from(kSupabaseUserSettingsTable)
        .select('updated_at')
        .eq('user_id', userId)
        .maybeSingle();
    if (row is! Map<String, dynamic>) return null;
    final raw = row['updated_at'] as String?;
    return raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
  }

  Future<void> _storeRemoteSyncAt(String userId, DateTime time) async {
    await _supabase.client.from('sync_meta').upsert({
      'user_id': userId,
      'last_sync_at': time.toIso8601String(),
    }).select('user_id');
    final confirm = await _fetchRemoteSyncAt(userId);
    if (confirm == null || confirm.isBefore(time)) {
      throw Exception('sync_meta_write_failed');
    }
  }

  Future<String?> _uploadImageIfNeeded({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    final String result = await _supabase.client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true),
        ).timeout(const Duration(seconds: 12));
    if (result.isEmpty) {
      throw Exception('storage_upload_failed');
    }
    return path;
  }

  Future<Uint8List?> _downloadImageIfAvailable({
    required String bucket,
    required String? path,
  }) async {
    if (path == null || path.isEmpty) return null;
    try {
      final data = await _supabase.client.storage.from(bucket).download(path);
      return data;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _mealEntryToRow(MealEntry entry, String userId, String? imagePath, String? labelPath) {
    return {
      'id': entry.id,
      'user_id': userId,
      'time': entry.time.toIso8601String(),
      'type': _mealTypeKey(entry.type),
      'filename': entry.filename,
      'portion_percent': entry.portionPercent,
      'override_calorie_range': entry.overrideCalorieRange,
      'container_type': entry.containerType,
      'container_size': entry.containerSize,
      'meal_id': entry.mealId,
      'note': entry.note,
      'override_food_name': entry.overrideFoodName,
      'image_hash': entry.imageHash,
      'updated_at': (entry.updatedAt ?? entry.time.toUtc()).toIso8601String(),
      'deleted_at': entry.deletedAt?.toIso8601String(),
      'image_path': imagePath,
      'label_image_path': labelPath,
      'result_json': entry.result?.toJson(),
      'label_json': entry.labelResult?.toJson(),
      'last_analyzed_note': entry.lastAnalyzedNote,
      'last_analyzed_food_name': entry.lastAnalyzedFoodName,
      'last_analyzed_at': entry.lastAnalyzedAt,
      'last_analyze_reason': entry.lastAnalyzeReason,
    };
  }

  MealEntry _mealEntryFromRow(
    Map<String, dynamic> row,
    Uint8List imageBytes,
    Uint8List? labelBytes,
  ) {
    final entry = MealEntry(
      id: row['id'] as String,
      imageBytes: imageBytes,
      filename: (row['filename'] as String?) ?? 'photo.jpg',
      time: DateTime.parse(row['time'] as String),
      type: _mealTypeFromKey((row['type'] as String?) ?? 'other'),
      portionPercent: (row['portion_percent'] as num?)?.toInt() ?? 100,
      overrideCalorieRange: row['override_calorie_range'] as String?,
      containerType: row['container_type'] as String?,
      containerSize: row['container_size'] as String?,
      updatedAt: row['updated_at'] == null ? null : DateTime.tryParse(row['updated_at'] as String),
      deletedAt: row['deleted_at'] == null ? null : DateTime.tryParse(row['deleted_at'] as String),
      note: row['note'] as String?,
      overrideFoodName: row['override_food_name'] as String?,
      imageHash: row['image_hash'] as String?,
      mealId: row['meal_id'] as String?,
      lastAnalyzedNote: row['last_analyzed_note'] as String?,
      lastAnalyzedFoodName: row['last_analyzed_food_name'] as String?,
      lastAnalyzedAt: row['last_analyzed_at'] as String?,
      lastAnalyzeReason: row['last_analyze_reason'] as String?,
      labelImageBytes: labelBytes,
    );
    final resultJson = row['result_json'];
    if (resultJson is Map<String, dynamic>) {
      entry.result = AnalysisResult.fromJson(resultJson);
    }
    final labelJson = row['label_json'];
    if (labelJson is Map<String, dynamic>) {
      entry.labelResult = LabelResult.fromJson(labelJson);
    }
    entry.updatedAt ??= entry.time.toUtc();
    return entry;
  }

  Map<String, double> _parseMacros(dynamic raw) {
    final parsed = <String, double>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        final k = key.toString();
        if (value is num) {
          parsed[k] = value.toDouble();
        } else if (value is String) {
          var cleaned = value.trim().toLowerCase();
          cleaned = cleaned.replaceAll('公克', 'g').replaceAll('毫克', 'mg');
          cleaned = cleaned.replaceAll('%', '').replaceAll('kcal', '').trim();
          final isMg = cleaned.contains('mg');
          cleaned = cleaned.replaceAll('mg', '').replaceAll('g', '').trim();
          final numeric = double.tryParse(cleaned) ?? 0;
          if (k == 'sodium') {
            if (isMg) {
              parsed[k] = numeric;
            } else if (value.toString().toLowerCase().contains('g')) {
              parsed[k] = numeric * 1000;
            } else {
              parsed[k] = numeric; // no unit -> treat as mg
            }
          } else {
            parsed[k] = isMg ? numeric / 1000 : numeric;
          }
        }
      });
    }
    return parsed;
  }

  Uint8List? _extractCustomFoodBytes(Map<String, dynamic> deleted) {
    final raw = deleted['image_bytes'];
    if (raw is Uint8List) return raw;
    if (raw is List<int>) return Uint8List.fromList(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        return Uint8List.fromList(base64Decode(raw));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _saveOverrides() async {
    await _settings.saveOverrides({
      'day': _dayOverrides,
      'meal': _mealOverrides,
      'week': _weekOverrides,
      'meta': _meta,
      'deleted_entries': _deletedEntries,
      'deleted_custom_foods': _deletedCustomFoods,
      'failed_meal_sync_ids': _failedMealSyncIds.toList(),
      'failed_meal_delete_sync_ids': _failedMealDeleteSyncIds.toList(),
      'failed_custom_food_sync_ids': _failedCustomFoodSyncIds.toList(),
      'failed_custom_food_delete_sync_ids': _failedCustomFoodDeleteSyncIds.toList(),
      'custom_foods': customFoods.map((item) => item.toJson()).toList(),
    });
  }

  Iterable<String> _parseIdList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty);
    }
    return const [];
  }

  Locale _localeFromProfile() {
    return profile.language == 'en' ? const Locale('en') : const Locale('zh', 'TW');
  }

  void _scheduleAutoFinalize() {
    _autoFinalizeTimer?.cancel();
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, profile.dailySummaryTime.hour, profile.dailySummaryTime.minute);
    final next = now.isAfter(target) ? target.add(const Duration(days: 1)) : target;
    final delay = next.difference(now);
    _autoFinalizeTimer = Timer(delay, () {
      // ignore: discarded_futures
      autoFinalizeToday();
    });
  }

  void _scheduleAutoFinalizeWeek() {
    _autoWeeklyTimer?.cancel();
    final now = DateTime.now();
    final weekStart = _weekStartFor(now);
    final targetDate = weekStart.add(Duration(days: profile.weeklySummaryWeekday - 1));
    final target = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      profile.dailySummaryTime.hour,
      profile.dailySummaryTime.minute,
    );
    final next = now.isAfter(target) ? target.add(const Duration(days: 7)) : target;
    final delay = next.difference(now);
    _autoWeeklyTimer = Timer(delay, () {
      // ignore: discarded_futures
      autoFinalizeWeek();
    });
  }

  Future<void> _saveProfile() async {
    await _settings.saveProfile(_profileToMap());
  }

  void _touchSettingsUpdatedAt() {
    _meta[_kSettingsUpdatedAtKey] = DateTime.now().toUtc().toIso8601String();
  }

  DateTime? _settingsUpdatedAt() {
    final raw = _meta[_kSettingsUpdatedAtKey];
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, dynamic> _profileToSyncMap() {
    final data = _profileToMap();
    data.remove('email');
    data.remove('api_base_url');
    data.remove('plate_asset');
    data.remove('theme_asset');
    data.remove('text_scale');
    data.remove('nutrition_chart');
    data.remove('nutrition_value_mode');
    data.remove('glow_enabled');
    return data;
  }

  bool _isSettingsMetaKey(String key) {
    return key.startsWith('activity:') ||
        key.startsWith('exercise_type:') ||
        key.startsWith('exercise_minutes:') ||
        key.startsWith('day_finalized:');
  }

  Map<String, String> _settingsMetaToSync() {
    final filtered = <String, String>{};
    _meta.forEach((key, value) {
      if (_isSettingsMetaKey(key)) {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  Map<String, Map<String, String>> _parseOverridesSection(dynamic raw) {
    final parsed = <String, Map<String, String>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsed[key.toString()] = value.map((k, v) => MapEntry(k, v.toString()));
        } else if (value is Map) {
          parsed[key.toString()] = value.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      });
    }
    return parsed;
  }

  Map<String, dynamic> _settingsOverridesToSyncMap() {
    return {
      'day': _dayOverrides,
      'meal': _mealOverrides,
      'week': _weekOverrides,
      'meta': _settingsMetaToSync(),
    };
  }

  void _applySettingsOverrides(Map<String, dynamic> overrides) {
    final day = _parseOverridesSection(overrides['day']);
    final meal = _parseOverridesSection(overrides['meal']);
    final week = _parseOverridesSection(overrides['week']);
    final metaRaw = overrides['meta'];
    final meta = <String, String>{};
    if (metaRaw is Map) {
      metaRaw.forEach((key, value) {
        final k = key.toString();
        if (_isSettingsMetaKey(k)) {
          meta[k] = value.toString();
        }
      });
    }
    _dayOverrides
      ..clear()
      ..addAll(day);
    _mealOverrides
      ..clear()
      ..addAll(meal);
    _weekOverrides
      ..clear()
      ..addAll(week);
    _meta.removeWhere((key, _) => _isSettingsMetaKey(key));
    _meta.addAll(meta);
  }

  Map<String, dynamic> _profileToMap() {
    return {
      'name': profile.name,
      'email': profile.email,
      'gender': profile.gender,
      'container_type': profile.containerType,
      'container_size': profile.containerSize,
      'container_depth': profile.containerDepth,
      'container_diameter_cm': profile.containerDiameterCm,
      'container_capacity_ml': profile.containerCapacityMl,
      'diet_type': profile.dietType,
      'diet_note': profile.dietNote,
      'tone': profile.tone,
      'persona': profile.persona,
      'activity_level': profile.activityLevel,
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'age': profile.age,
      'goal': profile.goal,
      'plan_speed': profile.planSpeed,
      'daily_summary_time': _timeToString(profile.dailySummaryTime),
      'weekly_summary_weekday': profile.weeklySummaryWeekday,
      'lunch_reminder_enabled': profile.lunchReminderEnabled,
      'dinner_reminder_enabled': profile.dinnerReminderEnabled,
      'lunch_reminder_time': _timeToString(profile.lunchReminderTime),
      'dinner_reminder_time': _timeToString(profile.dinnerReminderTime),
      'breakfast_start': _timeToString(profile.breakfastStart),
      'breakfast_end': _timeToString(profile.breakfastEnd),
      'brunch_start': _timeToString(profile.brunchStart),
      'brunch_end': _timeToString(profile.brunchEnd),
      'lunch_start': _timeToString(profile.lunchStart),
      'lunch_end': _timeToString(profile.lunchEnd),
      'afternoon_tea_start': _timeToString(profile.afternoonTeaStart),
      'afternoon_tea_end': _timeToString(profile.afternoonTeaEnd),
      'dinner_start': _timeToString(profile.dinnerStart),
      'dinner_end': _timeToString(profile.dinnerEnd),
      'late_snack_start': _timeToString(profile.lateSnackStart),
      'late_snack_end': _timeToString(profile.lateSnackEnd),
      'language': profile.language,
      'api_base_url': profile.apiBaseUrl,
      'plate_asset': profile.plateAsset,
      'theme_asset': profile.themeAsset,
      'text_scale': profile.textScale,
      'nutrition_chart': profile.nutritionChartStyle,
      'nutrition_value_mode': profile.nutritionValueMode,
      'glow_enabled': profile.glowEnabled,
      'exercise_suggestion_type': profile.exerciseSuggestionType,
    };
  }

  void _applyProfile(Map<String, dynamic> data) {
    profile
      ..name = (data['name'] as String?) ?? profile.name
      ..email = (data['email'] as String?) ?? profile.email
      ..gender = (data['gender'] as String?) ?? profile.gender
      ..containerType = (data['container_type'] as String?) ?? profile.containerType
      ..containerSize = (data['container_size'] as String?) ?? profile.containerSize
      ..containerDepth = (data['container_depth'] as String?) ?? profile.containerDepth
      ..containerDiameterCm = _parseInt(data['container_diameter_cm'], profile.containerDiameterCm)
      ..containerCapacityMl = _parseInt(data['container_capacity_ml'], profile.containerCapacityMl)
      ..dietType = (data['diet_type'] as String?) ?? profile.dietType
      ..dietNote = (data['diet_note'] as String?) ?? profile.dietNote
      ..tone = (data['tone'] as String?) ?? profile.tone
      ..persona = (data['persona'] as String?) ?? profile.persona
      ..activityLevel = (data['activity_level'] as String?) ?? profile.activityLevel
      ..heightCm = _parseInt(data['height_cm'], profile.heightCm)
      ..weightKg = _parseInt(data['weight_kg'], profile.weightKg)
      ..age = _parseInt(data['age'], profile.age)
      ..goal = (data['goal'] as String?) ?? profile.goal
      ..planSpeed = (data['plan_speed'] as String?) ?? profile.planSpeed
      ..dailySummaryTime = _parseTime(data['daily_summary_time'] as String?, profile.dailySummaryTime)
      ..weeklySummaryWeekday = _parseInt(data['weekly_summary_weekday'], profile.weeklySummaryWeekday)
      ..lunchReminderEnabled = (data['lunch_reminder_enabled'] as bool?) ?? profile.lunchReminderEnabled
      ..dinnerReminderEnabled = (data['dinner_reminder_enabled'] as bool?) ?? profile.dinnerReminderEnabled
      ..lunchReminderTime = _parseTime(data['lunch_reminder_time'] as String?, profile.lunchReminderTime)
      ..dinnerReminderTime = _parseTime(data['dinner_reminder_time'] as String?, profile.dinnerReminderTime)
      ..breakfastStart = _parseTime(data['breakfast_start'] as String?, profile.breakfastStart)
      ..breakfastEnd = _parseTime(data['breakfast_end'] as String?, profile.breakfastEnd)
      ..brunchStart = _parseTime(data['brunch_start'] as String?, profile.brunchStart)
      ..brunchEnd = _parseTime(data['brunch_end'] as String?, profile.brunchEnd)
      ..lunchStart = _parseTime(data['lunch_start'] as String?, profile.lunchStart)
      ..lunchEnd = _parseTime(data['lunch_end'] as String?, profile.lunchEnd)
      ..afternoonTeaStart = _parseTime(data['afternoon_tea_start'] as String?, profile.afternoonTeaStart)
      ..afternoonTeaEnd = _parseTime(data['afternoon_tea_end'] as String?, profile.afternoonTeaEnd)
      ..dinnerStart = _parseTime(data['dinner_start'] as String?, profile.dinnerStart)
      ..dinnerEnd = _parseTime(data['dinner_end'] as String?, profile.dinnerEnd)
      ..lateSnackStart = _parseTime(data['late_snack_start'] as String?, profile.lateSnackStart)
      ..lateSnackEnd = _parseTime(data['late_snack_end'] as String?, profile.lateSnackEnd)
      ..language = (data['language'] as String?) ?? profile.language
      ..apiBaseUrl = (data['api_base_url'] as String?) ?? profile.apiBaseUrl
      ..plateAsset = (data['plate_asset'] as String?) ?? profile.plateAsset
      ..themeAsset = (data['theme_asset'] as String?) ?? profile.themeAsset
      ..textScale = (data['text_scale'] as num?)?.toDouble() ?? profile.textScale
      ..nutritionChartStyle = (data['nutrition_chart'] as String?) ?? profile.nutritionChartStyle
      ..nutritionValueMode = (data['nutrition_value_mode'] as String?) ?? profile.nutritionValueMode
      ..glowEnabled = (data['glow_enabled'] as bool?) ?? profile.glowEnabled
      ..exerciseSuggestionType = (data['exercise_suggestion_type'] as String?) ?? profile.exerciseSuggestionType;
    if (profile.nutritionValueMode == 'percent') {
      profile.nutritionValueMode = 'amount';
    }
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

  String _weekdayLabel(int weekday, AppLocalizations t) {
    switch (weekday) {
      case DateTime.monday:
        return t.weekdayMon;
      case DateTime.tuesday:
        return t.weekdayTue;
      case DateTime.wednesday:
        return t.weekdayWed;
      case DateTime.thursday:
        return t.weekdayThu;
      case DateTime.friday:
        return t.weekdayFri;
      case DateTime.saturday:
        return t.weekdaySat;
      case DateTime.sunday:
      default:
        return t.weekdaySun;
    }
  }

  DateTime _weekStartFor(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  String _weekKey(DateTime weekStart) {
    return '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  double _activityFactor(String level) {
    switch (level) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'high':
        return 1.725;
      default:
        return 1.375;
    }
  }

  double _exerciseMet(String type) {
    switch (type) {
      case 'walking':
        return 3.3;
      case 'jogging':
        return 7.0;
      case 'cycling':
        return 6.8;
      case 'swimming':
        return 7.0;
      case 'strength':
        return 5.0;
      case 'yoga':
        return 3.0;
      case 'hiit':
        return 8.5;
      case 'basketball':
        return 6.5;
      case 'hiking':
        return 6.0;
      default:
        return 0.0;
    }
  }

  int _roundTo50(int value) {
    return ((value / 50).round()) * 50;
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
  final Map<String, double> macros;
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
    required this.gender,
    required this.containerType,
    required this.containerSize,
    required this.containerDepth,
    required this.containerDiameterCm,
    required this.containerCapacityMl,
    required this.dietType,
    required this.dietNote,
    required this.tone,
    required this.persona,
    required this.activityLevel,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.goal,
    required this.planSpeed,
    required this.dailySummaryTime,
    required this.weeklySummaryWeekday,
    required this.lunchReminderEnabled,
    required this.dinnerReminderEnabled,
    required this.lunchReminderTime,
    required this.dinnerReminderTime,
    required this.breakfastStart,
    required this.breakfastEnd,
    required this.brunchStart,
    required this.brunchEnd,
    required this.lunchStart,
    required this.lunchEnd,
    required this.afternoonTeaStart,
    required this.afternoonTeaEnd,
    required this.dinnerStart,
    required this.dinnerEnd,
    required this.lateSnackStart,
    required this.lateSnackEnd,
    required this.language,
    required this.apiBaseUrl,
    required this.plateAsset,
    required this.themeAsset,
    required this.textScale,
    required this.nutritionChartStyle,
    required this.nutritionValueMode,
    required this.glowEnabled,
    required this.exerciseSuggestionType,
  });

  String name;
  String email;
  String gender;
  String containerType;
  String containerSize;
  String containerDepth;
  int containerDiameterCm;
  int containerCapacityMl;
  String dietType;
  String dietNote;
  String tone;
  String persona;
  String activityLevel;
  int heightCm;
  int weightKg;
  int age;
  String goal;
  String planSpeed;
  TimeOfDay dailySummaryTime;
  int weeklySummaryWeekday;
  bool lunchReminderEnabled;
  bool dinnerReminderEnabled;
  TimeOfDay lunchReminderTime;
  TimeOfDay dinnerReminderTime;
  TimeOfDay breakfastStart;
  TimeOfDay breakfastEnd;
  TimeOfDay brunchStart;
  TimeOfDay brunchEnd;
  TimeOfDay lunchStart;
  TimeOfDay lunchEnd;
  TimeOfDay afternoonTeaStart;
  TimeOfDay afternoonTeaEnd;
  TimeOfDay dinnerStart;
  TimeOfDay dinnerEnd;
  TimeOfDay lateSnackStart;
  TimeOfDay lateSnackEnd;
  String language;
  String apiBaseUrl;
  String plateAsset;
  String themeAsset;
  double textScale;
  String nutritionChartStyle;
  String nutritionValueMode;
  bool glowEnabled;
  String exerciseSuggestionType;

  factory UserProfile.initial() {
    return UserProfile(
      name: '小明',
      email: 'xiaoming123@gmail.com',
      gender: 'unspecified',
      containerType: 'bowl',
      containerSize: 'medium',
      containerDepth: 'medium',
      containerDiameterCm: 14,
      containerCapacityMl: 0,
      dietType: 'none',
      dietNote: '',
      tone: 'gentle',
      persona: 'nutritionist',
      activityLevel: 'light',
      heightCm: 170,
      weightKg: 72,
      age: 30,
      goal: '減脂',
      planSpeed: '穩定',
      dailySummaryTime: const TimeOfDay(hour: 21, minute: 0),
      weeklySummaryWeekday: DateTime.sunday,
      lunchReminderEnabled: true,
      dinnerReminderEnabled: true,
      lunchReminderTime: const TimeOfDay(hour: 12, minute: 15),
      dinnerReminderTime: const TimeOfDay(hour: 18, minute: 45),
      breakfastStart: const TimeOfDay(hour: 6, minute: 0),
      breakfastEnd: const TimeOfDay(hour: 10, minute: 0),
      brunchStart: const TimeOfDay(hour: 10, minute: 0),
      brunchEnd: const TimeOfDay(hour: 12, minute: 0),
      lunchStart: const TimeOfDay(hour: 12, minute: 0),
      lunchEnd: const TimeOfDay(hour: 14, minute: 0),
      afternoonTeaStart: const TimeOfDay(hour: 14, minute: 0),
      afternoonTeaEnd: const TimeOfDay(hour: 17, minute: 0),
      dinnerStart: const TimeOfDay(hour: 17, minute: 0),
      dinnerEnd: const TimeOfDay(hour: 20, minute: 30),
      lateSnackStart: const TimeOfDay(hour: 20, minute: 30),
      lateSnackEnd: const TimeOfDay(hour: 2, minute: 0),
      language: 'zh-TW',
      apiBaseUrl: kDefaultApiBaseUrl,
      plateAsset: kDefaultPlateAsset,
      themeAsset: kDefaultThemeAsset,
      textScale: kDefaultTextScale,
      nutritionChartStyle: 'bars',
      nutritionValueMode: 'amount',
      glowEnabled: true,
      exerciseSuggestionType: 'walking',
    );
  }
}

class SyncReport {
  int pushedMeals = 0;
  int pushedMealDeletes = 0;
  int pushedCustomFoods = 0;
  int pushedCustomDeletes = 0;
  int pushedSettings = 0;
  int pulledMeals = 0;
  int pulledMealDeletes = 0;
  int pulledCustomFoods = 0;
  int pulledCustomDeletes = 0;
  int pulledSettings = 0;

  bool get hasChanges =>
      pushedMeals > 0 ||
      pushedMealDeletes > 0 ||
      pushedCustomFoods > 0 ||
      pushedCustomDeletes > 0 ||
      pushedSettings > 0 ||
      pulledMeals > 0 ||
      pulledMealDeletes > 0 ||
      pulledCustomFoods > 0 ||
      pulledCustomDeletes > 0 ||
      pulledSettings > 0;
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
