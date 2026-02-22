import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:flutter/foundation.dart';
import 'package:storage_client/storage_client.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/analysis_result.dart';
import '../models/chat_message.dart';
import '../models/meal_entry.dart';
import '../models/label_result.dart';
import '../models/custom_food.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../config/supabase_config.dart';
import '../storage/meal_store.dart';
import '../storage/settings_store.dart';

const String kDefaultApiBaseUrl =
    'https://food-ai-app-production.up.railway.app';
const List<String> kDeprecatedApiBaseUrls = [
  'https://pharmacy-little-fever-attacked.trycloudflare.com',
  'https://sussex-oscar-southern-scanning.trycloudflare.com',
  'https://effectively-wild-oecd-weddings.trycloudflare.com',
];
const String kIapMonthlyId = 'com.foodieeye.subscription.monthly';
const String kIapYearlyId = 'com.foodieeye.subscription.yearly';
const String kDefaultPlateAsset = 'assets/plates/plate_Japanese_02.png';
const String kDefaultThemeAsset = 'assets/themes/theme_clean.json';
const double kDefaultTextScale = 1.0;
const String kGoalValueLoseFat = 'lose_fat';
const String kGoalValueMaintain = 'maintain';
const String kPlanSpeedValueStable = 'stable';
const String kPlanSpeedValueGentle = 'gentle';
const String _kMacroUnitMetaKey = 'macro_unit';
const String _kSettingsUpdatedAtKey = 'settings_updated_at';
const String _kMockSubscriptionKey = 'mock_subscription_active';
const String _kMockSubscriptionPlanKey = 'mock_subscription_plan';
const String _kIapSubscriptionKey = 'iap_subscription_active';
const String _kAccessCheckAtKey = 'access_check_at';
const String _kAccessGraceHoursKey = 'access_grace_hours';
const String _kAccessPlanKey = 'access_plan';
const String _kAccessEntitlementsKey = 'access_entitlements';
const String _kChatHistoryKey = 'chat_history';
const String _kChatSummaryKey = 'chat_summary';
const String _kMealReminderKeyPrefix = 'last_meal_reminder';
const int _kAccessGraceHoursDefault = 24;
const String _kEntitlementAnalyze = 'ai_analyze';
const String _kEntitlementChat = 'ai_chat';
const String _kEntitlementSummary = 'ai_summary';
const String _kEntitlementSuggest = 'ai_suggest';
const Set<String> _kAiEntitlements = {
  _kEntitlementAnalyze,
  _kEntitlementChat,
  _kEntitlementSummary,
  _kEntitlementSuggest,
};
const String _kMacroUnitGrams = 'grams';
const String _kMacroUnitPercent = 'percent';
const double _kMacroBaselineProteinG = 30;
const double _kMacroBaselineCarbsG = 80;
const double _kMacroBaselineFatG = 25;
const double _kMacroBaselineSodiumMg = 2300;
const int _kSmallPortionThreshold = 35;
const String _kNamePlaceholderBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/Pi3n1wAAAABJRU5ErkJggg==';

enum AppFeature {
  analyze,
  chat,
  summary,
  suggest,
}

class NameLookupException implements Exception {
  NameLookupException(this.code);
  final String code;

  @override
  String toString() => 'NameLookupException($code)';
}

class _BeverageProfile {
  const _BeverageProfile({
    required this.key,
    required this.nameZh,
    required this.nameEn,
    required this.tokens,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    required this.baseSodium,
    required this.fullSugarCarbs,
    required this.defaultSugarRatio,
    required this.sugarAdjustable,
  });

  final String key;
  final String nameZh;
  final String nameEn;
  final List<String> tokens;
  final double baseProtein;
  final double baseCarbs;
  final double baseFat;
  final double baseSodium;
  final double fullSugarCarbs;
  final double defaultSugarRatio;
  final bool sugarAdjustable;
}

class _BeverageToppingProfile {
  const _BeverageToppingProfile({
    required this.key,
    required this.nameZh,
    required this.nameEn,
    required this.tokens,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodium,
  });

  final String key;
  final String nameZh;
  final String nameEn;
  final List<String> tokens;
  final double protein;
  final double carbs;
  final double fat;
  final double sodium;
}

class _BeverageParseResult {
  const _BeverageParseResult({
    required this.profile,
    required this.sizeFactor,
    required this.sizeLabel,
    required this.sugarRatio,
    required this.sugarLabel,
    required this.iceLabel,
    required this.toppings,
    required this.explicitSugar,
  });

  final _BeverageProfile profile;
  final double sizeFactor;
  final String sizeLabel;
  final double sugarRatio;
  final String sugarLabel;
  final String iceLabel;
  final List<_BeverageToppingProfile> toppings;
  final bool explicitSugar;
}

class _PieceFoodProfile {
  const _PieceFoodProfile({
    required this.key,
    required this.tokens,
    required this.defaultPieceCount,
    required this.kcalPerPiece,
    required this.proteinPerPiece,
    required this.carbsPerPiece,
    required this.fatPerPiece,
    required this.sodiumPerPiece,
  });

  final String key;
  final List<String> tokens;
  final int defaultPieceCount;
  final double kcalPerPiece;
  final double proteinPerPiece;
  final double carbsPerPiece;
  final double fatPerPiece;
  final double sodiumPerPiece;
}

class _PieceFoodEstimate {
  const _PieceFoodEstimate({
    required this.profile,
    required this.count,
    required this.usedDefaultCount,
  });

  final _PieceFoodProfile profile;
  final int count;
  final bool usedDefaultCount;
}

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
  static final Uint8List _namePlaceholderBytes =
      Uint8List.fromList(base64Decode(_kNamePlaceholderBase64));
  static const List<_BeverageProfile> _kBeverageProfiles = [
    _BeverageProfile(
      key: 'fresh_milk_tea',
      nameZh: '鮮奶茶',
      nameEn: 'fresh milk tea',
      tokens: ['鮮奶茶', '鮮乳茶', 'fresh milk tea'],
      baseProtein: 5,
      baseCarbs: 8,
      baseFat: 6,
      baseSodium: 85,
      fullSugarCarbs: 28,
      defaultSugarRatio: 1.0,
      sugarAdjustable: true,
    ),
    _BeverageProfile(
      key: 'milk_tea',
      nameZh: '奶茶',
      nameEn: 'milk tea',
      tokens: ['奶茶', '奶綠', '奶青', 'milk tea'],
      baseProtein: 3,
      baseCarbs: 6,
      baseFat: 4,
      baseSodium: 65,
      fullSugarCarbs: 28,
      defaultSugarRatio: 1.0,
      sugarAdjustable: true,
    ),
    _BeverageProfile(
      key: 'soy_milk',
      nameZh: '豆漿',
      nameEn: 'soy milk',
      tokens: ['豆漿', 'soy milk'],
      baseProtein: 8,
      baseCarbs: 5,
      baseFat: 4,
      baseSodium: 90,
      fullSugarCarbs: 16,
      defaultSugarRatio: 0.4,
      sugarAdjustable: true,
    ),
    _BeverageProfile(
      key: 'latte',
      nameZh: '拿鐵',
      nameEn: 'latte',
      tokens: ['拿鐵', 'latte'],
      baseProtein: 6,
      baseCarbs: 9,
      baseFat: 6,
      baseSodium: 75,
      fullSugarCarbs: 20,
      defaultSugarRatio: 0.2,
      sugarAdjustable: true,
    ),
    _BeverageProfile(
      key: 'americano',
      nameZh: '美式咖啡',
      nameEn: 'americano',
      tokens: ['美式', '黑咖啡', 'americano', 'black coffee'],
      baseProtein: 0,
      baseCarbs: 0,
      baseFat: 0,
      baseSodium: 10,
      fullSugarCarbs: 22,
      defaultSugarRatio: 0.0,
      sugarAdjustable: true,
    ),
    _BeverageProfile(
      key: 'tea',
      nameZh: '茶飲',
      nameEn: 'tea',
      tokens: [
        '青茶',
        '綠茶',
        '紅茶',
        '烏龍',
        '烏龍茶',
        '四季春',
        '茉莉綠',
        'tea',
        'green tea',
        'black tea',
        'oolong'
      ],
      baseProtein: 0,
      baseCarbs: 0,
      baseFat: 0,
      baseSodium: 10,
      fullSugarCarbs: 35,
      defaultSugarRatio: 0.0,
      sugarAdjustable: true,
    ),
    _BeverageProfile(
      key: 'fruit_juice',
      nameZh: '果汁',
      nameEn: 'juice',
      tokens: ['果汁', '柳橙汁', 'apple juice', 'orange juice', 'juice'],
      baseProtein: 1,
      baseCarbs: 34,
      baseFat: 0,
      baseSodium: 15,
      fullSugarCarbs: 0,
      defaultSugarRatio: 1.0,
      sugarAdjustable: false,
    ),
    _BeverageProfile(
      key: 'cocoa',
      nameZh: '可可',
      nameEn: 'cocoa',
      tokens: ['可可', '巧克力飲', 'cocoa', 'chocolate drink'],
      baseProtein: 4,
      baseCarbs: 26,
      baseFat: 6,
      baseSodium: 110,
      fullSugarCarbs: 0,
      defaultSugarRatio: 1.0,
      sugarAdjustable: false,
    ),
  ];
  static const List<_BeverageToppingProfile> _kBeverageToppings = [
    _BeverageToppingProfile(
      key: 'boba',
      nameZh: '珍珠',
      nameEn: 'boba',
      tokens: ['珍珠', '波霸', 'boba', 'pearl'],
      protein: 0,
      carbs: 35,
      fat: 0,
      sodium: 25,
    ),
    _BeverageToppingProfile(
      key: 'coconut_jelly',
      nameZh: '椰果',
      nameEn: 'coconut jelly',
      tokens: ['椰果', 'coconut jelly'],
      protein: 0,
      carbs: 17,
      fat: 0,
      sodium: 8,
    ),
    _BeverageToppingProfile(
      key: 'pudding',
      nameZh: '布丁',
      nameEn: 'pudding',
      tokens: ['布丁', 'pudding'],
      protein: 2,
      carbs: 18,
      fat: 3,
      sodium: 70,
    ),
    _BeverageToppingProfile(
      key: 'grass_jelly',
      nameZh: '仙草',
      nameEn: 'grass jelly',
      tokens: ['仙草', 'grass jelly'],
      protein: 0,
      carbs: 8,
      fat: 0,
      sodium: 8,
    ),
    _BeverageToppingProfile(
      key: 'cheese_foam',
      nameZh: '奶蓋',
      nameEn: 'cheese foam',
      tokens: ['奶蓋', 'cheese foam', 'foam'],
      protein: 2,
      carbs: 6,
      fat: 8,
      sodium: 90,
    ),
  ];
  static const List<String> _kBeverageHintTokens = [
    '飲',
    '茶',
    '咖啡',
    '豆漿',
    '奶茶',
    '果汁',
    '可可',
    'latte',
    'tea',
    'coffee',
    'drink',
    'juice',
    'boba',
    'smoothie',
  ];
  static const List<_PieceFoodProfile> _kPieceFoodProfiles = [
    _PieceFoodProfile(
      key: 'boiled_dumpling',
      tokens: ['水餃', 'dumpling', 'gyoza'],
      defaultPieceCount: 10,
      kcalPerPiece: 45,
      proteinPerPiece: 2.2,
      carbsPerPiece: 6.4,
      fatPerPiece: 1.4,
      sodiumPerPiece: 90,
    ),
    _PieceFoodProfile(
      key: 'fried_dumpling',
      tokens: ['煎餃', '鍋貼', 'potsticker'],
      defaultPieceCount: 8,
      kcalPerPiece: 62,
      proteinPerPiece: 2.6,
      carbsPerPiece: 6.8,
      fatPerPiece: 2.9,
      sodiumPerPiece: 110,
    ),
    _PieceFoodProfile(
      key: 'soup_dumpling',
      tokens: ['湯包', '小籠包', 'xiao long bao'],
      defaultPieceCount: 8,
      kcalPerPiece: 68,
      proteinPerPiece: 3.0,
      carbsPerPiece: 7.2,
      fatPerPiece: 3.0,
      sodiumPerPiece: 120,
    ),
    _PieceFoodProfile(
      key: 'wonton',
      tokens: ['餛飩', '抄手', 'wonton'],
      defaultPieceCount: 8,
      kcalPerPiece: 38,
      proteinPerPiece: 1.7,
      carbsPerPiece: 5.3,
      fatPerPiece: 1.1,
      sodiumPerPiece: 85,
    ),
  ];
  static const Map<String, int> _kChineseCountDigits = {
    '一': 1,
    '二': 2,
    '兩': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
    '十': 10,
  };
  static final RegExp _kPieceCountNumericPattern = RegExp(
    r'(\d{1,2})\s*(顆|粒|個|只|pcs?|pieces?)',
    caseSensitive: false,
  );
  static final RegExp _kPieceCountChinesePattern = RegExp(
    r'([一二兩三四五六七八九十]{1,3})\s*(顆|粒|個|只)',
  );
  static final RegExp _kBasketNumericPattern = RegExp(
    r'(\d{1,2})\s*籠',
    caseSensitive: false,
  );
  static final RegExp _kBasketChinesePattern =
      RegExp(r'([一二兩三四五六七八九十]{1,3})\s*籠');
  bool _trialExpired = false;
  bool _trialChecked = false;
  bool _whitelisted = false;
  bool _mockSubscriptionActive = false;
  String? _mockSubscriptionPlanId;
  bool _iapSubscriptionActive = false;
  bool _accessStatusFailed = false;
  String _accessPlan = 'unknown';
  final Set<String> _backendEntitlements = <String>{};
  bool _iapAvailable = false;
  bool _iapProcessing = false;
  bool _iapInitialized = false;
  String? _iapLastError;
  List<ProductDetails> _iapProducts = [];
  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;
  final InAppPurchase _iap = InAppPurchase.instance;
  DateTime? _trialEnd;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  final UserProfile profile = UserProfile.initial();
  final Map<String, Map<String, String>> _dayOverrides = {};
  final Map<String, Map<String, String>> _mealOverrides = {};
  final Map<String, Map<String, String>> _weekOverrides = {};
  final Map<String, String> _meta = {};
  final List<ChatMessage> _chatMessages = [];
  String _chatSummary = '';
  bool _chatSending = false;
  String? _chatError;
  Uint8List? _chatAvatarBytes;
  // Meal reminders are delivered via auto chat (no UI card).
  final Map<String, Map<String, dynamic>> _deletedEntries = {};
  final Map<String, Map<String, dynamic>> _deletedCustomFoods = {};
  final Set<String> _failedMealSyncIds = {};
  final Set<String> _failedMealDeleteSyncIds = {};
  final Set<String> _failedCustomFoodSyncIds = {};
  final Set<String> _failedCustomFoodDeleteSyncIds = {};
  final List<CustomFood> customFoods = [];
  SyncReport? _lastSyncReport;
  String? _lastSyncError;
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
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncAt => _localSyncAt();
  int get failedSyncCount =>
      _failedMealSyncIds.length +
      _failedMealDeleteSyncIds.length +
      _failedCustomFoodSyncIds.length +
      _failedCustomFoodDeleteSyncIds.length;
  bool get hasFailedSync => failedSyncCount > 0;

  String? get supabaseUserEmail => _supabase.currentUser?.email;

  String? _accessToken() {
    return _supabase.client.auth.currentSession?.accessToken;
  }

  String? get debugAccessToken => _accessToken();

  Future<void> refreshAccessStatus() async {
    if (!isSupabaseSignedIn) {
      _trialChecked = false;
      _trialExpired = false;
      _whitelisted = false;
      _trialEnd = null;
      _accessStatusFailed = false;
      _accessPlan = 'unknown';
      _backendEntitlements.clear();
      _meta.remove(_kAccessPlanKey);
      _meta.remove(_kAccessEntitlementsKey);
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
      final planRaw = (response['plan'] as String?)?.trim();
      if (planRaw != null && planRaw.isNotEmpty) {
        _accessPlan = planRaw;
      } else if (_whitelisted) {
        _accessPlan = 'whitelisted';
      } else {
        _accessPlan = active ? 'trial' : 'free';
      }
      final entitlements = <String>{};
      final rawEntitlements = response['entitlements'];
      if (rawEntitlements is List) {
        for (final item in rawEntitlements) {
          final value = item.toString().trim();
          if (value.isNotEmpty) {
            entitlements.add(value);
          }
        }
      }
      if (entitlements.isEmpty && active) {
        entitlements.addAll(_kAiEntitlements);
      }
      _backendEntitlements
        ..clear()
        ..addAll(entitlements);
      _meta[_kAccessCheckAtKey] = DateTime.now().toUtc().toIso8601String();
      _meta[_kAccessPlanKey] = _accessPlan;
      final orderedEntitlements = _backendEntitlements.toList()..sort();
      _meta[_kAccessEntitlementsKey] = orderedEntitlements.join(',');
      _accessStatusFailed = false;
      _touchSettingsUpdatedAt();
      // ignore: discarded_futures
      _saveOverrides();
      notifyListeners();
    } catch (_) {
      final lastCheckRaw = _meta[_kAccessCheckAtKey];
      final lastCheck =
          lastCheckRaw == null ? null : DateTime.tryParse(lastCheckRaw);
      final now = DateTime.now().toUtc();
      final withinGrace = lastCheck != null &&
          now.difference(lastCheck) <= Duration(hours: accessGraceHours);
      _trialChecked = true;
      if (!withinGrace) {
        _trialExpired = true;
        _whitelisted = false;
        _trialEnd = null;
        _accessPlan = 'unknown';
        _backendEntitlements.clear();
        _meta.remove(_kAccessPlanKey);
        _meta.remove(_kAccessEntitlementsKey);
        _accessStatusFailed = true;
      } else {
        _accessStatusFailed = false;
      }
      notifyListeners();
    }
  }

  bool get trialExpired =>
      _trialChecked &&
      _trialExpired &&
      !_mockSubscriptionActive &&
      !_iapSubscriptionActive &&
      !_hasAnyAiEntitlementFromBackend;

  bool get trialChecked => _trialChecked;

  bool get isWhitelisted => _whitelisted;

  bool get mockSubscriptionActive => _mockSubscriptionActive;
  String? get mockSubscriptionPlanId => _mockSubscriptionPlanId;
  bool get accessStatusFailed => _accessStatusFailed;
  String get accessPlan => _accessPlan;
  Set<String> get accessEntitlements => Set.unmodifiable(_backendEntitlements);
  int get accessGraceHours {
    final raw = _meta[_kAccessGraceHoursKey];
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null || parsed <= 0) return _kAccessGraceHoursDefault;
    return parsed;
  }

  bool get iapAvailable => _iapAvailable;
  bool get iapSubscriptionActive => _iapSubscriptionActive;
  bool get iapProcessing => _iapProcessing;
  String? get iapLastError => _iapLastError;
  List<ProductDetails> get iapProducts => List.unmodifiable(_iapProducts);

  DateTime? get trialEndAt => _trialEnd;
  bool get chatAvailable => canUseFeature(AppFeature.chat);
  bool get chatSending => _chatSending;
  String? get chatError => _chatError;
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  Uint8List? get chatAvatarBytes => _chatAvatarBytes;

  bool get _hasAnyAiEntitlementFromBackend {
    for (final entitlement in _kAiEntitlements) {
      if (_backendEntitlements.contains(entitlement)) {
        return true;
      }
    }
    return false;
  }

  String _featureEntitlement(AppFeature feature) {
    switch (feature) {
      case AppFeature.analyze:
        return _kEntitlementAnalyze;
      case AppFeature.chat:
        return _kEntitlementChat;
      case AppFeature.summary:
        return _kEntitlementSummary;
      case AppFeature.suggest:
        return _kEntitlementSuggest;
    }
  }

  bool canUseFeature(AppFeature feature) {
    if (_iapSubscriptionActive || _mockSubscriptionActive || _whitelisted) {
      return true;
    }
    return _backendEntitlements.contains(_featureEntitlement(feature));
  }

  String buildAiContext() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recent =
        entries.where((entry) => entry.time.isAfter(cutoff)).toList();
    if (recent.isEmpty) return '';
    recent.sort((a, b) => b.time.compareTo(a.time));
    final last = recent.first;
    final lastName =
        last.overrideFoodName ?? last.result?.foodName ?? last.filename;
    final t = lookupAppLocalizations(_localeFromProfile());
    final lastSummary = _entryDishSummary(last, t) ?? '';
    final protein = _aggregateMacroPercentPlain(recent, 'protein').round();
    final carbs = _aggregateMacroPercentPlain(recent, 'carbs').round();
    final fat = _aggregateMacroPercentPlain(recent, 'fat').round();
    final sodium = _aggregateMacroPercentPlain(recent, 'sodium').round();
    final recentGroups = <String, List<MealEntry>>{};
    for (final entry in recent) {
      final key = entry.mealId ?? entry.id;
      recentGroups.putIfAbsent(key, () => []).add(entry);
    }
    final recentMealCount =
        recentGroups.values.where((group) => !_isBeverageGroup(group)).length;
    return [
      'last_meal_type=${_mealTypeKey(last.type)}',
      'last_meal_name=$lastName',
      if (lastSummary.trim().isNotEmpty) 'last_meal_summary=$lastSummary',
      'recent_7d_macros=protein:$protein, carbs:$carbs, fat:$fat, sodium:$sodium',
      'recent_7d_meal_count=$recentMealCount',
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

  static String normalizeGoalValue(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return kGoalValueLoseFat;
    final lower = value.toLowerCase();
    if (lower == kGoalValueLoseFat || lower == 'losefat') {
      return kGoalValueLoseFat;
    }
    if (lower == kGoalValueMaintain || lower == 'maintenance') {
      return kGoalValueMaintain;
    }
    if (value.contains('維持') || lower.contains('maintain')) {
      return kGoalValueMaintain;
    }
    if (value.contains('減脂') || lower.contains('lose')) {
      return kGoalValueLoseFat;
    }
    return kGoalValueLoseFat;
  }

  static String normalizePlanSpeedValue(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return kPlanSpeedValueStable;
    final lower = value.toLowerCase();
    if (lower == kPlanSpeedValueGentle) {
      return kPlanSpeedValueGentle;
    }
    if (lower == kPlanSpeedValueStable || lower == 'steady') {
      return kPlanSpeedValueStable;
    }
    if (value.contains('保守') || lower.contains('gentle')) {
      return kPlanSpeedValueGentle;
    }
    if (value.contains('穩定') || lower.contains('stable')) {
      return kPlanSpeedValueStable;
    }
    return kPlanSpeedValueStable;
  }

  bool _normalizeProfileGoalAndPlan() {
    final normalizedGoal = normalizeGoalValue(profile.goal);
    final normalizedPlan = normalizePlanSpeedValue(profile.planSpeed);
    var changed = false;
    if (profile.goal != normalizedGoal) {
      profile.goal = normalizedGoal;
      changed = true;
    }
    if (profile.planSpeed != normalizedPlan) {
      profile.planSpeed = normalizedPlan;
      changed = true;
    }
    return changed;
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
    final goal = normalizeGoalValue(profile.goal);
    final plan = normalizePlanSpeedValue(profile.planSpeed);
    final isMaintain = goal == kGoalValueMaintain;
    if (!isMaintain) {
      final isGentle = plan == kPlanSpeedValueGentle;
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
      final range = _parseCalorieRange(
          entry.overrideCalorieRange ?? entry.result?.calorieRange);
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
    String? referenceObject,
    double? referenceLengthCm,
  }) async {
    if (!canUseFeature(AppFeature.analyze)) {
      throw Exception('subscription_required');
    }
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
      referenceObject: referenceObject,
      referenceLengthCm: referenceLengthCm,
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
      result: _resolveNutritionResult(result),
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
    String? referenceObject,
    double? referenceLengthCm,
  }) async {
    if (!canUseFeature(AppFeature.analyze)) {
      throw Exception('subscription_required');
    }
    final filename =
        analysis.file.name.isNotEmpty ? analysis.file.name : 'upload.jpg';
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
      referenceObject: referenceObject,
      referenceLengthCm: referenceLengthCm,
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
      result: _resolveNutritionResult(result),
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
    final filename =
        analysis.file.name.isNotEmpty ? analysis.file.name : 'upload.jpg';
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
        overrideCalorieRange:
            overrideCalorieRange ?? existing.overrideCalorieRange,
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
    bool profileChanged = false;
    final profileMap = await _settings.loadProfile();
    final hadProfile = profileMap != null;
    if (profileMap != null) {
      _applyProfile(profileMap);
      if (_normalizeProfileGoalAndPlan()) {
        profileChanged = true;
      }
    }
    _refreshChatAvatarBytes();
    final didMigrateApi = _migrateApiBaseUrlIfNeeded();
    if (profile.nutritionValueMode != 'amount') {
      profile.nutritionValueMode = 'amount';
      profileChanged = true;
    }
    final overrides = await _settings.loadOverrides();
    if (overrides != null) {
      _loadOverrides(overrides);
    }
    if (!hadProfile) {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (systemLocale.languageCode == 'en') {
        profile.language = 'en';
      } else {
        profile.language = 'zh-TW';
      }
      await _saveProfile();
    }
    if (_meta[_kSettingsUpdatedAtKey] == null ||
        _meta[_kSettingsUpdatedAtKey]!.isEmpty) {
      _meta[_kSettingsUpdatedAtKey] = DateTime.now().toUtc().toIso8601String();
      await _saveOverrides();
    }
    _api = ApiService(
        baseUrl: profile.apiBaseUrl.isEmpty
            ? kDefaultApiBaseUrl
            : profile.apiBaseUrl);
    final loaded = await _store.loadAll();
    entries
      ..clear()
      ..addAll(loaded);
    _syncSelectedDateToLatestEntryIfNeeded();
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
    // Warm plate asset cache on startup (web uses network for assets).
    precachePlateAsset();
    if (isSupabaseSignedIn) {
      // Do not block app startup on network calls.
      scheduleMicrotask(() async {
        await refreshAccessStatus();
        await runAutoFinalizeFlow();
      });
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // Do not block startup on IAP checks.
      scheduleMicrotask(() async {
        await initIap();
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
    } catch (err) {
      setLastSyncError(err.toString());
      // Silent auto sync failure.
    } finally {
      setSyncInProgress(false);
    }
  }

  Future<void> runAutoFinalizeFlow() async {
    if (!isSupabaseSignedIn) return;
    await _runAutoSync();
    final dayFinalized = await _maybeFinalizeDayOnLaunch();
    final weekFinalized = await _maybeFinalizeWeekOnLaunch();
    if (dayFinalized || weekFinalized) {
      await _runAutoSync();
    }
  }

  Future<void> runAutoMealChatReminder(
    AppLocalizations t,
    String locale,
  ) async {
    if (!chatAvailable) return;
    if (_chatSending) return;
    final now = DateTime.now();
    final reminder = _buildMealReminder(now);
    if (reminder == null) return;
    await _sendHiddenMealReminder(reminder, t, locale);
  }

  MealReminder? _buildMealReminder(DateTime now) {
    final reminderType = _currentReminderMealType(now);
    if (reminderType == null) return null;
    if (!_isMealReminderEnabled(reminderType)) return null;
    final date = _dateOnly(now);
    if (_hasNonBeverageMealForDate(date, reminderType)) return null;
    final dayKey = _dayKey(date);
    final key = _lastMealReminderKey(reminderType);
    if (_meta[key] == dayKey) return null;
    _meta[key] = dayKey;
    // ignore: unawaited_futures
    _saveOverrides();
    return MealReminder(type: reminderType, date: date);
  }

  Future<void> _sendHiddenMealReminder(
    MealReminder reminder,
    AppLocalizations t,
    String locale,
  ) async {
    if (_chatSending) return;
    _chatSending = true;
    // Do not surface chat errors for auto reminders.
    try {
      final now = DateTime.now();
      final mealLabel = _mealTypeLabel(reminder.type, t);
      final prompt = _buildHiddenMealPrompt(mealLabel, t);
      final payload = {
        'lang': locale,
        'profile': _chatProfileSnapshot(_dateOnly(now)),
        'days': _recentDaysForChat(t),
        'today_meals': _todayMealsForChat(t),
        'context': {
          'now': now.toIso8601String(),
          'last_meal_time': _lastMealTimeForChat(now),
          'fasting_hours': _fastingHoursForChat(now),
        },
        if (_chatSummary.trim().isNotEmpty) 'summary': _chatSummary.trim(),
        'messages': [
          ..._chatMessagesForApi(),
          {'role': 'user', 'content': prompt},
        ],
      };
      final response = await _api.chat(payload, _accessToken());
      final reply = (response['reply'] as String?)?.trim() ?? '';
      final summary = (response['summary'] as String?)?.trim() ?? '';
      if (reply.isNotEmpty) {
        _chatMessages.add(ChatMessage.assistant(reply));
      }
      if (summary.isNotEmpty) {
        _chatSummary = summary;
      }
      _trimChatHistory();
      await _persistChat();
    } catch (_) {
      // Silent failure for auto reminders.
    } finally {
      _chatSending = false;
      notifyListeners();
    }
  }

  String _buildHiddenMealPrompt(String mealLabel, AppLocalizations t) {
    if (t.localeName.startsWith('en')) {
      return 'It is $mealLabel time. Based on my logged meals today, remaining calories, and time since last meal, give 2-4 short suggestions. If I am already over, clearly advise me to stop eating. Do not ask questions or request photos. Follow my persona and tone, and occasionally add a meow/nya.';
    }
    return '現在是$mealLabel時間。請根據我今天已記錄的飲食、剩餘熱量與距離上次進食時間，給我 2-4 個簡短建議；若我已超標請明確叫我先停止進食。不要反問，也不要要求拍照。請維持我的角色語氣，並可偶爾加喵。';
  }

  MealType? _currentReminderMealType(DateTime time) {
    final current = TimeOfDay.fromDateTime(time);
    if (_inRange(profile.breakfastStart, profile.breakfastEnd, current))
      return MealType.breakfast;
    if (_inRange(profile.lunchStart, profile.lunchEnd, current))
      return MealType.lunch;
    if (_inRange(profile.dinnerStart, profile.dinnerEnd, current))
      return MealType.dinner;
    return null;
  }

  bool _isMealReminderEnabled(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return profile.breakfastReminderEnabled;
      case MealType.lunch:
        return profile.lunchReminderEnabled;
      case MealType.dinner:
        return profile.dinnerReminderEnabled;
      default:
        return false;
    }
  }

  bool _hasNonBeverageMealForDate(DateTime date, MealType type) {
    final groups = mealGroupsForDate(date, type);
    for (final group in groups) {
      if (!_isBeverageGroup(group)) return true;
    }
    return false;
  }

  String _lastMealReminderKey(MealType type) {
    return '$_kMealReminderKeyPrefix:${_mealTypeKey(type)}';
  }

  Future<void> precachePlateAsset() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    final context = binding.renderViewElement;
    if (context == null) return;
    final asset =
        profile.plateAsset.isEmpty ? kDefaultPlateAsset : profile.plateAsset;
    try {
      await precacheImage(AssetImage(asset), context);
    } catch (_) {}
  }

  Future<bool> _maybeFinalizeDayOnLaunch() async {
    final now = DateTime.now();
    if (!isDailySummaryReady(now)) {
      return false;
    }
    final dayKey = _dayKey(now);
    if (_meta['last_auto_finalize'] == dayKey) {
      return false;
    }
    if (_dayOverrides.containsKey(dayKey)) {
      return false;
    }
    final locale = _localeFromProfile();
    final t = lookupAppLocalizations(locale);
    final success = await finalizeDay(now, locale.toLanguageTag(), t);
    if (!success) {
      return false;
    }
    _meta['last_auto_finalize'] = dayKey;
    await _saveOverrides();
    return true;
  }

  Future<bool> _maybeFinalizeWeekOnLaunch() async {
    final now = DateTime.now();
    if (!isWeeklySummaryReady(now)) {
      return false;
    }
    final weekStart = _weekStartFor(now);
    final weekKey = _weekKey(weekStart);
    if (_meta['last_auto_week'] == weekKey) {
      return false;
    }
    if (_weekOverrides.containsKey(weekKey)) {
      return false;
    }
    final locale = _localeFromProfile();
    final t = lookupAppLocalizations(locale);
    final success = await finalizeWeek(now, locale.toLanguageTag(), t);
    if (!success) {
      return false;
    }
    _meta['last_auto_week'] = weekKey;
    await _saveOverrides();
    return true;
  }

  Future<void> addCustomFoodFromEntry(
      MealEntry entry, AppLocalizations t) async {
    final now = DateTime.now();
    final result = entry.result;
    if (result == null) return;
    final scaledRange = entryCalorieRangeLabel(entry, t);
    final scaledMacros = scaledMacrosForEntry(entry);
    final food = CustomFood(
      id: _newId(),
      name: entry.overrideFoodName ?? result.foodName,
      summary: result.dishSummary ?? '',
      calorieRange:
          scaledRange == t.calorieUnknown ? result.calorieRange : scaledRange,
      suggestion: result.suggestion,
      macros: scaledMacros.isEmpty
          ? Map<String, double>.from(result.macros)
          : scaledMacros,
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
      judgementTags: const ['custom'],
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
    DateTime? overrideTime,
    MealType? fixedType,
  }) async {
    if (!canUseFeature(AppFeature.analyze)) {
      throw Exception('subscription_required');
    }
    final trimmed = foodName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Food name is empty');
    }
    final now = overrideTime ?? DateTime.now();
    final mealType = fixedType ?? resolveMealType(now);
    final mealId = _assignMealId(now, mealType);
    final normalizedInput = _normalizeFoodLookupText(trimmed);

    CustomFood? matched;
    for (final item in customFoods) {
      if (_normalizeFoodLookupText(item.name) == normalizedInput) {
        matched = item;
        break;
      }
    }
    if (matched != null) {
      return saveCustomFoodUsage(matched, now, mealType);
    }

    List<Map<String, dynamic>> catalogItems = const [];
    bool catalogLookupFailed = false;
    final mergedCatalogItems = <String, Map<String, dynamic>>{};
    for (final candidate in _catalogLookupCandidates(trimmed)) {
      try {
        final found = await _api.searchFoods(
          candidate,
          accessToken: _accessToken(),
          lang: locale,
          limit: 8,
        );
        for (final item in found) {
          final key =
              ((item['food_id'] ?? item['id'] ?? item['food_name'] ?? '')
                      .toString()
                      .trim())
                  .toLowerCase();
          if (key.isEmpty) continue;
          final existing = mergedCatalogItems[key];
          if (existing == null ||
              _catalogMatchScore(item) > _catalogMatchScore(existing)) {
            mergedCatalogItems[key] = item;
          }
        }
      } on CatalogSearchException catch (err) {
        catalogLookupFailed = true;
        debugPrint('catalog search failed: ${err.code}');
      }
      if (mergedCatalogItems.length >= 8) {
        break;
      }
    }
    if (mergedCatalogItems.isNotEmpty) {
      catalogItems = mergedCatalogItems.values.toList()
        ..sort(
            (a, b) => _catalogMatchScore(b).compareTo(_catalogMatchScore(a)));
    }
    final catalogMatch = _bestCatalogFoodMatch(trimmed, catalogItems);
    if (catalogMatch != null) {
      final catalogResult = _catalogItemToAnalysisResult(
        catalogMatch,
        locale,
        fallbackName: trimmed,
      );
      return _saveNameOnlyEntry(
        time: now,
        mealType: mealType,
        mealId: mealId,
        inputFoodName: trimmed,
        result: catalogResult,
        reason: 'name_catalog',
      );
    }
    final beverageFormulaResult = _buildBeverageFormulaResult(trimmed, locale);
    if (beverageFormulaResult != null) {
      return _saveNameOnlyEntry(
        time: now,
        mealType: mealType,
        mealId: mealId,
        inputFoodName: trimmed,
        result: beverageFormulaResult,
        reason: 'name_beverage_formula',
      );
    }
    if (catalogLookupFailed && catalogItems.isEmpty) {
      await _reportCatalogSearchMiss(
        trimmed,
        locale,
        source: 'catalog_unavailable',
      );
      throw NameLookupException('catalog_unavailable');
    }
    await _reportCatalogSearchMiss(
      trimmed,
      locale,
      source: 'catalog_not_found',
    );
    throw NameLookupException('catalog_not_found');
  }

  Future<List<String>> suggestFoodNames(
    String query,
    String locale, {
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final maxCount = limit.clamp(1, 40);
    final normalizedQuery = _normalizeFoodLookupText(trimmed);
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    final suggestions = <String>[];
    final seen = <String>{};

    void addSuggestion(String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      final key = _normalizeFoodLookupText(text);
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      suggestions.add(text);
    }

    final customMatches = customFoods.where((food) {
      final normalized = _normalizeFoodLookupText(food.name);
      final compact = normalized.replaceAll(' ', '');
      return normalized.contains(normalizedQuery) ||
          compact.contains(compactQuery);
    }).toList()
      ..sort((a, b) => _nameSuggestionScore(b.name, normalizedQuery)
          .compareTo(_nameSuggestionScore(a.name, normalizedQuery)));

    for (final food in customMatches) {
      addSuggestion(food.name);
      if (suggestions.length >= maxCount) {
        return suggestions.take(maxCount).toList();
      }
    }

    final localCountBeforeBeverage = suggestions.length;
    final beverageSuggestions = _beveragePresetSuggestionsV2(
      trimmed,
      locale,
      limit: maxCount,
    );
    for (final name in beverageSuggestions) {
      addSuggestion(name);
      if (suggestions.length >= maxCount) {
        return suggestions.take(maxCount).toList();
      }
    }

    // Fast-path for short input: return local suggestions immediately
    // to avoid remote timeout latency while the user is still typing.
    final beverageSuggestionsAdded =
        suggestions.length > localCountBeforeBeverage;
    if (suggestions.isNotEmpty &&
        compactQuery.length <= 2 &&
        beverageSuggestionsAdded) {
      return suggestions.take(maxCount).toList();
    }

    final candidates = <String>[];
    final candidateSeen = <String>{};
    void addCandidate(String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      final key = _normalizeFoodLookupText(text);
      if (key.isEmpty || candidateSeen.contains(key)) return;
      candidateSeen.add(key);
      candidates.add(text);
    }

    addCandidate(trimmed);
    addCandidate(normalizedQuery);
    addCandidate(compactQuery);

    final mergedCatalogItems = <String, Map<String, dynamic>>{};
    for (final candidate in candidates) {
      try {
        final found = await _api.searchFoods(
          candidate,
          accessToken: _accessToken(),
          lang: locale,
          limit: maxCount,
        );
        for (final item in found) {
          final key = ((item['food_id'] ??
                      item['id'] ??
                      item['food_name'] ??
                      item['alias'] ??
                      '')
                  .toString()
                  .trim())
              .toLowerCase();
          if (key.isEmpty) continue;
          final existing = mergedCatalogItems[key];
          if (existing == null ||
              _catalogSuggestionScore(item, normalizedQuery) >
                  _catalogSuggestionScore(existing, normalizedQuery)) {
            mergedCatalogItems[key] = item;
          }
        }
      } on CatalogSearchException {
        // Ignore remote lookup errors in suggestion mode.
      } catch (_) {
        // Ignore remote lookup errors in suggestion mode.
      }
      if (mergedCatalogItems.length >= maxCount * 2) {
        break;
      }
    }

    if (mergedCatalogItems.isEmpty) {
      final directRows = await _searchFoodCatalogFromSupabase(
        trimmed,
        locale: locale,
        limit: maxCount,
      );
      for (final row in directRows) {
        final foodName =
            (row['food_name'] ?? row['canonical_name'] ?? '').toString().trim();
        if (foodName.isEmpty) continue;
        final key =
            ((row['id'] ?? row['food_id'] ?? foodName).toString().trim())
                .toLowerCase();
        if (key.isEmpty) continue;
        mergedCatalogItems[key] = {
          'food_id': (row['id'] ?? row['food_id'] ?? '').toString(),
          'food_name': foodName,
          'alias': foodName,
          'source': (row['source'] ?? 'catalog').toString(),
          'image_url': (row['image_url'] ?? '').toString(),
          'thumb_url': (row['thumb_url'] ?? '').toString(),
          'image_source': (row['image_source'] ?? '').toString(),
          'image_license': (row['image_license'] ?? '').toString(),
          'match_score': _nameSuggestionScore(foodName, normalizedQuery),
        };
      }
    }

    final catalogItems = mergedCatalogItems.values.toList()
      ..sort((a, b) => _catalogSuggestionScore(b, normalizedQuery)
          .compareTo(_catalogSuggestionScore(a, normalizedQuery)));

    for (final item in catalogItems) {
      final foodName = (item['food_name'] ?? '').toString().trim();
      if (foodName.isNotEmpty) {
        addSuggestion(foodName);
      }
      if (suggestions.length >= maxCount) break;
      final alias = (item['alias'] ?? '').toString().trim();
      if (alias.isNotEmpty) {
        addSuggestion(alias);
      }
      if (suggestions.length >= maxCount) break;
    }

    return suggestions.take(maxCount).toList();
  }

  Future<List<Map<String, dynamic>>> _searchFoodCatalogFromSupabase(
    String query, {
    required String locale,
    required int limit,
  }) async {
    final pattern = query.trim().replaceAll(',', ' ');
    if (pattern.isEmpty) return const [];
    final lang = _catalogLangFromLocale(locale);
    try {
      final rows = await _supabase.client
          .from('food_catalog')
          .select(
              'id,food_name,canonical_name,source,image_url,thumb_url,image_source,image_license')
          .eq('lang', lang)
          .eq('is_active', true)
          .or('food_name.ilike.*$pattern*,canonical_name.ilike.*$pattern*')
          .limit(limit.clamp(1, 20));
      if (rows is! List) return const [];
      final mapped = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          mapped.add(row);
        } else if (row is Map) {
          mapped.add(row.map((k, v) => MapEntry(k.toString(), v)));
        }
      }
      return mapped;
    } catch (_) {
      // Backward compatible fallback for older schemas without lang/is_active.
      try {
        final rows = await _supabase.client
            .from('food_catalog')
            .select(
                'id,food_name,canonical_name,source,image_url,thumb_url,image_source,image_license')
            .or('food_name.ilike.*$pattern*,canonical_name.ilike.*$pattern*')
            .limit(limit.clamp(1, 20));
        if (rows is! List) return const [];
        final mapped = <Map<String, dynamic>>[];
        for (final row in rows) {
          if (row is Map<String, dynamic>) {
            mapped.add(row);
          } else if (row is Map) {
            mapped.add(row.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
        return mapped;
      } catch (_) {
        return const [];
      }
    }
  }

  Future<void> _reportCatalogSearchMiss(
    String query,
    String locale, {
    required String source,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    try {
      await _api.reportFoodSearchMiss(
        trimmed,
        accessToken: _accessToken(),
        lang: locale,
        source: source,
      );
    } catch (_) {
      // Ignore telemetry failures.
    }
  }

  double _catalogSuggestionScore(
    Map<String, dynamic> item,
    String normalizedQuery,
  ) {
    final foodName = (item['food_name'] ?? '').toString();
    final alias = (item['alias'] ?? '').toString();
    final nameScore = max(
      _nameSuggestionScore(foodName, normalizedQuery),
      _nameSuggestionScore(alias, normalizedQuery),
    );
    return (nameScore * 10) + _catalogMatchScore(item);
  }

  double _nameSuggestionScore(String value, String normalizedQuery) {
    final normalized = _normalizeFoodLookupText(value);
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

  String _normalizeFoodLookupText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _catalogLangFromLocale(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('en')) return 'en';
    return 'zh-TW';
  }

  List<String> _beveragePresetSuggestions(
    String query,
    String locale, {
    int limit = 8,
  }) {
    final normalizedQuery = _normalizeFoodLookupText(query);
    if (normalizedQuery.isEmpty) return const [];
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    final isZh = locale.toLowerCase().startsWith('zh');
    final maxCount = limit.clamp(1, 40);

    bool tokenMatches(String token) {
      final normalizedToken = _normalizeFoodLookupText(token);
      if (normalizedToken.isEmpty) return false;
      final compactToken = normalizedToken.replaceAll(' ', '');
      return normalizedToken.contains(normalizedQuery) ||
          normalizedQuery.contains(normalizedToken) ||
          compactToken.contains(compactQuery) ||
          compactQuery.contains(compactToken);
    }

    final hintTokens = isZh
        ? <String>[
            '茶',
            '青',
            '紅',
            '綠',
            '烏龍',
            '奶茶',
            '豆漿',
            '咖啡',
            '拿鐵',
            '果汁',
            '飲料',
            '珍珠',
            '椰果',
            '仙草',
            '布丁',
            '奶蓋',
          ]
        : <String>[
            'tea',
            'milk tea',
            'soy',
            'coffee',
            'latte',
            'juice',
            'drink',
            'boba',
            'pearl',
            'coconut jelly',
            'grass jelly',
            'pudding',
            'foam',
          ];

    final likelyBeverage = hintTokens.any(tokenMatches);
    if (!likelyBeverage) return const [];

    final baseProfiles = isZh
        ? <Map<String, dynamic>>[
            {
              'name': '青茶',
              'tokens': ['青茶', '青', 'tea', 'green tea'],
            },
            {
              'name': '紅茶',
              'tokens': ['紅茶', '紅', 'black tea'],
            },
            {
              'name': '綠茶',
              'tokens': ['綠茶', '綠', 'green tea'],
            },
            {
              'name': '烏龍茶',
              'tokens': ['烏龍', '烏龍茶', 'oolong'],
            },
            {
              'name': '奶茶',
              'tokens': ['奶茶', 'milk tea'],
            },
            {
              'name': '無糖豆漿',
              'tokens': ['豆漿', 'soy milk'],
            },
            {
              'name': '美式咖啡',
              'tokens': ['咖啡', '美式', 'americano', 'coffee'],
            },
            {
              'name': '拿鐵',
              'tokens': ['拿鐵', 'latte'],
            },
          ]
        : <Map<String, dynamic>>[
            {
              'name': 'green tea',
              'tokens': ['green tea', 'tea', 'green'],
            },
            {
              'name': 'black tea',
              'tokens': ['black tea', 'tea', 'black'],
            },
            {
              'name': 'oolong tea',
              'tokens': ['oolong', 'tea'],
            },
            {
              'name': 'milk tea',
              'tokens': ['milk tea', 'tea'],
            },
            {
              'name': 'soy milk',
              'tokens': ['soy milk', 'soy'],
            },
            {
              'name': 'americano',
              'tokens': ['americano', 'coffee'],
            },
            {
              'name': 'latte',
              'tokens': ['latte', 'coffee'],
            },
          ];

    final matchedBases = <String>[];
    for (final profile in baseProfiles) {
      final name = (profile['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final tokens = (profile['tokens'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      final matched =
          tokenMatches(name) || tokens.any((token) => tokenMatches(token));
      if (matched && !matchedBases.contains(name)) {
        matchedBases.add(name);
      }
    }

    if (matchedBases.isEmpty) {
      matchedBases.add(
        isZh ? '青茶' : 'green tea',
      );
    }

    final suggestions = <String>[];
    final seen = <String>{};
    void addSuggestion(String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      final key = _normalizeFoodLookupText(text);
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      suggestions.add(text);
    }

    for (final base in matchedBases.take(3)) {
      addSuggestion(base);
      if (isZh) {
        addSuggestion('$base 無糖去冰');
        addSuggestion('$base 微糖少冰');
        addSuggestion('$base 半糖去冰');
        addSuggestion('$base 半糖少冰');
        addSuggestion('$base 半糖去冰加珍珠');
        addSuggestion('$base 無糖去冰加椰果');
        addSuggestion('$base 無糖去冰加仙草');
        if (base.contains('奶茶') || base.contains('拿鐵')) {
          addSuggestion('$base 半糖少冰加奶蓋');
        }
      } else {
        addSuggestion('$base unsweetened no ice');
        addSuggestion('$base light sugar less ice');
        addSuggestion('$base half sugar no ice');
        addSuggestion('$base half sugar less ice');
        addSuggestion('$base half sugar no ice with boba');
        addSuggestion('$base unsweetened no ice with coconut jelly');
      }
      if (suggestions.length >= maxCount * 2) break;
    }

    suggestions.sort((a, b) => _nameSuggestionScore(b, normalizedQuery)
        .compareTo(_nameSuggestionScore(a, normalizedQuery)));
    return suggestions.take(maxCount).toList();
  }

  List<String> _beveragePresetSuggestionsV2(
    String query,
    String locale, {
    int limit = 8,
  }) {
    final normalizedQuery = _normalizeFoodLookupText(query);
    if (normalizedQuery.isEmpty) return const [];
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    final isZh = locale.toLowerCase().startsWith('zh');
    final maxCount = limit.clamp(1, 20);

    bool tokenMatches(String token) {
      final normalizedToken = _normalizeFoodLookupText(token);
      if (normalizedToken.isEmpty) return false;
      final compactToken = normalizedToken.replaceAll(' ', '');
      return normalizedToken.contains(normalizedQuery) ||
          normalizedQuery.contains(normalizedToken) ||
          compactToken.contains(compactQuery) ||
          compactQuery.contains(compactToken);
    }

    final hintTokens = isZh
        ? const <String>[
            '\u8336',
            '\u9752',
            '\u7d05',
            '\u7da0',
            '\u70cf\u9f8d',
            '\u5976\u8336',
            '\u8c46\u6f3f',
            '\u8c46\u6f3f\u7d05\u8336',
            '\u8c46\u4e73',
            '\u9bae\u5976',
            '\u9187\u5976',
            '\u679c\u8336',
            '\u690d\u7269\u5976',
            '\u6ab8\u6aac',
            '\u767e\u9999',
            '\u8292\u679c',
            '\u82ad\u6a02',
            '\u8461\u8404\u67da',
            '\u7d05\u67da',
            '\u91d1\u6854',
            '\u6885\u7da0',
            '\u9752\u6885',
            '\u8354\u679d',
            '\u67f3\u6a59',
            '\u694a\u679d',
            '\u5496\u5561',
            '\u62ff\u9435',
            '\u7f8e\u5f0f',
            '\u51b7\u8403',
            '\u5361\u5e03',
            '\u5361\u5e03\u5947\u8afe',
            '\u6469\u5361',
            '\u746a\u5947\u6735',
            '\u99e5\u5217\u767d',
            '\u897f\u897f\u91cc',
            '\u679c\u6c41',
            '\u98f2\u6599',
            '\u73cd\u73e0',
            '\u6ce2\u9738',
            '\u6930\u679c',
            '\u4ed9\u8349',
            '\u5e03\u4e01',
            '\u5976\u84cb',
            '\u52a0\u6599',
            '\u0035\u0030\u5d50',
            '\u4e94\u5341\u5d50',
            '\u6e05\u5fc3',
            '\u53ef\u4e0d\u53ef',
            '\u9ebb\u53e4',
            '\u8ff7\u5ba2\u590f',
            '\u8336\u6e6f\u6703',
            '\u4e94\u6850\u865f',
            '\u9f9c\u8a18',
            '\u5f97\u6b63',
            '\u842c\u6ce2',
            '\u4e00\u6c90\u65e5',
            '\u518d\u7761\u0035\u5206\u9418',
            '\u8001\u8cf4',
            '\u5927\u82d1\u5b50',
            '\u73cd\u716e\u4e39',
            '\u4e0a\u5b87\u6797',
            '\u9db4\u8336\u6a13',
            '\u5148\u559d\u9053',
            '\u65e5\u51fa\u8336\u592a',
            '\u8336\u805a',
            '\u6a02\u6cd5',
            '\u559d\u8336\u5c0f\u8216',
            '\u6625\u6c34\u5802',
            '\u9f8d\u89d2',
            '\u8336\u9b54',
            'comebuy',
            'coco',
            'chatime',
            'kung fu tea',
          ]
        : const <String>[
            'tea',
            'milk tea',
            'soy',
            'coffee',
            'latte',
            'americano',
            'espresso',
            'cappuccino',
            'flat white',
            'macchiato',
            'mocha',
            'cold brew',
            'coldbrew',
            'juice',
            'drink',
            'boba',
            'pearl',
            'coconut jelly',
            'grass jelly',
            'pudding',
            'foam',
            'topping',
          ];

    final brandProfiles = isZh
        ? const <Map<String, dynamic>>[
            {
              'name': '\u0035\u0030\u5d50',
              'tokens': ['\u0035\u0030\u5d50', '\u4e94\u5341\u5d50', '50lan'],
              'signatures': [
                '\u56db\u5b63\u6625\u9752\u8336',
                '\u73cd\u73e0\u5976\u8336',
                '\u6ce2\u9738\u5976\u8336',
                '\u6ab8\u6aac\u7da0\u8336',
              ],
            },
            {
              'name': '\u6e05\u5fc3\u798f\u5168',
              'tokens': [
                '\u6e05\u5fc3',
                '\u6e05\u5fc3\u798f\u5168',
                'chingshin'
              ],
              'signatures': [
                '\u70cf\u9f8d\u7da0\u8336',
                '\u51ac\u74dc\u8336',
                '\u591a\u591a\u7da0\u8336',
                '\u73cd\u73e0\u7d05\u8336',
              ],
            },
            {
              'name': '\u53ef\u4e0d\u53ef',
              'tokens': [
                '\u53ef\u4e0d\u53ef',
                '\u53ef\u4e0d\u53ef\u719f\u6210\u7d05\u8336',
                'kebuke'
              ],
              'signatures': [
                '\u719f\u6210\u7d05\u8336',
                '\u6625\u82bd\u7da0\u8336',
                '\u96ea\u82b1\u51b7\u9732',
              ],
            },
            {
              'name': '\u9ebb\u53e4',
              'tokens': ['\u9ebb\u53e4', '\u9ebb\u53e4\u8336\u574a', 'macu'],
              'signatures': [
                '\u91d1\u8431\u96d9Q',
                '\u829d\u829d\u91d1\u8431',
                '\u694a\u679d\u7518\u9732 2.0',
              ],
            },
            {
              'name': '\u8ff7\u5ba2\u590f',
              'tokens': ['\u8ff7\u5ba2\u590f', 'milksha'],
              'signatures': [
                '\u5927\u6b63\u7d05\u8336\u62ff\u9435',
                '\u73cd\u73e0\u7d05\u8336\u62ff\u9435',
                '\u9752\u6ab8\u9999\u8336',
              ],
            },
            {
              'name': '\u8336\u6e6f\u6703',
              'tokens': ['\u8336\u6e6f\u6703', 'tp tea'],
              'signatures': [
                '\u89c0\u97f3\u62ff\u9435',
                '\u7fe1\u7fe0\u6ab8\u6aac',
                '\u73cd\u73e0\u5976\u8336',
              ],
            },
            {
              'name': '\u4e94\u6850\u865f',
              'tokens': ['\u4e94\u6850\u865f', 'woo tea'],
              'signatures': [
                '\u8001\u5be6\u4eba\u7d05\u8336',
                '\u4e94\u6850\u5976\u8336',
                '\u694a\u679d\u7518\u9732',
              ],
            },
            {
              'name': 'CoCo\u90fd\u53ef',
              'tokens': ['coco', 'coco\u90fd\u53ef', '\u90fd\u53ef'],
              'signatures': [
                '\u767e\u9999\u96d9\u97ff\u70ae',
                '\u73cd\u73e0\u5976\u8336',
                '\u9bae\u767e\u9999\u7da0\u8336',
              ],
            },
            {
              'name': 'COMEBUY',
              'tokens': ['comebuy', '\u7981\u6cbb\u8336', '\u73fe\u6ce1\u8336'],
              'signatures': [
                '\u6d77\u795e',
                '\u7d55\u4ee3\u96d9Q\u5976\u8336',
                '\u78a7\u87ba\u6625',
              ],
            },
            {
              'name': '\u842c\u6ce2',
              'tokens': ['\u842c\u6ce2', 'wanpo'],
              'signatures': [
                '\u6975\u54c1\u51ac\u74dc\u9732',
                '\u6975\u54c1\u5976\u8336',
                '\u689d\u5b50\u8001\u4eba\u8336',
              ],
            },
            {
              'name': '\u4e00\u6c90\u65e5',
              'tokens': ['\u4e00\u6c90\u65e5', 'aniceholiday'],
              'signatures': [
                '\u7c89\u7cbf\u9ea5\u8336',
                '\u8c46\u6f3f\u7d05\u8336',
                '\u6cb9\u5207\u70cf\u9f8d',
              ],
            },
            {
              'name': '\u518d\u7761\u0035\u5206\u9418',
              'tokens': ['\u518d\u7761\u0035\u5206\u9418', 'nap tea'],
              'signatures': [
                '\u68c9\u88ab\u5348\u8317\u7da0',
                '\u65e5\u5b89\u7d05\u6f38\u5c64\u9bae\u5976',
                '\u68c9\u88ab\u53ef\u53ef',
              ],
            },
            {
              'name': '\u8001\u8cf4\u8336\u68e7',
              'tokens': ['\u8001\u8cf4', '\u8001\u8cf4\u8336\u68e7', 'laolai'],
              'signatures': [
                '\u8c46\u6f3f\u7d05\u8336',
                '\u73cd\u73e0\u8c46\u6f3f\u7d05\u8336',
                '\u8001\u8cf4\u7d05\u8336',
              ],
            },
            {
              'name': '\u9f9c\u8a18',
              'tokens': ['\u9f9c\u8a18', '\u9f9c\u8a18\u8317\u54c1'],
              'signatures': [
                '\u7d05\u67da\u7fe1\u7fe0',
                '\u4e09\u5341\u4e09\u8336\u738b',
                '\u860b\u679c\u7d05\u8431',
              ],
            },
            {
              'name': '\u5f97\u6b63',
              'tokens': ['\u5f97\u6b63', 'dejeng'],
              'signatures': [
                '\u8f15\u70cf\u9f8d\u9bae\u5976',
                '\u6625\u70cf\u9f8d',
                '\u820a\u57ce\u7d05\u8336',
              ],
            },
            {
              'name': '\u5927\u82d1\u5b50',
              'tokens': ['\u5927\u82d1\u5b50', 'dayungs'],
              'signatures': [
                '\u82ad\u6a02\u6885\u7da0',
                '\u67da\u7f8e\u7c92',
                '\u91d1\u6843\u82ad\u6a02',
              ],
            },
            {
              'name': '\u73cd\u716e\u4e39',
              'tokens': ['\u73cd\u716e\u4e39', 'jenjudan'],
              'signatures': [
                '\u9ed1\u7cd6\u73cd\u73e0\u9bae\u5976',
                '\u8001\u6d3e\u5341\u5206\u8336',
                '\u9ed1\u7cd6\u9bae\u5976\u8336',
              ],
            },
            {
              'name': '\u4e0a\u5b87\u6797',
              'tokens': ['\u4e0a\u5b87\u6797', 'shang yulin'],
              'signatures': [
                '\u592a\u6975\u9bae\u5976\u8336',
                '\u9f8d\u773c\u871c\u70cf\u9f8d',
                '\u8f9b\u9999\u70cf\u9f8d',
              ],
            },
            {
              'name': '\u9db4\u8336\u6a13',
              'tokens': ['\u9db4\u8336\u6a13', 'hechalou'],
              'signatures': [
                '\u9db4\u9802\u7d05\u8336',
                '\u9f8d\u773c\u871c\u8336',
                '\u9db4\u9802\u90a3\u63d0',
              ],
            },
            {
              'name': '\u5148\u559d\u9053',
              'tokens': ['\u5148\u559d\u9053', 'xianhidao'],
              'signatures': [
                '\u51ac\u74dc\u6ab8\u6aac',
                '\u82f1\u5f0f\u7d05\u8336',
                '\u70cf\u9f8d\u9bae\u5976',
              ],
            },
            {
              'name': '\u65e5\u51fa\u8336\u592a',
              'tokens': ['\u65e5\u51fa\u8336\u592a', 'chatime'],
              'signatures': [
                '\u73cd\u73e0\u5976\u8336',
                '\u91d1\u6843\u6c34\u679c\u8336',
                '\u9752\u8336\u51cd\u9732',
              ],
            },
            {
              'name': '\u8336\u805a',
              'tokens': ['\u8336\u805a', 'chage'],
              'signatures': [
                '\u6d3b\u83cc\u591a\u591a\u7da0',
                '\u9178\u67d1\u9752\u8336',
                '\u871c\u9999\u7d05\u8336',
              ],
            },
            {
              'name': '\u6a02\u6cd5',
              'tokens': ['\u6a02\u6cd5', 'le phare'],
              'signatures': [
                '\u6a02\u6cd5\u9bae\u679c\u8336',
                '\u9e97\u6625\u7d05\u8336',
                '\u6ab8\u6aac\u7da0\u8336',
              ],
            },
            {
              'name': '\u559d\u8336\u5c0f\u8216',
              'tokens': ['\u559d\u8336\u5c0f\u8216', 'teashop168'],
              'signatures': [
                '\u82f1\u5f0f\u7d05\u8336',
                '\u51ac\u74dc\u9752\u8336',
                '\u73cd\u73e0\u9bae\u5976\u8336',
              ],
            },
            {
              'name': '\u6625\u6c34\u5802',
              'tokens': ['\u6625\u6c34\u5802', 'chun shui tang'],
              'signatures': [
                '\u73cd\u73e0\u5976\u8336',
                '\u9435\u89c0\u97f3\u5976\u8336',
                '\u9f8d\u773c\u871c\u6ab8\u6aac',
              ],
            },
            {
              'name': '\u9f8d\u89d2',
              'tokens': ['\u9f8d\u89d2', 'dragon horn'],
              'signatures': [
                '\u9f8d\u89d2\u9ed1\u8336',
                '\u829d\u58eb\u4e73\u8336',
                '\u9ed1\u7cd6\u9f8d\u73e0',
              ],
            },
            {
              'name': '\u8336\u9b54',
              'tokens': ['\u8336\u9b54', 'teamag'],
              'signatures': [
                '\u62db\u724c\u7d05\u8336',
                '\u9999\u67da\u7da0\u8336',
                '\u6d77\u9e7d\u5976\u84cb\u9752',
              ],
            },
          ]
        : const <Map<String, dynamic>>[];

    final likelyBeverage = hintTokens.any(tokenMatches);
    if (!likelyBeverage) return const [];

    final baseProfiles = isZh
        ? const <Map<String, dynamic>>[
            {
              'name': '\u9752\u8336',
              'tokens': ['\u9752\u8336', '\u9752', 'tea', 'green tea'],
            },
            {
              'name': '\u7d05\u8336',
              'tokens': ['\u7d05\u8336', '\u7d05', 'black tea'],
            },
            {
              'name': '\u7da0\u8336',
              'tokens': ['\u7da0\u8336', '\u7da0', 'green tea'],
            },
            {
              'name': '\u70cf\u9f8d\u8336',
              'tokens': ['\u70cf\u9f8d\u8336', '\u70cf\u9f8d', 'oolong tea'],
            },
            {
              'name': '\u5976\u8336',
              'tokens': ['\u5976\u8336', 'milk tea'],
            },
            {
              'name': '\u9bae\u5976\u8336',
              'tokens': [
                '\u9bae\u5976\u8336',
                '\u9bae\u5976',
                'fresh milk tea'
              ],
            },
            {
              'name': '\u73cd\u73e0\u5976\u8336',
              'tokens': [
                '\u73cd\u73e0\u5976\u8336',
                '\u6ce2\u9738\u5976\u8336'
              ],
            },
            {
              'name': '\u7121\u7cd6\u8c46\u6f3f',
              'tokens': [
                '\u8c46\u6f3f',
                '\u7121\u7cd6\u8c46\u6f3f',
                'soy milk'
              ],
            },
            {
              'name': '\u8c46\u6f3f\u7d05\u8336',
              'tokens': [
                '\u8c46\u6f3f\u7d05\u8336',
                '\u8c46\u4e73\u7d05\u8336',
                'soy black tea',
              ],
            },
            {
              'name': '\u8c46\u6f3f\u5976\u8336',
              'tokens': [
                '\u8c46\u6f3f\u5976\u8336',
                '\u8c46\u4e73\u5976\u8336'
              ],
            },
            {
              'name': '\u7f8e\u5f0f\u5496\u5561',
              'tokens': ['\u7f8e\u5f0f', '\u5496\u5561', 'americano', 'coffee'],
            },
            {
              'name': '\u62ff\u9435',
              'tokens': ['\u62ff\u9435', 'latte'],
            },
            {
              'name': '\u51b7\u8403\u5496\u5561',
              'tokens': [
                '\u51b7\u8403\u5496\u5561',
                '\u51b7\u8403',
                'cold brew'
              ],
            },
            {
              'name': '\u6fc3\u7e2e\u5496\u5561',
              'tokens': [
                '\u6fc3\u7e2e\u5496\u5561',
                '\u7fa9\u5f0f\u6fc3\u7e2e',
                'espresso'
              ],
            },
            {
              'name': '\u5361\u5e03\u5947\u8afe',
              'tokens': [
                '\u5361\u5e03\u5947\u8afe',
                '\u5361\u5e03',
                'cappuccino'
              ],
            },
            {
              'name': '\u99e5\u5217\u767d',
              'tokens': ['\u99e5\u5217\u767d', 'flat white'],
            },
            {
              'name': '\u7126\u7cd6\u746a\u5947\u6735',
              'tokens': [
                '\u7126\u7cd6\u746a\u5947\u6735',
                '\u746a\u5947\u6735',
                'macchiato'
              ],
            },
            {
              'name': '\u6469\u5361\u5496\u5561',
              'tokens': ['\u6469\u5361\u5496\u5561', '\u6469\u5361', 'mocha'],
            },
            {
              'name': '\u897f\u897f\u91cc\u5496\u5561',
              'tokens': [
                '\u897f\u897f\u91cc\u5496\u5561',
                '\u897f\u897f\u91cc'
              ],
            },
            {
              'name': '\u71d5\u9ea5\u62ff\u9435',
              'tokens': [
                '\u71d5\u9ea5\u62ff\u9435',
                '\u71d5\u9ea5',
                'oat latte'
              ],
            },
            {
              'name': '\u51ac\u74dc\u8336',
              'tokens': ['\u51ac\u74dc\u8336', '\u51ac\u74dc'],
            },
            {
              'name': '\u6ab8\u6aac\u7da0\u8336',
              'tokens': ['\u6ab8\u6aac\u7da0\u8336', '\u6ab8\u6aac'],
            },
            {
              'name': '\u6ab8\u6aac\u7d05\u8336',
              'tokens': ['\u6ab8\u6aac\u7d05\u8336'],
            },
            {
              'name': '\u591a\u591a\u7da0',
              'tokens': ['\u591a\u591a\u7da0', 'yakult'],
            },
            {
              'name': '\u6885\u5b50\u7da0\u8336',
              'tokens': ['\u6885\u5b50\u7da0\u8336', '\u6885\u7da0'],
            },
            {
              'name': '\u767e\u9999\u7da0\u8336',
              'tokens': ['\u767e\u9999\u7da0\u8336', '\u767e\u9999'],
            },
            {
              'name': '\u8702\u871c\u6ab8\u6aac',
              'tokens': ['\u8702\u871c\u6ab8\u6aac', '\u8702\u871c'],
            },
            {
              'name': '\u6c34\u679c\u8336',
              'tokens': ['\u6c34\u679c\u8336', '\u7d9c\u5408\u679c\u8336'],
            },
            {
              'name': '\u695a\u9580\u70cf\u9f8d',
              'tokens': [
                '\u695a\u9580\u70cf\u9f8d',
                '\u91d1\u8431',
                '\u89c0\u97f3'
              ],
            },
            {
              'name': '\u56db\u5b63\u6625\u9752\u8336',
              'tokens': [
                '\u56db\u5b63\u6625',
                '\u56db\u5b63\u6625\u9752\u8336'
              ],
            },
            {
              'name': '\u8702\u871c\u7da0\u8336',
              'tokens': [
                '\u8702\u871c\u7da0\u8336',
                '\u8702\u871c\u9752\u8336'
              ],
            },
            {
              'name': '\u871c\u9999\u7d05\u8336',
              'tokens': ['\u871c\u9999\u7d05\u8336', '\u871c\u9999\u7d05'],
            },
            {
              'name': '\u70cf\u9f8d\u9bae\u5976',
              'tokens': ['\u70cf\u9f8d\u9bae\u5976', '\u70cf\u9f8d\u5976'],
            },
            {
              'name': '\u9435\u89c0\u97f3\u5976\u8336',
              'tokens': [
                '\u9435\u89c0\u97f3',
                '\u9435\u89c0\u97f3\u5976\u8336'
              ],
            },
            {
              'name': '\u62b9\u8336\u62ff\u9435',
              'tokens': ['\u62b9\u8336\u62ff\u9435', '\u62b9\u8336'],
            },
            {
              'name': '\u7119\u8336\u62ff\u9435',
              'tokens': ['\u7119\u8336\u62ff\u9435', '\u7119\u8336'],
            },
            {
              'name': '\u53ef\u53ef\u9bae\u5976',
              'tokens': [
                '\u53ef\u53ef\u9bae\u5976',
                '\u53ef\u53ef\u725b\u5976'
              ],
            },
            {
              'name': '\u9ed1\u7cd6\u9bae\u5976',
              'tokens': [
                '\u9ed1\u7cd6\u9bae\u5976',
                '\u9ed1\u7cd6\u725b\u5976'
              ],
            },
            {
              'name': '\u9ed1\u7cd6\u73cd\u73e0\u9bae\u5976',
              'tokens': [
                '\u9ed1\u7cd6\u73cd\u73e0\u9bae\u5976',
                '\u9ed1\u7cd6\u6ce2\u9738\u9bae\u5976'
              ],
            },
            {
              'name': '\u591a\u591a\u7da0\u8336',
              'tokens': [
                '\u591a\u591a\u7da0\u8336',
                '\u990a\u6a02\u591a\u7da0'
              ],
            },
            {
              'name': '\u91d1\u6854\u6ab8\u6aac',
              'tokens': ['\u91d1\u6854\u6ab8\u6aac', '\u91d1\u6854'],
            },
            {
              'name': '\u91d1\u6854\u7da0\u8336',
              'tokens': ['\u91d1\u6854\u7da0\u8336'],
            },
            {
              'name': '\u8461\u8404\u67da\u7da0\u8336',
              'tokens': [
                '\u8461\u8404\u67da\u7da0\u8336',
                '\u7d05\u67da\u7da0'
              ],
            },
            {
              'name': '\u767e\u9999\u96d9\u97ff\u70ae',
              'tokens': [
                '\u767e\u9999\u96d9\u97ff\u70ae',
                '\u96d9\u97ff\u70ae'
              ],
            },
            {
              'name': '\u51ac\u74dc\u9752\u8336',
              'tokens': ['\u51ac\u74dc\u9752\u8336'],
            },
            {
              'name': '\u51ac\u74dc\u6ab8\u6aac',
              'tokens': [
                '\u51ac\u74dc\u6ab8\u6aac',
                '\u6ab8\u6aac\u51ac\u74dc'
              ],
            },
            {
              'name': '\u6885\u5b50\u7d05\u8336',
              'tokens': ['\u6885\u5b50\u7d05\u8336', '\u6885\u7d05'],
            },
            {
              'name': '\u6d1b\u795e\u82b1\u8336',
              'tokens': ['\u6d1b\u795e\u82b1\u8336', '\u6d1b\u795e'],
            },
            {
              'name': '\u70cf\u6885\u6c41',
              'tokens': ['\u70cf\u6885\u6c41', '\u9178\u6885\u6c41'],
            },
            {
              'name': '\u9ea5\u9999\u7d05\u8336',
              'tokens': ['\u9ea5\u9999\u7d05\u8336'],
            },
            {
              'name': '\u9ea5\u8336',
              'tokens': ['\u9ea5\u8336'],
            },
            {
              'name': '\u82ad\u6a02\u7da0\u8336',
              'tokens': ['\u82ad\u6a02\u7da0\u8336', '\u82ad\u6a02'],
            },
            {
              'name': '\u8292\u679c\u7da0\u8336',
              'tokens': ['\u8292\u679c\u7da0\u8336', '\u8292\u679c'],
            },
            {
              'name': '\u694a\u679d\u7518\u9732',
              'tokens': [
                '\u694a\u679d\u7518\u9732',
                '\u8292\u679c\u67da\u5b50\u897f\u7c73\u9732'
              ],
            },
            {
              'name': '\u6c34\u679c\u6c23\u6ce1\u98f2',
              'tokens': ['\u6c34\u679c\u6c23\u6ce1', '\u6c23\u6ce1\u98f2'],
            },
            {
              'name': '\u6a58\u5b50\u7da0\u8336',
              'tokens': [
                '\u67da\u5b50\u7da0\u8336',
                '\u6a58\u5b50\u7da0\u8336'
              ],
            },
            {
              'name': '\u860b\u679c\u7d05\u8336',
              'tokens': ['\u860b\u679c\u7d05\u8336'],
            },
            {
              'name': '\u9cf3\u68a8\u9752\u8336',
              'tokens': ['\u9cf3\u68a8\u9752\u8336', '\u9cf3\u68a8'],
            },
            {
              'name': '\u897f\u74dc\u9752\u8336',
              'tokens': ['\u897f\u74dc\u9752\u8336', '\u897f\u74dc'],
            },
          ]
        : const <Map<String, dynamic>>[
            {
              'name': 'green tea',
              'tokens': ['green tea', 'tea', 'green'],
            },
            {
              'name': 'black tea',
              'tokens': ['black tea', 'tea', 'black'],
            },
            {
              'name': 'oolong tea',
              'tokens': ['oolong tea', 'oolong'],
            },
            {
              'name': 'milk tea',
              'tokens': ['milk tea', 'tea'],
            },
            {
              'name': 'soy milk',
              'tokens': ['soy milk', 'soy'],
            },
            {
              'name': 'americano',
              'tokens': ['americano', 'coffee'],
            },
            {
              'name': 'latte',
              'tokens': ['latte', 'coffee'],
            },
            {
              'name': 'cold brew coffee',
              'tokens': ['cold brew', 'coldbrew'],
            },
            {
              'name': 'espresso',
              'tokens': ['espresso'],
            },
            {
              'name': 'cappuccino',
              'tokens': ['cappuccino', 'cap'],
            },
            {
              'name': 'flat white',
              'tokens': ['flat white'],
            },
            {
              'name': 'caramel macchiato',
              'tokens': ['macchiato', 'caramel macchiato'],
            },
            {
              'name': 'mocha',
              'tokens': ['mocha'],
            },
            {
              'name': 'winter melon tea',
              'tokens': ['winter melon tea', 'winter melon'],
            },
            {
              'name': 'lemon green tea',
              'tokens': ['lemon green tea', 'lemon tea'],
            },
          ];

    final popularMenuItems = isZh
        ? const <String>[
            '\u56db\u5b63\u6625\u9752\u8336',
            '\u56db\u5b63\u6625\u5976\u9752',
            '\u8309\u9999\u7da0\u8336',
            '\u7389\u9732\u7da0\u8336',
            '\u9ad8\u5c71\u9752\u8336',
            '\u7fe0\u7389\u9752\u8336',
            '\u963f\u85a9\u59c6\u7d05\u8336',
            '\u4f2f\u7235\u7d05\u8336',
            '\u932b\u862d\u7d05\u8336',
            '\u871c\u9999\u7d05\u8336',
            '\u80ed\u8102\u7d05\u8336',
            '\u719f\u6210\u7d05\u8336',
            '\u51ac\u74dc\u8336',
            '\u51ac\u74dc\u9752\u8336',
            '\u51ac\u74dc\u6ab8\u6aac',
            '\u51ac\u74dc\u9bae\u5976',
            '\u9ed1\u7cd6\u51ac\u74dc',
            '\u6ab8\u6aac\u9752\u8336',
            '\u6ab8\u6aac\u7d05\u8336',
            '\u6ab8\u6aac\u7da0\u8336',
            '\u8702\u871c\u6ab8\u6aac',
            '\u8702\u871c\u7da0\u8336',
            '\u8702\u871c\u9752\u8336',
            '\u91d1\u6854\u6ab8\u6aac',
            '\u91d1\u6854\u7da0\u8336',
            '\u767e\u9999\u7da0\u8336',
            '\u767e\u9999\u7d05\u8336',
            '\u767e\u9999\u96d9\u97ff\u70ae',
            '\u591a\u591a\u7da0\u8336',
            '\u8461\u8404\u67da\u7da0\u8336',
            '\u8461\u8404\u67da\u9752\u8336',
            '\u860b\u679c\u7d05\u8336',
            '\u860b\u679c\u7da0\u8336',
            '\u9cf3\u68a8\u9752\u8336',
            '\u8292\u679c\u7da0\u8336',
            '\u82ad\u6a02\u6885\u7da0',
            '\u67f3\u6a59\u7da0\u8336',
            '\u897f\u74dc\u9752\u8336',
            '\u694a\u679d\u7518\u9732',
            '\u6c34\u679c\u8336',
            '\u7d9c\u5408\u679c\u8336',
            '\u8354\u679d\u70cf\u9f8d',
            '\u767d\u6843\u70cf\u9f8d',
            '\u8461\u8404\u70cf\u9f8d',
            '\u9752\u6885\u7da0\u8336',
            '\u6885\u5b50\u7da0\u8336',
            '\u6885\u5b50\u7d05\u8336',
            '\u70cf\u6885\u6c41',
            '\u6d1b\u795e\u82b1\u8336',
            '\u6851\u845a\u51b0\u8336',
            '\u7518\u8517\u9752\u8336',
            '\u7518\u8517\u6ab8\u6aac',
            '\u5976\u8336',
            '\u73cd\u73e0\u5976\u8336',
            '\u6ce2\u9738\u5976\u8336',
            '\u96d9\u0051\u5976\u8336',
            '\u5e03\u4e01\u5976\u8336',
            '\u6930\u679c\u5976\u8336',
            '\u4ed9\u8349\u51cd\u5976\u8336',
            '\u5976\u84cb\u7d05\u8336',
            '\u5976\u84cb\u7da0\u8336',
            '\u5976\u84cb\u9752\u8336',
            '\u829d\u58eb\u5976\u84cb\u70cf\u9f8d',
            '\u9bae\u5976\u8336',
            '\u9bae\u5976\u7d05\u8336',
            '\u9bae\u5976\u7da0\u8336',
            '\u70cf\u9f8d\u9bae\u5976',
            '\u9435\u89c0\u97f3\u9bae\u5976',
            '\u9ed1\u7cd6\u9bae\u5976',
            '\u9ed1\u7cd6\u73cd\u73e0\u9bae\u5976',
            '\u53ef\u53ef\u9bae\u5976',
            '\u62b9\u8336\u62ff\u9435',
            '\u7119\u8336\u62ff\u9435',
            '\u53ef\u53ef\u62ff\u9435',
            '\u5496\u5561\u62ff\u9435',
            '\u7f8e\u5f0f\u5496\u5561',
            '\u51b7\u8403\u5496\u5561',
            '\u6fc3\u7e2e\u5496\u5561',
            '\u5361\u5e03\u5947\u8afe',
            '\u99e5\u5217\u767d',
            '\u7126\u7cd6\u746a\u5947\u6735',
            '\u6469\u5361\u5496\u5561',
            '\u897f\u897f\u91cc\u5496\u5561',
            '\u9999\u8349\u62ff\u9435',
            '\u7126\u7cd6\u62ff\u9435',
            '\u9ed1\u7cd6\u71d5\u9ea5\u62ff\u9435',
            '\u6d77\u9e7d\u5976\u84cb\u9752',
            '\u6d77\u9e7d\u5976\u84cb\u7d05',
            '\u73cd\u73e0\u7d05\u8336\u62ff\u9435',
            '\u8c46\u6f3f',
            '\u7121\u7cd6\u8c46\u6f3f',
            '\u8c46\u6f3f\u7d05\u8336',
            '\u8c46\u6f3f\u5976\u8336',
            '\u73cd\u73e0\u8c46\u6f3f\u7d05\u8336',
            '\u71d5\u9ea5\u5976\u8336',
            '\u71d5\u9ea5\u62ff\u9435',
            '\u6842\u82b1\u70cf\u9f8d',
            '\u6842\u82b1\u51cd\u70cf\u9f8d',
            '\u871c\u6843\u70cf\u9f8d',
            '\u7d05\u67da\u7fe1\u7fe0',
            '\u4e09\u5341\u4e09\u8336\u738b',
            '\u592a\u6975\u9bae\u5976\u8336',
            '\u91d1\u8431\u96d9\u0051',
            '\u6d77\u795e',
            '\u78a7\u87ba\u6625',
            '\u8001\u6d3e\u5341\u5206\u8336',
            '\u6d3b\u83cc\u591a\u591a\u7da0',
            '\u9178\u67d1\u9752\u8336',
            '\u82f1\u5f0f\u7d05\u8336',
            '\u9f8d\u773c\u871c\u8336',
            '\u689d\u5b50\u8001\u4eba\u8336',
            '\u65e5\u5b89\u7d05\u6f38\u5c64\u9bae\u5976',
            '\u68c9\u88ab\u5348\u8317\u7da0',
            '\u68c9\u88ab\u53ef\u53ef',
            '\u829d\u829d\u91d1\u8431',
            '\u7fe1\u7fe0\u6ab8\u6aac',
            '\u6cb9\u5207\u70cf\u9f8d',
            '\u592a\u6975\u9bae\u5976',
          ]
        : const <String>[];

    final toppingOptions = isZh
        ? const <String>[
            '\u73cd\u73e0',
            '\u5c0f\u73cd\u73e0',
            '\u767d\u7389',
            '\u6ce2\u9738',
            '\u7c89\u89d2',
            '\u7c89\u689d',
            '\u6930\u679c',
            '\u4ed9\u8349\u51cd',
            '\u611b\u7389',
            '\u5bd2\u5929',
            '\u849f\u84bb',
            '\u5e03\u4e01',
            '\u5976\u84cb',
            '\u5976\u971c',
            '\u829d\u58eb\u5976\u84cb',
            '\u7d05\u8c46',
            '\u7da0\u8c46',
            '\u828b\u5713',
            '\u5730\u74dc\u5713',
            '\u7c89\u7cbf',
            '\u8606\u8588',
            '\u897f\u7c73\u9732',
            '\u8336\u51cd',
            '\u5496\u5561\u51cd',
            '\u7da0\u8336\u51cd',
            '\u871c\u9999\u51cd',
            '\u8354\u679d\u51cd',
            '\u9ed1\u7cd6\u51cd',
            '\u6842\u82b1\u51cd',
            '\u674f\u4ec1\u51cd',
            '\u5976\u916a',
            '\u82cb\u6ce5',
            '\u5947\u4e9e\u7c7d',
            '\u8461\u8404\u67da\u679c\u7c92',
            '\u7206\u7206\u73e0',
            '\u5575\u5575\u73e0',
          ]
        : const <String>[
            'boba',
            'pearl',
            'mini boba',
            'white pearl',
            'coconut jelly',
            'grass jelly',
            'aiyu jelly',
            'agar jelly',
            'konjac jelly',
            'pudding',
            'cheese foam',
            'milk foam',
            'red bean',
            'mung bean',
            'taro balls',
            'sweet potato balls',
            'rice jelly',
            'rice noodle jelly',
            'aloe',
            'sago pearls',
            'tea jelly',
            'coffee jelly',
            'green tea jelly',
            'honey jelly',
            'lychee jelly',
            'brown sugar jelly',
            'osmanthus jelly',
            'almond jelly',
            'panna cotta',
            'taro paste',
            'chia seeds',
            'grapefruit pulp',
            'popping boba',
          ];

    final queryWantsTopping = isZh
        ? normalizedQuery.contains('\u52a0') ||
            normalizedQuery.contains('\u6599') ||
            normalizedQuery.contains('\u96d9Q') ||
            normalizedQuery.contains('\u96d9\u6599') ||
            normalizedQuery.contains('\u96d9\u62fc') ||
            normalizedQuery.contains('q') ||
            toppingOptions.any(tokenMatches)
        : normalizedQuery.contains('with') ||
            normalizedQuery.contains('topping') ||
            toppingOptions.any(tokenMatches);

    final explicitToppings =
        toppingOptions.where((value) => tokenMatches(value)).toList();
    final activeToppings = explicitToppings.isNotEmpty
        ? explicitToppings
        : toppingOptions.take(queryWantsTopping ? 20 : 12).toList();

    final matchedBases = <String>[];
    for (final profile in baseProfiles) {
      final name = (profile['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      final tokens = (profile['tokens'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      final matched =
          tokenMatches(name) || tokens.any((token) => tokenMatches(token));
      if (matched && !matchedBases.contains(name)) {
        matchedBases.add(name);
      }
    }
    if (matchedBases.isEmpty) {
      matchedBases.add(isZh ? '\u9752\u8336' : 'green tea');
    }

    final matchedBrands = <Map<String, dynamic>>[];
    if (isZh && brandProfiles.isNotEmpty) {
      for (final profile in brandProfiles) {
        final name = (profile['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final tokens = (profile['tokens'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        final matched =
            tokenMatches(name) || tokens.any((token) => tokenMatches(token));
        if (matched) matchedBrands.add(profile);
      }
    }

    final matchedPopularItems = <String>[];
    if (isZh && popularMenuItems.isNotEmpty) {
      for (final item in popularMenuItems) {
        if (tokenMatches(item) && !matchedPopularItems.contains(item)) {
          matchedPopularItems.add(item);
        }
      }
      if (matchedPopularItems.isEmpty && compactQuery.length <= 2) {
        matchedPopularItems.addAll(popularMenuItems.take(20));
      }
    }

    const fruitTokens = <String>[
      '\u6ab8\u6aac',
      '\u767e\u9999',
      '\u8461\u8404\u67da',
      '\u7d05\u67da',
      '\u8292\u679c',
      '\u82ad\u6a02',
      '\u9cf3\u68a8',
      '\u860b\u679c',
      '\u767d\u6843',
      '\u8354\u679d',
      '\u67f3\u6a59',
      '\u91d1\u6854',
      '\u6851\u845a',
      '\u6885\u5b50',
      '\u70cf\u6885',
      '\u6c34\u871c\u6843',
      '\u694a\u679d',
      '\u7d42\u5408\u679c',
    ];
    const teaTokens = <String>[
      '\u7da0\u8336',
      '\u9752\u8336',
      '\u7d05\u8336',
      '\u70cf\u9f8d\u8336',
      '\u56db\u5b63\u6625',
      '\u91d1\u8431',
      '\u89c0\u97f3',
    ];

    final matchedFruitTokens = isZh
        ? fruitTokens.where((value) => tokenMatches(value)).toList()
        : const <String>[];
    final matchedTeaTokens = isZh
        ? teaTokens.where((value) => tokenMatches(value)).toList()
        : const <String>[];
    final wantsFruitTea = isZh &&
        (normalizedQuery.contains('\u679c') ||
            normalizedQuery.contains('\u8336') ||
            matchedFruitTokens.isNotEmpty ||
            matchedTeaTokens.isNotEmpty);

    final suggestions = <String>[];
    final seen = <String>{};
    void addSuggestion(String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      final key = _normalizeFoodLookupText(text);
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      suggestions.add(text);
    }

    if (isZh && matchedPopularItems.isNotEmpty) {
      for (final item in matchedPopularItems.take(28)) {
        final isCoffeeItem = item.contains('\u5496\u5561') ||
            item.contains('\u62ff\u9435') ||
            item.contains('\u5361\u5e03') ||
            item.contains('\u746a\u5947\u6735') ||
            item.contains('\u99e5\u5217\u767d') ||
            item.contains('\u6469\u5361') ||
            item.contains('\u7f8e\u5f0f') ||
            item.contains('\u51b7\u8403');
        addSuggestion(item);
        addSuggestion('$item \u534a\u7cd6');
        addSuggestion('$item \u5fae\u7cd6');
        addSuggestion('$item \u7121\u7cd6');
        if (isCoffeeItem) {
          addSuggestion('$item \u7121\u7cd6\u52a0\u71d5\u9ea5\u5976');
          addSuggestion('$item \u7121\u7cd6\u52a0\u4e00\u4efd\u6fc3\u7e2e');
        } else if (queryWantsTopping) {
          for (final topping in activeToppings.take(3)) {
            addSuggestion('$item \u534a\u7cd6\u52a0$topping');
          }
        }
      }
    }

    if (wantsFruitTea) {
      final fruits = matchedFruitTokens.isNotEmpty
          ? matchedFruitTokens
          : fruitTokens.take(10).toList();
      final teas = matchedTeaTokens.isNotEmpty
          ? matchedTeaTokens
          : teaTokens.take(5).toList();
      for (final fruit in fruits.take(12)) {
        for (final tea in teas.take(5)) {
          final combo = '$fruit$tea';
          addSuggestion(combo);
          addSuggestion('$combo \u534a\u7cd6');
          addSuggestion('$combo \u5fae\u7cd6');
          addSuggestion('$combo \u7121\u7cd6');
          if (queryWantsTopping) {
            for (final topping in activeToppings.take(2)) {
              addSuggestion('$combo \u534a\u7cd6\u52a0$topping');
            }
          }
        }
      }
    }

    if (isZh && matchedBrands.isNotEmpty) {
      for (final brand in matchedBrands.take(5)) {
        final brandName = (brand['name'] ?? '').toString().trim();
        if (brandName.isEmpty) continue;
        final signatures = (brand['signatures'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
        for (final drink in signatures.take(6)) {
          addSuggestion('$brandName $drink');
          addSuggestion('$brandName $drink \u534a\u7cd6');
          addSuggestion('$brandName $drink \u5fae\u7cd6');
          addSuggestion('$brandName $drink \u7121\u7cd6');
          addSuggestion('$brandName $drink \u4e2d\u676f\u534a\u7cd6');
          addSuggestion('$brandName $drink \u5927\u676f\u5fae\u7cd6');
          if (queryWantsTopping) {
            for (final topping in activeToppings.take(5)) {
              addSuggestion('$brandName $drink \u534a\u7cd6\u52a0$topping');
            }
            if (activeToppings.length >= 2) {
              final first = activeToppings[0];
              final second = activeToppings[1];
              addSuggestion(
                  '$brandName $drink \u534a\u7cd6\u52a0$first\u52a0$second');
            }
          }
        }
      }
    }

    for (final base in matchedBases.take(6)) {
      addSuggestion(base);
      if (isZh) {
        final isCoffeeBase = base.contains('\u5496\u5561') ||
            base.contains('\u62ff\u9435') ||
            base.contains('\u5361\u5e03') ||
            base.contains('\u746a\u5947\u6735') ||
            base.contains('\u99e5\u5217\u767d') ||
            base.contains('\u6469\u5361') ||
            base.contains('\u7f8e\u5f0f') ||
            base.contains('\u51b7\u8403') ||
            base.contains('\u6fc3\u7e2e');
        const sugarVariants = <String>[
          '\u7121\u7cd6',
          '\u5fae\u7cd6',
          '\u5c11\u7cd6',
          '\u4e00\u5206\u7cd6',
          '\u4e09\u5206\u7cd6',
          '\u534a\u7cd6',
          '\u4e03\u5206\u7cd6',
          '\u5168\u7cd6',
          '\u6b63\u5e38\u7cd6',
        ];
        const sizeVariants = <String>[
          '\u4e2d\u676f',
          '\u5927\u676f',
          '\u5c0f\u676f',
        ];
        for (final variant in sugarVariants) {
          addSuggestion('$base $variant');
        }
        for (final size in sizeVariants) {
          addSuggestion('$base $size \u534a\u7cd6');
        }

        if (isCoffeeBase) {
          const coffeeOptions = <String>[
            '\u7121\u7cd6\u52a0\u71d5\u9ea5\u5976',
            '\u7121\u7cd6\u52a0\u8c46\u4e73',
            '\u7121\u7cd6\u52a0\u4e00\u4efd\u6fc3\u7e2e',
            '\u7121\u7cd6\u52a0\u5169\u4efd\u6fc3\u7e2e',
            '\u5fae\u7cd6\u52a0\u4f4e\u8102\u5976',
          ];
          for (final option in coffeeOptions) {
            addSuggestion('$base $option');
          }
        } else {
          final toppingCount = queryWantsTopping ? 16 : 8;
          for (final topping in activeToppings.take(toppingCount)) {
            addSuggestion('$base \u52a0$topping');
            addSuggestion('$base \u534a\u7cd6\u52a0$topping');
            addSuggestion('$base \u5fae\u7cd6\u52a0$topping');
          }
          if (activeToppings.length >= 2) {
            final first = activeToppings[0];
            final second = activeToppings[1];
            addSuggestion('$base \u534a\u7cd6\u52a0$first\u52a0$second');
            addSuggestion('$base \u5fae\u7cd6\u52a0$first\u52a0$second');
          }
          if (base.contains('\u5976\u8336') || base.contains('\u62ff\u9435')) {
            addSuggestion('$base \u534a\u7cd6\u52a0\u5976\u84cb');
            addSuggestion('$base \u534a\u7cd6\u52a0\u5e03\u4e01');
            addSuggestion('$base \u534a\u7cd6\u52a0\u5c0f\u73cd\u73e0');
          }
        }
      } else {
        const sugarVariants = <String>[
          'unsweetened',
          'light sugar',
          'less sugar',
          'half sugar',
          'regular sugar',
        ];
        for (final variant in sugarVariants) {
          addSuggestion('$base $variant');
        }
        for (final topping in activeToppings.take(queryWantsTopping ? 16 : 8)) {
          addSuggestion('$base with $topping');
          addSuggestion('$base half sugar with $topping');
        }
      }
      if (suggestions.length >= maxCount * 6) break;
    }

    int suggestionScore(String value) {
      var score = (_nameSuggestionScore(value, normalizedQuery) * 10).round();
      final normalized = _normalizeFoodLookupText(value);
      if (normalized.startsWith(normalizedQuery)) score += 20;
      if (queryWantsTopping &&
          (isZh ? value.contains('\u52a0') : value.contains('with'))) {
        score += 8;
      }
      return score;
    }

    suggestions
        .sort((a, b) => suggestionScore(b).compareTo(suggestionScore(a)));
    return suggestions.take(maxCount).toList();
  }

  List<String> _catalogLookupCandidates(String rawInput) {
    final candidates = <String>[];
    final seen = <String>{};
    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final key = _normalizeFoodLookupText(trimmed);
      if (key.isEmpty || seen.contains(key)) return;
      seen.add(key);
      candidates.add(trimmed);
    }

    final normalized = _normalizeFoodLookupText(rawInput);
    add(rawInput);
    add(normalized);

    final collapsed = normalized.replaceAll(' ', '');
    add(collapsed);

    final simplified = _stripDrinkModifiers(collapsed);
    add(simplified);
    add(_normalizeFoodLookupText(simplified));

    if (candidates.length > 5) {
      return candidates.take(5).toList();
    }
    return candidates;
  }

  String _stripDrinkModifiers(String text) {
    var value = text.trim();
    if (value.isEmpty) return value;

    final hasDrinkHint = RegExp(
      r'(飲|喝|茶|咖啡|奶|豆漿|果汁|可可|latte|tea|coffee|drink|beverage|milk|juice|boba|smoothie)',
      caseSensitive: false,
    ).hasMatch(value);
    if (!hasDrinkHint) return value;

    final patterns = <RegExp>[
      // Common drink options and serving modifiers.
      RegExp(
        r'(無糖|微糖|半糖|少糖|全糖|正常糖|去冰|少冰|微冰|常溫|熱飲|冰飲|熱|冷|大杯|中杯|小杯|加料|珍珠|椰果|布丁|奶蓋|去奶|加奶|extra|less|no)\s*',
        caseSensitive: false,
      ),
      // Common beverage base words.
      RegExp(
        r'(豆漿|鮮奶茶|奶茶|紅茶|綠茶|青茶|烏龍|美式|拿鐵|可可|咖啡|果汁|latte|tea|coffee|drink|beverage|milk|juice|boba|smoothie)\s*',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      value = value.replaceAll(pattern, '');
    }
    value = value.replaceAll(RegExp(r'\s+'), '');
    return value.trim();
  }

  bool _matchesLookupToken(
    String normalized,
    String compact,
    String token,
  ) {
    final normalizedToken = _normalizeFoodLookupText(token);
    if (normalizedToken.isEmpty) return false;
    final compactToken = normalizedToken.replaceAll(' ', '');
    if (normalized.contains(normalizedToken)) return true;
    if (compact.contains(compactToken)) return true;
    return false;
  }

  _BeverageParseResult? _parseBeverageName(String input, String locale) {
    final normalized = _normalizeFoodLookupText(input);
    final compact = normalized.replaceAll(' ', '');
    final isZh = locale.toLowerCase().startsWith('zh');
    final hasHint = _kBeverageHintTokens
        .any((token) => _matchesLookupToken(normalized, compact, token));
    if (!hasHint) return null;

    _BeverageProfile? profile;
    for (final candidate in _kBeverageProfiles) {
      if (candidate.tokens
          .any((token) => _matchesLookupToken(normalized, compact, token))) {
        profile = candidate;
        break;
      }
    }
    if (profile == null) {
      return null;
    }

    final (sizeFactor, sizeLabel) =
        _detectBeverageSize(normalized, compact, isZh);
    final (sugarRatio, sugarLabel, explicitSugar) =
        _detectBeverageSugar(normalized, compact, profile, isZh);
    final iceLabel = _detectBeverageIce(normalized, compact, isZh);
    final toppings = _detectBeverageToppings(normalized, compact);
    return _BeverageParseResult(
      profile: profile,
      sizeFactor: sizeFactor,
      sizeLabel: sizeLabel,
      sugarRatio: sugarRatio,
      sugarLabel: sugarLabel,
      iceLabel: iceLabel,
      toppings: toppings,
      explicitSugar: explicitSugar,
    );
  }

  List<String> _localBeverageSuggestions(
    String query,
    String locale, {
    int limit = 8,
  }) {
    final normalizedQuery = _normalizeFoodLookupText(query);
    if (normalizedQuery.isEmpty) return const [];
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    final isZh = locale.toLowerCase().startsWith('zh');

    final results = <String>[];
    final seen = <String>{};
    bool tokenMatchesQuery(String token) {
      final normalizedToken = _normalizeFoodLookupText(token);
      if (normalizedToken.isEmpty) return false;
      final compactToken = normalizedToken.replaceAll(' ', '');
      if (normalizedToken.contains(normalizedQuery) ||
          compactToken.contains(compactQuery)) {
        return true;
      }
      if (normalizedQuery.contains(normalizedToken) ||
          compactQuery.contains(compactToken)) {
        return true;
      }
      return false;
    }

    void add(String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      final key = _normalizeFoodLookupText(text);
      if (key.isEmpty || seen.contains(key)) return;
      final score = _nameSuggestionScore(text, normalizedQuery);
      if (score <= 0) return;
      seen.add(key);
      results.add(text);
    }

    for (final profile in _kBeverageProfiles) {
      final matched = profile.tokens.any(tokenMatchesQuery);
      if (!matched) continue;

      final base = isZh ? profile.nameZh : profile.nameEn;
      add(base);
      if (isZh) {
        add('$base 無糖去冰');
        add('$base 半糖去冰');
        add('$base 微糖少冰');
      } else {
        add('$base unsweetened');
        add('$base half sugar no ice');
        add('$base light sugar less ice');
      }

      if (profile.key == 'tea' && isZh) {
        add('青茶');
        add('紅茶');
        add('綠茶');
        add('烏龍茶');
      }
      if (results.length >= limit * 2) break;
    }

    for (final topping in _kBeverageToppings) {
      final matched = topping.tokens.any(tokenMatchesQuery);
      if (!matched) continue;
      if (isZh) {
        add('奶茶加${topping.nameZh}');
        add('青茶加${topping.nameZh}');
      } else {
        add('milk tea with ${topping.nameEn}');
      }
      if (results.length >= limit * 2) break;
    }

    results.sort((a, b) => _nameSuggestionScore(b, normalizedQuery)
        .compareTo(_nameSuggestionScore(a, normalizedQuery)));
    return results.take(limit).toList();
  }

  (double, String) _detectBeverageSize(
    String normalized,
    String compact,
    bool isZh,
  ) {
    if (_matchesLookupToken(normalized, compact, '特大杯') ||
        _matchesLookupToken(normalized, compact, '超大杯') ||
        _matchesLookupToken(normalized, compact, 'xlarge') ||
        _matchesLookupToken(normalized, compact, 'xl')) {
      return (1.45, isZh ? '特大杯' : 'x-large');
    }
    if (_matchesLookupToken(normalized, compact, '大杯') ||
        _matchesLookupToken(normalized, compact, 'large')) {
      return (1.25, isZh ? '大杯' : 'large');
    }
    if (_matchesLookupToken(normalized, compact, '小杯') ||
        _matchesLookupToken(normalized, compact, 'small')) {
      return (0.8, isZh ? '小杯' : 'small');
    }
    return (1.0, isZh ? '中杯' : 'medium');
  }

  (double, String, bool) _detectBeverageSugar(
    String normalized,
    String compact,
    _BeverageProfile profile,
    bool isZh,
  ) {
    double ratio = profile.defaultSugarRatio;
    bool explicit = false;

    if (_matchesLookupToken(normalized, compact, '無糖') ||
        _matchesLookupToken(normalized, compact, '零糖') ||
        _matchesLookupToken(normalized, compact, 'no sugar') ||
        _matchesLookupToken(normalized, compact, 'sugar free') ||
        _matchesLookupToken(normalized, compact, 'unsweetened')) {
      ratio = 0.0;
      explicit = true;
    } else if (_matchesLookupToken(normalized, compact, '微糖') ||
        _matchesLookupToken(normalized, compact, '一分糖') ||
        _matchesLookupToken(normalized, compact, 'quarter sugar')) {
      ratio = 0.25;
      explicit = true;
    } else if (_matchesLookupToken(normalized, compact, '少糖') ||
        _matchesLookupToken(normalized, compact, '三分糖') ||
        _matchesLookupToken(normalized, compact, 'less sugar')) {
      ratio = 0.3;
      explicit = true;
    } else if (_matchesLookupToken(normalized, compact, '半糖') ||
        _matchesLookupToken(normalized, compact, '五分糖') ||
        _matchesLookupToken(normalized, compact, 'half sugar')) {
      ratio = 0.5;
      explicit = true;
    } else if (_matchesLookupToken(normalized, compact, '七分糖')) {
      ratio = 0.7;
      explicit = true;
    } else if (_matchesLookupToken(normalized, compact, '全糖') ||
        _matchesLookupToken(normalized, compact, '正常糖') ||
        _matchesLookupToken(normalized, compact, 'full sugar') ||
        _matchesLookupToken(normalized, compact, 'regular sugar')) {
      ratio = 1.0;
      explicit = true;
    }

    ratio = ratio.clamp(0.0, 1.0);
    final percent = (ratio * 100).round();
    final sugarLabel = isZh ? '${percent}%糖' : '$percent% sugar';
    return (ratio, sugarLabel, explicit);
  }

  String _detectBeverageIce(
    String normalized,
    String compact,
    bool isZh,
  ) {
    if (_matchesLookupToken(normalized, compact, '去冰') ||
        _matchesLookupToken(normalized, compact, 'no ice')) {
      return isZh ? '去冰' : 'no ice';
    }
    if (_matchesLookupToken(normalized, compact, '少冰') ||
        _matchesLookupToken(normalized, compact, 'light ice')) {
      return isZh ? '少冰' : 'light ice';
    }
    if (_matchesLookupToken(normalized, compact, '微冰')) {
      return isZh ? '微冰' : 'mild ice';
    }
    if (_matchesLookupToken(normalized, compact, '熱') ||
        _matchesLookupToken(normalized, compact, 'hot')) {
      return isZh ? '熱飲' : 'hot';
    }
    if (_matchesLookupToken(normalized, compact, '常溫') ||
        _matchesLookupToken(normalized, compact, 'room temperature')) {
      return isZh ? '常溫' : 'room temperature';
    }
    return '';
  }

  List<_BeverageToppingProfile> _detectBeverageToppings(
    String normalized,
    String compact,
  ) {
    final matched = <_BeverageToppingProfile>[];
    for (final topping in _kBeverageToppings) {
      final hit = topping.tokens
          .any((token) => _matchesLookupToken(normalized, compact, token));
      if (hit) {
        matched.add(topping);
      }
    }
    return matched;
  }

  AnalysisResult? _buildBeverageFormulaResult(String input, String locale) {
    final parsed = _parseBeverageName(input, locale);
    if (parsed == null) return null;
    final isZh = locale.toLowerCase().startsWith('zh');
    final profile = parsed.profile;

    var protein = profile.baseProtein * parsed.sizeFactor;
    var carbs = profile.baseCarbs * parsed.sizeFactor;
    var fat = profile.baseFat * parsed.sizeFactor;
    var sodium = profile.baseSodium * parsed.sizeFactor;

    if (profile.sugarAdjustable) {
      carbs += profile.fullSugarCarbs * parsed.sugarRatio * parsed.sizeFactor;
    }

    for (final topping in parsed.toppings) {
      protein += topping.protein;
      carbs += topping.carbs;
      fat += topping.fat;
      sodium += topping.sodium;
    }

    protein = max(0, protein);
    carbs = max(0, carbs);
    fat = max(0, fat);
    sodium = max(0, sodium);

    final kcal = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0);
    final low = max(30, (kcal * 0.9).round());
    final high = max(low + 20, (kcal * 1.1).round());
    final calorieRange = '$low-$high kcal';

    final toppingNames = parsed.toppings
        .map((item) => isZh ? item.nameZh : item.nameEn)
        .toList(growable: false);
    final foodItems = <String>[isZh ? profile.nameZh : profile.nameEn];
    foodItems.addAll(toppingNames);

    final summaryParts = <String>[
      isZh ? profile.nameZh : profile.nameEn,
      parsed.sizeLabel,
      parsed.sugarLabel,
      if (parsed.iceLabel.isNotEmpty) parsed.iceLabel,
      if (toppingNames.isNotEmpty)
        (isZh
            ? '加${toppingNames.join('、')}'
            : 'with ${toppingNames.join(', ')}'),
    ];

    final judgementTags = <String>[];
    if (carbs >= 45) judgementTags.add(isZh ? '碳水偏多' : 'Higher carbs');
    if (parsed.sugarRatio >= 0.7 || (parsed.explicitSugar && carbs >= 35)) {
      judgementTags.add(isZh ? '高糖' : 'High sugar');
    }
    if (fat >= 18) judgementTags.add(isZh ? '偏油' : 'Higher fat');
    if (judgementTags.isEmpty) {
      judgementTags.add(isZh ? '清淡' : 'Light');
    }

    final suggestion = _buildBeverageSuggestion(
      isZh: isZh,
      carbs: carbs,
      sugarRatio: parsed.sugarRatio,
      toppings: parsed.toppings,
      profile: profile,
    );

    return AnalysisResult(
      foodName: input,
      calorieRange: calorieRange,
      macros: {
        'protein': ((protein * 10).round() / 10),
        'carbs': ((carbs * 10).round() / 10),
        'fat': ((fat * 10).round() / 10),
        'sodium': ((sodium * 10).round() / 10),
      },
      foodItems: foodItems,
      judgementTags: judgementTags.take(3).toList(),
      dishSummary: isZh
          ? '飲料規則估算：${summaryParts.join('，')}'
          : 'Beverage rule estimate: ${summaryParts.join(', ')}',
      suggestion: suggestion,
      tier: 'catalog',
      source: 'beverage_formula',
      nutritionSource: 'beverage_formula',
      referenceUsed: isZh ? '飲料規則估算' : 'beverage rules',
      confidence: 0.62,
      isBeverage: true,
      isFood: true,
    );
  }

  String _buildBeverageSuggestion({
    required bool isZh,
    required double carbs,
    required double sugarRatio,
    required List<_BeverageToppingProfile> toppings,
    required _BeverageProfile profile,
  }) {
    if (isZh) {
      if (sugarRatio >= 0.7 || carbs >= 45) {
        return '這杯糖量偏高，建議下次改半糖或少糖，並避免再加含糖點心。';
      }
      if (toppings.isNotEmpty) {
        return '你有加配料，熱量主要來自配料碳水；若在控脂期可改無配料。';
      }
      if (profile.key == 'soy_milk' || profile.key == 'latte') {
        return '這杯蛋白質相對較好，可搭配低糖主食，讓整餐更平衡。';
      }
      return '建議和正餐錯開，並優先選擇低糖版本，避免影響整日熱量控制。';
    }
    if (sugarRatio >= 0.7 || carbs >= 45) {
      return 'Sugar load is high. Next time consider half/less sugar and skip extra sweet snacks.';
    }
    if (toppings.isNotEmpty) {
      return 'Most extra calories come from toppings. Remove toppings if you are cutting.';
    }
    return 'Prefer lower sugar options and pair with balanced meals to keep daily intake stable.';
  }

  Map<String, dynamic>? _bestCatalogFoodMatch(
    String query,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return null;
    final normalizedQuery = _normalizeFoodLookupText(query);
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    Map<String, dynamic>? bestPrefix;
    double bestPrefixScore = -1;
    Map<String, dynamic>? bestByScore;
    double bestScore = -1;
    for (final item in items) {
      final alias = _normalizeFoodLookupText((item['alias'] as String?) ?? '');
      final foodName =
          _normalizeFoodLookupText((item['food_name'] as String?) ?? '');
      final aliasCompact = alias.replaceAll(' ', '');
      final foodCompact = foodName.replaceAll(' ', '');
      final score = _catalogMatchScore(item);
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
      if (!startsWith) continue;
      if (score > bestPrefixScore) {
        bestPrefix = item;
        bestPrefixScore = score;
      }
      if (score > bestScore) {
        bestByScore = item;
        bestScore = score;
      }
    }
    if (bestPrefix != null && bestPrefixScore >= 3.5) {
      return bestPrefix;
    }
    // No prefix hit: allow a strong score-only fallback match.
    if (bestByScore != null && bestScore >= 4.0) {
      return bestByScore;
    }
    return null;
  }

  double _catalogMatchScore(Map<String, dynamic> item) {
    final raw = item['match_score'];
    if (raw is num) return raw.toDouble();
    return 0;
  }

  AnalysisResult _catalogItemToAnalysisResult(
    Map<String, dynamic> item,
    String locale, {
    required String fallbackName,
  }) {
    final rawFoodName = (item['food_name'] ?? '').toString().trim();
    final foodName = rawFoodName.isNotEmpty ? rawFoodName : fallbackName;
    String calorieRange = ((item['calorie_range'] as String?) ?? '').trim();
    if (calorieRange.isEmpty) {
      final kcalRaw = item['kcal_100g'];
      final kcal = kcalRaw is num ? kcalRaw.toDouble() : null;
      if (kcal != null && kcal > 0) {
        final low = (kcal * 0.9).round();
        final high = (kcal * 1.1).round();
        calorieRange = '$low-$high kcal';
      }
    }
    if (calorieRange.isEmpty) {
      calorieRange = '0-0 kcal';
    }
    final parsedMacros = _parseMacros(item['macros']);
    final macros = <String, double>{
      'protein': parsedMacros['protein'] ?? 0,
      'carbs': parsedMacros['carbs'] ?? 0,
      'fat': parsedMacros['fat'] ?? 0,
      'sodium': parsedMacros['sodium'] ?? 0,
    };

    final foodItems = _parseStringListValue(item['food_items']);
    if (foodItems.isEmpty) {
      foodItems.add(foodName);
    }

    final judgementTags = _parseStringListValue(item['judgement_tags']);
    if (judgementTags.isEmpty) {
      judgementTags.addAll(_parseStringListValue(item['summary_tags']));
    }
    if (judgementTags.isEmpty) {
      judgementTags.addAll(
        _catalogFallbackJudgementTags(
          macros: macros,
          calorieRange: calorieRange,
          locale: locale,
        ),
      );
    }

    final suggestionRaw = ((item['suggestion'] as String?) ?? '').trim();
    final summaryRaw = ((item['dish_summary'] as String?) ?? '').trim();
    final matchScoreRaw = item['match_score'];
    final confidence = matchScoreRaw is num
        ? matchScoreRaw.toDouble()
        : double.tryParse(matchScoreRaw?.toString() ?? '');
    final sourceRaw = (item['source'] ?? '').toString().trim();
    final nutritionSourceRaw =
        (item['nutrition_source'] ?? '').toString().trim();
    final referenceUsedRaw = (item['reference_used'] ?? '').toString().trim();
    final catalogImageUrlRaw = (item['image_url'] ?? '').toString().trim();
    final catalogThumbUrlRaw = (item['thumb_url'] ?? '').toString().trim();
    final catalogImageSourceRaw =
        (item['image_source'] ?? '').toString().trim();
    final catalogImageLicenseRaw =
        (item['image_license'] ?? '').toString().trim();

    return AnalysisResult(
      foodName: foodName,
      calorieRange: calorieRange,
      macros: macros,
      foodItems: foodItems,
      judgementTags: judgementTags.take(3).toList(),
      dishSummary: summaryRaw.isNotEmpty ? summaryRaw : null,
      suggestion: suggestionRaw.isNotEmpty
          ? suggestionRaw
          : (locale.startsWith('zh')
              ? '此結果由資料庫估算，若補充份量或品牌資訊會更準確。'
              : 'Estimated from the food catalog. Add portion or brand details for better accuracy.'),
      tier: 'catalog',
      source: sourceRaw.isNotEmpty ? sourceRaw : 'catalog',
      nutritionSource:
          nutritionSourceRaw.isNotEmpty ? nutritionSourceRaw : 'catalog',
      confidence: confidence,
      isBeverage:
          item['is_beverage'] is bool ? item['is_beverage'] as bool : null,
      isFood: item['is_food'] is bool ? item['is_food'] as bool : true,
      catalogImageUrl:
          catalogImageUrlRaw.isNotEmpty ? catalogImageUrlRaw : null,
      catalogThumbUrl:
          catalogThumbUrlRaw.isNotEmpty ? catalogThumbUrlRaw : null,
      catalogImageSource:
          catalogImageSourceRaw.isNotEmpty ? catalogImageSourceRaw : null,
      catalogImageLicense:
          catalogImageLicenseRaw.isNotEmpty ? catalogImageLicenseRaw : null,
      referenceUsed: referenceUsedRaw.isNotEmpty
          ? referenceUsedRaw
          : (locale.startsWith('zh') ? '資料庫' : 'catalog'),
    );
  }

  List<String> _parseStringListValue(dynamic raw) {
    final parsed = <String>[];

    void addItem(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty || parsed.contains(text)) return;
      parsed.add(text);
    }

    if (raw is List) {
      for (final item in raw) {
        addItem(item);
      }
      return parsed;
    }

    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return parsed;

    if (text.startsWith('[') && text.endsWith(']')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) {
          for (final item in decoded) {
            addItem(item);
          }
          return parsed;
        }
      } catch (_) {
        // Continue with delimiter split fallback.
      }
    }

    final normalized = text
        .replaceAll('，', ',')
        .replaceAll('、', ',')
        .replaceAll('；', ',')
        .replaceAll(';', ',');
    for (final part in normalized.split(',')) {
      addItem(part);
    }
    return parsed;
  }

  List<String> _catalogFallbackJudgementTags({
    required Map<String, double> macros,
    required String calorieRange,
    required String locale,
  }) {
    final protein = (macros['protein'] ?? 0).clamp(0, double.infinity);
    final carbs = (macros['carbs'] ?? 0).clamp(0, double.infinity);
    final fat = (macros['fat'] ?? 0).clamp(0, double.infinity);

    var calorieMid = calorieRangeMid(calorieRange) ?? 0;
    if (calorieMid <= 0) {
      calorieMid = (protein * 4) + (carbs * 4) + (fat * 9);
    }

    double fatPct = 0;
    double carbPct = 0;
    double proteinPct = 0;
    if (calorieMid > 0) {
      fatPct = (fat * 9 / calorieMid) * 100;
      carbPct = (carbs * 4 / calorieMid) * 100;
      proteinPct = (protein * 4 / calorieMid) * 100;
    }

    final isZh = locale.startsWith('zh');
    final tags = <String>[];
    if (fatPct >= 35) tags.add(isZh ? '偏油' : 'Heavier oil');
    if (carbPct >= 55) tags.add(isZh ? '碳水偏多' : 'Higher carbs');
    if ((proteinPct > 0 && proteinPct < 16) ||
        (proteinPct == 0 && protein < 12)) {
      tags.add(isZh ? '蛋白不足' : 'Low protein');
    }
    if (tags.isEmpty) {
      tags.add(isZh ? '清淡' : 'Light');
    }
    return tags.take(3).toList();
  }

  Future<MealEntry> _saveNameOnlyEntry({
    required DateTime time,
    required MealType mealType,
    required String mealId,
    required String inputFoodName,
    required AnalysisResult result,
    required String reason,
    String? lastAnalyzedNote,
  }) async {
    final entry = MealEntry(
      id: _newId(),
      imageBytes: _namePlaceholderBytes,
      filename: 'name_only.png',
      time: time,
      type: mealType,
      portionPercent: 100,
      updatedAt: DateTime.now().toUtc(),
      mealId: mealId,
      imageHash: _hashBytes(_namePlaceholderBytes),
      lastAnalyzedFoodName: inputFoodName,
    );
    entry.result = _resolveNutritionResult(result);
    entry.lastAnalyzedAt = DateTime.now().toIso8601String();
    entry.lastAnalyzeReason = reason;
    entry.lastAnalyzedNote = lastAnalyzedNote;
    entries.insert(0, entry);
    markMealInteraction(mealId);
    _selectedDate = _dateOnly(time);
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

  List<int>? proteinTargetRangeGrams() {
    final weight = profile.weightKg;
    if (weight <= 0) return null;
    final min = (weight * 0.8).round();
    final max = (weight * 1.2).round();
    if (min <= 0 || max <= 0) return null;
    return [min, max];
  }

  double dailyProteinConsumedGrams(DateTime date,
      {bool excludeBeverages = false}) {
    double sum = 0;
    for (final entry in entriesForDate(date)) {
      final result = entry.result;
      if (result == null) continue;
      if (excludeBeverages && result.isBeverage == true) continue;
      final weight = _entryPortionFactor(entry);
      sum += (result.macros['protein'] ?? 0) * weight;
    }
    return sum;
  }

  MealEntry? latestNonBeverageEntryForDate(DateTime date) {
    final list = entriesForDate(date);
    for (final entry in list) {
      final result = entry.result;
      if (result == null) continue;
      if (result.isBeverage == true) continue;
      return entry;
    }
    return null;
  }

  MealEntry? get latestNonBeverageEntryForSelectedDate {
    return latestNonBeverageEntryForDate(_selectedDate);
  }

  bool hasBeverageEntriesForDate(DateTime date) {
    return entriesForDate(date)
        .any((entry) => entry.result?.isBeverage == true);
  }

  bool hasNonBeverageEntriesForDate(DateTime date) {
    return entriesForDate(date).any(
        (entry) => entry.result == null || entry.result?.isBeverage != true);
  }

  bool _isBeverageOnlyDay(DateTime date) {
    return hasBeverageEntriesForDate(date) &&
        !hasNonBeverageEntriesForDate(date);
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
    final baseRange = entry.overrideCalorieRange ??
        entry.labelResult?.calorieRange ??
        entry.result?.calorieRange ??
        '';
    final parsed = _parseCalorieRange(baseRange);
    if (parsed == null) return t.calorieUnknown;
    final weight = _entryPortionFactor(entry);
    final minVal = (parsed[0] * weight).round();
    final maxVal = (parsed[1] * weight).round();
    return '$minVal-$maxVal kcal';
  }

  double? entryCalorieMid(MealEntry entry) {
    final baseRange = entry.overrideCalorieRange ??
        entry.labelResult?.calorieRange ??
        entry.result?.calorieRange;
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
      final summary =
          buildMealSummary(group, lookupAppLocalizations(_localeFromProfile()));
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
    final entry = latestNonBeverageEntryForSelectedDate;
    if (entry == null || entry.result == null) {
      if (_isBeverageOnlyDay(_selectedDate)) return t.summaryBeverageOnly;
      return t.suggestTodayHint;
    }
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
    final entry = latestNonBeverageEntryForSelectedDate;
    if (entry == null || entry.result == null) {
      if (_isBeverageOnlyDay(_selectedDate)) return t.summaryBeverageOnly;
      return t.summaryEmpty;
    }
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
      return (now.hour > target.hour) ||
          (now.hour == target.hour && now.minute >= target.minute);
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
      return (now.hour > t.hour) ||
          (now.hour == t.hour && now.minute >= t.minute);
    }
    return today.isAfter(target);
  }

  String dailySummaryPendingText(AppLocalizations t) {
    return t.summaryPendingAt(_timeToString(profile.dailySummaryTime));
  }

  String weeklySummaryPendingText(AppLocalizations t) {
    final weekdayLabel = _weekdayLabel(profile.weeklySummaryWeekday, t);
    return t.weekSummaryPendingAt(
        weekdayLabel, _timeToString(profile.dailySummaryTime));
  }

  String daySummaryText(DateTime date, AppLocalizations t) {
    final override = _dayOverrides[_dayKey(date)];
    final manual = override?['summary'];
    if (manual != null && manual.trim().isNotEmpty) return manual;
    if (!isDailySummaryReady(date)) return dailySummaryPendingText(t);
    final dayEntries = entriesForDate(date);
    if (dayEntries.isEmpty) return t.summaryEmpty;
    final nonBeverageEntries = dayEntries
        .where(
            (entry) => entry.result != null && entry.result?.isBeverage != true)
        .toList();
    if (nonBeverageEntries.isEmpty) {
      return _isBeverageOnlyDay(date) ? t.summaryBeverageOnly : t.summaryEmpty;
    }
    final fatScore = _aggregateMacroScore(nonBeverageEntries, 'fat', t);
    final carbScore = _aggregateMacroScore(nonBeverageEntries, 'carbs', t);
    final proteinScore = _aggregateMacroScore(nonBeverageEntries, 'protein', t);
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
    if (_isBeverageOnlyDay(date)) return t.nextMealHint;
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

  Future<bool> finalizeDay(
      DateTime date, String locale, AppLocalizations t) async {
    if (!canUseFeature(AppFeature.summary)) {
      return false;
    }
    final dayKey = _dayKey(date);
    final hadOverride = _dayOverrides.containsKey(dayKey);
    final groups = mealGroupsForDateAll(date);
    if (groups.isEmpty) return true;
    final mealGroups = _nonBeverageGroups(groups);
    if (mealGroups.isEmpty) {
      await updateDayOverride(
        date,
        summary: t.summaryBeverageOnly,
        tomorrowAdvice: t.nextMealHint,
      );
      _meta[_dayLockKey(date)] = 'true';
      await _saveOverrides();
      await _maybeFinalizeWeekForDate(date, locale, t);
      return true;
    }
    final meals = <Map<String, dynamic>>[];
    for (final group in mealGroups) {
      final summary = buildMealSummary(group, t);
      final dishSummaries = <String>[];
      for (final entry in group) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
        }
      }
      final collapsedSummaries = _appendSmallPortionSuffixToList(
        _collapseDishSummaries(dishSummaries, t),
        group,
        t,
      );
      meals.add({
        'meal_type': _mealTypeKey(group.first.type),
        'calorie_range': summary?.calorieRange ?? '',
        'dish_summaries': collapsedSummaries,
      });
    }
    final consumedKcal = dailyConsumedCalorieMid(date).round();
    final targetMid = targetCalorieMid(date);
    final remainingKcal =
        targetMid == null ? null : (targetMid - consumedKcal).round();
    final prevDate = _dateOnly(date).subtract(const Duration(days: 1));
    final prevKey = _dayKey(prevDate);
    final prevOverride = _dayOverrides[prevKey];
    final prevSummary = prevOverride?['summary']?.trim();
    final prevAdvice = prevOverride?['tomorrow_advice']?.trim();
    final payload = {
      'date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'lang': locale,
      'meals': meals,
      'day_calorie_range': _dailyCalorieRangeLabelForDate(date, t),
      'day_meal_count': mealGroups.length,
      'today_consumed_kcal': consumedKcal > 0 ? consumedKcal : null,
      'today_remaining_kcal': remainingKcal,
      if (prevSummary != null && prevSummary.isNotEmpty)
        'previous_day_summary': prevSummary,
      if (prevAdvice != null && prevAdvice.isNotEmpty)
        'previous_tomorrow_advice': prevAdvice,
      'profile': {
        'height_cm': profile.heightCm,
        'weight_kg': profile.weightKg,
        'age': profile.age,
        'gender': profile.gender,
        'assistant_name': profile.chatAssistantName,
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
    final success = _dayOverrides.containsKey(dayKey) || hadOverride;
    if (!success) {
      return false;
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
    return true;
  }

  Future<void> _maybeFinalizeWeekForDate(
      DateTime date, String locale, AppLocalizations t) async {
    final normalized = _dateOnly(date);
    final weekStart = _weekStartFor(normalized);
    final weekKey = _weekKey(weekStart);
    if (_weekOverrides.containsKey(weekKey)) {
      return;
    }
    final targetDate =
        weekStart.add(Duration(days: profile.weeklySummaryWeekday - 1));
    if (normalized.isBefore(targetDate)) {
      return;
    }
    if (_meta['last_auto_week'] == weekKey) {
      return;
    }
    final success = await finalizeWeek(normalized, locale, t);
    if (!success) {
      return;
    }
    _meta['last_auto_week'] = weekKey;
    await _saveOverrides();
  }

  Future<void> autoFinalizeToday() async {
    await runAutoFinalizeFlow();
    _scheduleAutoFinalize();
  }

  Future<bool> finalizeWeek(
      DateTime date, String locale, AppLocalizations t) async {
    if (!canUseFeature(AppFeature.summary)) {
      return false;
    }
    final weekStart = _weekStartFor(date);
    final weekKey = _weekKey(weekStart);
    final hadOverride = _weekOverrides.containsKey(weekKey);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final days = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final daySummary = buildDaySummary(day, t);
      if (daySummary == null) continue;
      final entriesFor = entriesForDate(day);
      final groups = mealGroupsForDateAll(day);
      final mealGroups = _nonBeverageGroups(groups);
      final dayMealSummaries = <String>[];
      for (final group in mealGroups) {
        if (group.isEmpty) continue;
        final summary = buildMealSummary(group, t);
        final dishSummaries = <String>[];
        for (final entry in group) {
          final summaryText = _entryDishSummary(entry, t);
          if (summaryText != null && summaryText.isNotEmpty) {
            dishSummaries.add(summaryText);
          }
        }
        final collapsedSummaries = _appendSmallPortionSuffixToList(
          _collapseDishSummaries(dishSummaries, t),
          group,
          t,
        );
        final label = _mealTypeLabel(group.first.type, t);
        final rangeText = summary?.calorieRange ?? t.calorieUnknown;
        final dishText =
            collapsedSummaries.isEmpty ? '' : collapsedSummaries.join(' / ');
        final parts = <String>[label];
        if (rangeText.isNotEmpty) parts.add(rangeText);
        if (dishText.isNotEmpty) parts.add(dishText);
        dayMealSummaries.add(parts.join(' · '));
      }
      days.add({
        'date':
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        'calorie_range': daySummary.calorieRange,
        'day_summary': daySummary.advice,
        'meal_count': mealGroups.length,
        'meal_entry_count': entriesFor.length,
        'day_meal_summaries': dayMealSummaries,
      });
    }
    if (days.isEmpty) return hadOverride;
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekKey = _weekKey(prevWeekStart);
    final prevWeekOverride = _weekOverrides[prevWeekKey];
    final prevWeekSummary = prevWeekOverride?['week_summary']?.trim();
    final prevWeekAdvice = prevWeekOverride?['next_week_advice']?.trim();
    final payload = {
      'week_start':
          '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}',
      'week_end':
          '${weekEnd.year.toString().padLeft(4, '0')}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}',
      'lang': locale,
      'days': days,
      if (prevWeekSummary != null && prevWeekSummary.isNotEmpty)
        'previous_week_summary': prevWeekSummary,
      if (prevWeekAdvice != null && prevWeekAdvice.isNotEmpty)
        'previous_next_week_advice': prevWeekAdvice,
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
    return _weekOverrides.containsKey(weekKey) || hadOverride;
  }

  Future<void> autoFinalizeWeek() async {
    await runAutoFinalizeFlow();
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
      final mealGroups = _nonBeverageGroups(dayGroups);
      final daySummary = buildDaySummary(mealDate, t);
      final summary = buildMealSummary(group, t);
      final consumedKcal = dailyConsumedCalorieMid(mealDate).round();
      final targetMid = targetCalorieMid(mealDate);
      final remainingKcal =
          targetMid == null ? null : (targetMid - consumedKcal).round();
      final lastMealInfo =
          _lastMealInfo(group.first.time, excludeMealId: mealId);
      final recentAdvice = _collectRecentMealAdvice(mealDate, t);
      final dishSummaries = <String>[];
      for (final entry in group) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
        }
      }
      final collapsedSummaries = _appendSmallPortionSuffixToList(
        _collapseDishSummaries(dishSummaries, t),
        group,
        t,
      );
      final dayMealSummaries = <String>[];
      for (final dayGroup in mealGroups) {
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
        final collapsedDaySummaries = _appendSmallPortionSuffixToList(
          _collapseDishSummaries(dayDishSummaries, t),
          dayGroup,
          t,
        );
        final dishText = collapsedDaySummaries.isEmpty
            ? ''
            : collapsedDaySummaries.join(' / ');
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
        'day_meal_count': mealGroups.length,
        'day_meal_summaries': dayMealSummaries,
        'today_consumed_kcal': consumedKcal > 0 ? consumedKcal : null,
        'today_remaining_kcal': remainingKcal,
        'today_macros': daySummary?.macros.isNotEmpty == true
            ? _roundMacros(daySummary!.macros)
            : null,
        'last_meal_macros': summary?.macros.isNotEmpty == true
            ? _roundMacros(summary!.macros)
            : null,
        if (lastMealInfo.isNotEmpty) ...lastMealInfo,
        'recent_advice': recentAdvice.isEmpty ? null : recentAdvice,
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
        convenience:
            (response['convenience'] as String?) ?? t.nextConvenienceHint,
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

  Future<void> updateDayOverride(DateTime date,
      {String? summary, String? tomorrowAdvice}) async {
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

  Future<void> updateWeekOverride(DateTime weekStart,
      {String? weekSummary, String? nextWeekAdvice}) async {
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

  Future<void> updateMealAdvice(String mealId, MealAdvice advice,
      {bool reanalyzeEntries = true}) async {
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
        _scheduleAnalyze(entry, locale,
            force: true, reason: 'meal_advice_changed');
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
    if (normalized != normalizedDefault) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
      return true;
    }
    if (profile.apiBaseUrl != kDefaultApiBaseUrl) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
      return true;
    }
    return false;
  }

  Future<void> updateApiBaseUrl(String url) async {
    final normalized = _normalizeApiBaseUrl(url);
    if (normalized.isEmpty) return;
    profile.apiBaseUrl = normalized;
    _api = ApiService(baseUrl: normalized);
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveProfile();
    await _saveOverrides();
  }

  void _clearApiBaseUrlBackups() {
    _meta.removeWhere((key, _) => key.startsWith('api_base_url'));
  }

  Future<void> resetApiBaseUrlToDefault() async {
    profile.apiBaseUrl = kDefaultApiBaseUrl;
    _api = ApiService(baseUrl: kDefaultApiBaseUrl);
    _clearApiBaseUrlBackups();
    _touchSettingsUpdatedAt();
    notifyListeners();
    await _saveProfile();
    await _saveOverrides();
  }

  Future<void> refreshApiBaseUrlFromRemote() async {
    if (_migrateApiBaseUrlIfNeeded()) {
      _touchSettingsUpdatedAt();
      // ignore: discarded_futures
      _saveProfile();
      // ignore: discarded_futures
      _saveOverrides();
    }
    if (profile.apiBaseUrl != kDefaultApiBaseUrl) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
      _touchSettingsUpdatedAt();
      // ignore: discarded_futures
      _saveProfile();
      // ignore: discarded_futures
      _saveOverrides();
    }
    final normalized = _normalizeApiBaseUrl(profile.apiBaseUrl);
    _api = ApiService(baseUrl: normalized);
    notifyListeners();
  }

  MealType resolveMealType(DateTime time) {
    final current = TimeOfDay.fromDateTime(time);
    if (_inRange(profile.breakfastStart, profile.breakfastEnd, current))
      return MealType.breakfast;
    if (_inRange(profile.brunchStart, profile.brunchEnd, current))
      return MealType.brunch;
    if (_inRange(profile.lunchStart, profile.lunchEnd, current))
      return MealType.lunch;
    if (_inRange(profile.afternoonTeaStart, profile.afternoonTeaEnd, current))
      return MealType.afternoonTea;
    if (_inRange(profile.dinnerStart, profile.dinnerEnd, current))
      return MealType.dinner;
    if (_inRange(profile.lateSnackStart, profile.lateSnackEnd, current))
      return MealType.lateSnack;
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
      final range =
          _parseCalorieRange(entry.overrideCalorieRange ?? result.calorieRange);
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
    final calorieRange = minSum > 0 && maxSum > 0
        ? '${minSum.round()}-${maxSum.round()} kcal'
        : t.calorieUnknown;
    final advice = dishSummary.isNotEmpty
        ? dishSummary
        : _buildMealAdvice(macros, calorieRange, t);
    return MealSummary(
        calorieRange: calorieRange, macros: macros, advice: advice);
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
      final range =
          _parseCalorieRange(entry.overrideCalorieRange ?? result.calorieRange);
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
    final calorieRange = minSum > 0 && maxSum > 0
        ? '${minSum.round()}-${maxSum.round()} kcal'
        : t.calorieUnknown;
    final advice = _buildMealAdvice(macros, calorieRange, t);
    return MealSummary(
        calorieRange: calorieRange, macros: macros, advice: advice);
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
      return addEntry(files.first, locale,
          note: note, fixedType: fixedType, overrideTime: overrideTime);
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
      final mealId = fixedType != null
          ? _assignMealId(time, fixedType)
          : _assignMealId(time, mealType);
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

  Future<void> updateEntryNote(
      MealEntry entry, String note, String locale) async {
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

  Future<void> addLabelToEntry(
      MealEntry entry, XFile file, String locale) async {
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
        entry.result = _resolveNutritionResult(entry.result!,
            custom: custom, label: labelResult);
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
    _chatMessages.clear();
    _chatSummary = '';
    _chatError = null;
    _meta.remove(_kChatHistoryKey);
    _meta.remove(_kChatSummaryKey);
    notifyListeners();
    await _store.clearAll();
    await _saveOverrides();
  }

  Future<void> _clearLocalDataForAccountSwitch() async {
    final apiBaseUrl = kDefaultApiBaseUrl;
    final language = profile.language;
    final plateAsset = profile.plateAsset;
    final themeAsset = profile.themeAsset;
    final textScale = profile.textScale;
    final nutritionChartStyle = profile.nutritionChartStyle;
    final nutritionValueMode = profile.nutritionValueMode;
    final glowEnabled = profile.glowEnabled;

    entries.clear();
    customFoods.clear();
    _deletedEntries.clear();
    _deletedCustomFoods.clear();
    _failedMealSyncIds.clear();
    _failedMealDeleteSyncIds.clear();
    _failedCustomFoodSyncIds.clear();
    _failedCustomFoodDeleteSyncIds.clear();
    _dayOverrides.clear();
    _mealOverrides.clear();
    _weekOverrides.clear();
    _lastSyncReport = null;
    _lastSyncError = null;
    _syncing = false;
    _meta.clear();
    _chatMessages.clear();
    _chatSummary = '';
    _chatError = null;

    _mockSubscriptionActive = false;
    _mockSubscriptionPlanId = null;
    _iapSubscriptionActive = false;
    _accessPlan = 'unknown';
    _backendEntitlements.clear();

    final reset = UserProfile.initial()
      ..apiBaseUrl = apiBaseUrl
      ..language = language
      ..plateAsset = plateAsset
      ..themeAsset = themeAsset
      ..textScale = textScale
      ..nutritionChartStyle = nutritionChartStyle
      ..nutritionValueMode = nutritionValueMode
      ..glowEnabled = glowEnabled;
    profile
      ..name = reset.name
      ..email = reset.email
      ..gender = reset.gender
      ..containerType = reset.containerType
      ..containerSize = reset.containerSize
      ..containerDepth = reset.containerDepth
      ..containerDiameterCm = reset.containerDiameterCm
      ..containerCapacityMl = reset.containerCapacityMl
      ..dietType = reset.dietType
      ..dietNote = reset.dietNote
      ..tone = reset.tone
      ..persona = reset.persona
      ..activityLevel = reset.activityLevel
      ..heightCm = reset.heightCm
      ..weightKg = reset.weightKg
      ..age = reset.age
      ..goal = reset.goal
      ..planSpeed = reset.planSpeed
      ..dailySummaryTime = reset.dailySummaryTime
      ..weeklySummaryWeekday = reset.weeklySummaryWeekday
      ..breakfastReminderEnabled = reset.breakfastReminderEnabled
      ..lunchReminderEnabled = reset.lunchReminderEnabled
      ..dinnerReminderEnabled = reset.dinnerReminderEnabled
      ..breakfastStart = reset.breakfastStart
      ..breakfastEnd = reset.breakfastEnd
      ..brunchStart = reset.brunchStart
      ..brunchEnd = reset.brunchEnd
      ..lunchStart = reset.lunchStart
      ..lunchEnd = reset.lunchEnd
      ..afternoonTeaStart = reset.afternoonTeaStart
      ..afternoonTeaEnd = reset.afternoonTeaEnd
      ..dinnerStart = reset.dinnerStart
      ..dinnerEnd = reset.dinnerEnd
      ..lateSnackStart = reset.lateSnackStart
      ..lateSnackEnd = reset.lateSnackEnd
      ..language = reset.language
      ..apiBaseUrl = reset.apiBaseUrl
      ..plateAsset = reset.plateAsset
      ..themeAsset = reset.themeAsset
      ..textScale = reset.textScale
      ..nutritionChartStyle = reset.nutritionChartStyle
      ..nutritionValueMode = reset.nutritionValueMode
      ..glowEnabled = reset.glowEnabled
      ..exerciseSuggestionType = reset.exerciseSuggestionType;

    await _store.clearAll();
    await _saveProfile();
    await _saveOverrides();
    notifyListeners();
  }

  Future<void> updateEntryFoodName(
      MealEntry entry, String foodName, String locale) async {
    entry.overrideFoodName = foodName.trim().isEmpty ? null : foodName.trim();
    entry.updatedAt = DateTime.now().toUtc();
    markMealInteraction(entry.mealId ?? entry.id);
    final custom = _findCustomFoodByName(entry.overrideFoodName);
    if (entry.result != null) {
      entry.result = _resolveNutritionResult(entry.result!,
          custom: custom, label: entry.labelResult);
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
      ..chatAssistantName = updated.chatAssistantName
      ..chatAvatarBase64 = updated.chatAvatarBase64
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
      ..breakfastReminderEnabled = updated.breakfastReminderEnabled
      ..lunchReminderEnabled = updated.lunchReminderEnabled
      ..dinnerReminderEnabled = updated.dinnerReminderEnabled
      ..language = updated.language
      ..apiBaseUrl = kDefaultApiBaseUrl
      ..plateAsset = updated.plateAsset
      ..themeAsset = updated.themeAsset
      ..textScale = updated.textScale
      ..nutritionChartStyle = updated.nutritionChartStyle
      ..glowEnabled = updated.glowEnabled;
    _normalizeProfileGoalAndPlan();
    _refreshChatAvatarBytes();
    notifyListeners();
    _touchSettingsUpdatedAt();
    // ignore: unawaited_futures
    _saveProfile();
    // ignore: unawaited_futures
    _saveOverrides();
  }

  void updateField(void Function(UserProfile profile) updater) {
    updater(profile);
    _normalizeProfileGoalAndPlan();
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
    if (!canUseFeature(AppFeature.analyze)) {
      return;
    }
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
      final photoContext = _mealPhotoContext(entry, locale);
      final AnalysisResult res = await _api.analyzeImage(
        entry.imageBytes,
        entry.filename,
        accessToken: _accessToken(),
        lang: locale,
        foodName: entry.overrideFoodName,
        note: entry.note,
        context: photoContext,
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
      entry.result = _resolveNutritionResult(res,
          custom: custom, label: entry.labelResult);
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
      if (force &&
          entry.error == null &&
          refreshMealAdviceReasons.contains(reason)) {
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

  Future<void> _refreshMealAdviceForEntry(
      MealEntry entry, String locale) async {
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
    final t = lookupAppLocalizations(
        Locale.fromSubtags(languageCode: locale.split('-').first));
    final group = entriesForMealId(mealId);
    if (group.isEmpty) return;
    await ensureMealAdviceForGroup(group, t, locale);
  }

  Future<void> _refreshDaySummaryForEntry(
      MealEntry entry, String locale) async {
    final date = _dateOnly(entry.time);
    final t = lookupAppLocalizations(
        Locale.fromSubtags(languageCode: locale.split('-').first));
    await _refreshDaySummaryForDate(date, locale, t: t);
  }

  Future<void> _refreshDaySummaryForDate(DateTime date, String locale,
      {AppLocalizations? t}) async {
    final key = _dayKey(date);
    if (!_isDayLocked(date) && !_dayOverrides.containsKey(key)) {
      return;
    }
    final resolved = t ??
        lookupAppLocalizations(
            Locale.fromSubtags(languageCode: locale.split('-').first));
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
    final match =
        RegExp(r'(20\\d{2})[-_]?([01]\\d)[-_]?([0-3]\\d)').firstMatch(filename);
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
    final maxDim =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final scale = maxDim > 1024 ? 1024 / maxDim : 1.0;
    final targetWidth = (decoded.width * scale).round();
    final targetHeight = (decoded.height * scale).round();
    final resized = scale < 1.0
        ? img.copyResize(decoded, width: targetWidth, height: targetHeight)
        : decoded;
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

  bool isNamePlaceholderImage(List<int> bytes) {
    if (bytes.length != _namePlaceholderBytes.length) {
      return false;
    }
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != _namePlaceholderBytes[i]) {
        return false;
      }
    }
    return true;
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

  Map<String, double> _macroPercentMapFromGrams(
      Map<String, double> grams, String? calorieRange,
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
          aiOriginalMacros: result.aiOriginalMacros == null
              ? null
              : _percentMacrosToGrams(result.aiOriginalMacros!),
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

  double _aggregateMacroScore(
      List<MealEntry> dayEntries, String key, AppLocalizations t) {
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
    if (labelResult.labelName != null &&
        labelResult.labelName!.trim().isNotEmpty) {
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

  _PieceFoodEstimate? _estimatePieceFood(AnalysisResult result) {
    final joined = <String>[
      result.foodName,
      if ((result.dishSummary ?? '').trim().isNotEmpty) result.dishSummary!,
      ...result.foodItems,
    ].join(' ');
    final normalized = joined.toLowerCase();

    _PieceFoodProfile? matchedProfile;
    for (final profile in _kPieceFoodProfiles) {
      final hit = profile.tokens.any((token) {
        final trimmed = token.trim();
        if (trimmed.isEmpty) return false;
        final lowerToken = trimmed.toLowerCase();
        return joined.contains(trimmed) || normalized.contains(lowerToken);
      });
      if (hit) {
        matchedProfile = profile;
        break;
      }
    }
    if (matchedProfile == null) return null;

    int? explicitCount;
    for (final match in _kPieceCountNumericPattern.allMatches(joined)) {
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        explicitCount = parsed;
        break;
      }
    }
    if (explicitCount == null) {
      for (final match in _kPieceCountChinesePattern.allMatches(joined)) {
        final parsed = _parseChineseCountToken(match.group(1) ?? '');
        if (parsed != null && parsed > 0) {
          explicitCount = parsed;
          break;
        }
      }
    }

    if (explicitCount != null) {
      return _PieceFoodEstimate(
        profile: matchedProfile,
        count: explicitCount.clamp(1, 60),
        usedDefaultCount: false,
      );
    }

    int basketCount = 0;
    for (final match in _kBasketNumericPattern.allMatches(joined)) {
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > 0) {
        basketCount = parsed;
        break;
      }
    }
    if (basketCount <= 0) {
      for (final match in _kBasketChinesePattern.allMatches(joined)) {
        final parsed = _parseChineseCountToken(match.group(1) ?? '');
        if (parsed != null && parsed > 0) {
          basketCount = parsed;
          break;
        }
      }
    }
    if (basketCount > 0) {
      return _PieceFoodEstimate(
        profile: matchedProfile,
        count: (basketCount * matchedProfile.defaultPieceCount).clamp(1, 60),
        usedDefaultCount: false,
      );
    }

    return _PieceFoodEstimate(
      profile: matchedProfile,
      count: matchedProfile.defaultPieceCount.clamp(1, 60),
      usedDefaultCount: true,
    );
  }

  int? _parseChineseCountToken(String raw) {
    final token = raw.trim();
    if (token.isEmpty) return null;
    final direct = _kChineseCountDigits[token];
    if (direct != null) return direct;

    if (token == '十') return 10;
    if (token.length == 2 && token.startsWith('十')) {
      final ones = _kChineseCountDigits[token.substring(1)];
      if (ones != null) return 10 + ones;
    }
    if (token.length == 2 && token.endsWith('十')) {
      final tens = _kChineseCountDigits[token.substring(0, 1)];
      if (tens != null) return tens * 10;
    }
    if (token.length == 3 && token.substring(1, 2) == '十') {
      final tens = _kChineseCountDigits[token.substring(0, 1)];
      final ones = _kChineseCountDigits[token.substring(2)];
      if (tens != null && ones != null) return (tens * 10) + ones;
    }
    return null;
  }

  double _macroKcalEstimate(Map<String, double> macros) {
    final protein = (macros['protein'] ?? 0).clamp(0, double.infinity);
    final carbs = (macros['carbs'] ?? 0).clamp(0, double.infinity);
    final fat = (macros['fat'] ?? 0).clamp(0, double.infinity);
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }

  double _round1(double value) {
    return (value * 10).round() / 10.0;
  }

  AnalysisResult _applyPieceFoodGuard(AnalysisResult result) {
    final source = result.source.trim().toLowerCase();
    final nutritionSource = (result.nutritionSource ?? '').trim().toLowerCase();
    final isAiLike = source == 'ai' ||
        source == 'mock' ||
        source == 'cache' ||
        nutritionSource.isEmpty ||
        nutritionSource == 'ai';
    if (!isAiLike) return result;

    final estimate = _estimatePieceFood(result);
    if (estimate == null) return result;

    final joined = <String>[
      result.foodName,
      if ((result.dishSummary ?? '').trim().isNotEmpty) result.dishSummary!,
      ...result.foodItems,
      result.suggestion,
    ].join(' ');
    final lower = joined.toLowerCase();
    var modifier = 1.0;
    if (estimate.profile.key != 'fried_dumpling' &&
        (joined.contains('煎') ||
            joined.contains('炸') ||
            lower.contains('fried') ||
            lower.contains('pan-fried'))) {
      modifier += 0.18;
    }
    if (joined.contains('醬') ||
        joined.contains('辣油') ||
        lower.contains('sauce')) {
      modifier += 0.08;
    }

    final targetMid =
        estimate.profile.kcalPerPiece * estimate.count.clamp(1, 60) * modifier;
    if (targetMid <= 0) return result;
    final currentMid = calorieRangeMid(result.calorieRange) ??
        _macroKcalEstimate(result.macros);
    final highLimit = targetMid * 1.75;
    final lowLimit = targetMid * 0.32;
    final needsCorrection =
        currentMid <= 0 || currentMid > highLimit || currentMid < lowLimit;
    if (!needsCorrection) return result;

    final low = max(20, (targetMid * 0.85).round());
    final high = max(low + 20, (targetMid * 1.15).round());
    final factor = estimate.count * modifier;
    final guardedMacros = <String, double>{
      'protein': _round1(estimate.profile.proteinPerPiece * factor),
      'carbs': _round1(estimate.profile.carbsPerPiece * factor),
      'fat': _round1(estimate.profile.fatPerPiece * factor),
      'sodium': _round1(estimate.profile.sodiumPerPiece * factor),
    };

    final aiOriginalCalories =
        result.aiOriginalCalorieRange ?? result.calorieRange;
    final aiOriginalMacros = result.aiOriginalMacros == null
        ? Map<String, double>.from(result.macros)
        : Map<String, double>.from(result.aiOriginalMacros!);
    final guardNote = estimate.usedDefaultCount
        ? 'unit_guard:${estimate.profile.key}:default'
        : 'unit_guard:${estimate.profile.key}:${estimate.count}pcs';
    final existingReference = (result.referenceUsed ?? '').trim();
    final referenceUsed = existingReference.isEmpty
        ? guardNote
        : '$existingReference | $guardNote';

    return AnalysisResult(
      foodName: result.foodName,
      calorieRange: '$low-$high kcal',
      macros: guardedMacros,
      foodItems: result.foodItems,
      judgementTags: result.judgementTags,
      dishSummary: result.dishSummary,
      suggestion: result.suggestion,
      tier: result.tier,
      source: result.source,
      nutritionSource: result.nutritionSource ?? 'ai',
      aiOriginalCalorieRange: aiOriginalCalories,
      aiOriginalMacros: aiOriginalMacros,
      costEstimateUsd: result.costEstimateUsd,
      confidence: result.confidence,
      isBeverage: result.isBeverage,
      isFood: result.isFood,
      nonFoodReason: result.nonFoodReason,
      referenceUsed: referenceUsed,
      containerGuessType: result.containerGuessType,
      containerGuessSize: result.containerGuessSize,
      catalogImageUrl: result.catalogImageUrl,
      catalogThumbUrl: result.catalogThumbUrl,
      catalogImageSource: result.catalogImageSource,
      catalogImageLicense: result.catalogImageLicense,
    );
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
        dishSummary: custom.summary.trim().isNotEmpty
            ? custom.summary
            : base.dishSummary,
        suggestion: custom.suggestion.trim().isNotEmpty
            ? custom.suggestion
            : base.suggestion,
        tier: base.tier,
        source: base.source,
        nutritionSource: 'custom',
        aiOriginalCalorieRange: originalCalories,
        aiOriginalMacros: Map<String, double>.from(originalMacros),
        costEstimateUsd: base.costEstimateUsd,
        confidence: base.confidence,
        isBeverage: isBeverage,
        isFood: base.isFood,
        nonFoodReason: base.nonFoodReason,
        referenceUsed: base.referenceUsed,
        containerGuessType: base.containerGuessType,
        containerGuessSize: base.containerGuessSize,
        catalogImageUrl: base.catalogImageUrl,
        catalogThumbUrl: base.catalogThumbUrl,
        catalogImageSource: base.catalogImageSource,
        catalogImageLicense: base.catalogImageLicense,
      );
    }
    if (label != null) {
      final calorieRange = label.calorieRange.trim().isNotEmpty
          ? label.calorieRange
          : base.calorieRange;
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
        isFood: base.isFood,
        nonFoodReason: base.nonFoodReason,
        referenceUsed: base.referenceUsed,
        containerGuessType: base.containerGuessType,
        containerGuessSize: base.containerGuessSize,
        catalogImageUrl: base.catalogImageUrl,
        catalogThumbUrl: base.catalogThumbUrl,
        catalogImageSource: base.catalogImageSource,
        catalogImageLicense: base.catalogImageLicense,
      );
    }
    final adjusted = _applyPieceFoodGuard(base);
    final resolvedSource = adjusted.nutritionSource ??
        (adjusted.source == 'label'
            ? 'label'
            : adjusted.source == 'custom'
                ? 'custom'
                : 'ai');
    return AnalysisResult(
      foodName: adjusted.foodName,
      calorieRange: adjusted.calorieRange,
      macros: adjusted.macros,
      foodItems: adjusted.foodItems,
      judgementTags: adjusted.judgementTags,
      dishSummary: adjusted.dishSummary,
      suggestion: adjusted.suggestion,
      tier: adjusted.tier,
      source: adjusted.source,
      nutritionSource: resolvedSource,
      aiOriginalCalorieRange: adjusted.aiOriginalCalorieRange,
      aiOriginalMacros: adjusted.aiOriginalMacros == null
          ? null
          : Map<String, double>.from(adjusted.aiOriginalMacros!),
      costEstimateUsd: adjusted.costEstimateUsd,
      confidence: adjusted.confidence,
      isBeverage: isBeverage,
      isFood: adjusted.isFood,
      nonFoodReason: adjusted.nonFoodReason,
      referenceUsed: adjusted.referenceUsed,
      containerGuessType: adjusted.containerGuessType,
      containerGuessSize: adjusted.containerGuessSize,
      catalogImageUrl: adjusted.catalogImageUrl,
      catalogThumbUrl: adjusted.catalogThumbUrl,
      catalogImageSource: adjusted.catalogImageSource,
      catalogImageLicense: adjusted.catalogImageLicense,
    );
  }

  MealEntry? _findMealAnchor(MealEntry entry) {
    if ((entry.note ?? '').trim().isNotEmpty) return null;
    if ((entry.overrideFoodName ?? '').trim().isNotEmpty) return null;
    for (final existing in entries) {
      if (existing.id == entry.id) continue;
      if (existing.imageHash == null || existing.imageHash != entry.imageHash)
        continue;
      if (existing.result == null) continue;
      if ((existing.overrideFoodName ?? '').trim().isNotEmpty) continue;
      if ((existing.note ?? '').trim().isNotEmpty) continue;
      return existing;
    }
    return null;
  }

  DateTime? _parseExifDate(String value) {
    final match = RegExp(r'(\d{4}):(\d{2}):(\d{2})\s+(\d{2}):(\d{2}):(\d{2})')
        .firstMatch(value);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    final second = int.tryParse(match.group(6)!);
    if ([year, month, day, hour, minute, second].any((v) => v == null))
      return null;
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
    final rangeMatch =
        RegExp(r'(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)').firstMatch(value);
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
    return portion *
        _containerSizeFactorFor(size) *
        _containerTypeFactorFor(type);
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

  String? _mealPhotoContext(MealEntry entry, String locale) {
    final mealId = entry.mealId ?? entry.id;
    final group = entriesForMealId(mealId);
    if (group.length <= 1) return null;
    final count = group.length;
    final isZh = locale.toLowerCase().startsWith('zh');
    if (isZh) {
      return '這餐共有 $count 張照片，請視為同一餐並保持建議一致。';
    }
    return 'This meal has $count photos. Treat them as one meal and keep advice consistent.';
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

  String _buildMealAdvice(
      Map<String, double> macros, String calorieRange, AppLocalizations t) {
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
    final line =
        advice.isEmpty ? t.dietitianBalanced : advice.take(2).join('、');
    final loseFat = normalizeGoalValue(profile.goal) == kGoalValueLoseFat;
    final goalHint = loseFat ? t.goalAdviceLoseFat : t.goalAdviceMaintain;
    return '${t.dietitianPrefix}$line ${goalHint}';
  }

  bool _isSmallPortion(MealEntry entry) {
    return entry.portionPercent <= _kSmallPortionThreshold;
  }

  bool _shouldShowSmallPortionNoteForGroup(List<MealEntry> group,
      {double ratio = 0.5}) {
    if (group.isEmpty) return false;
    int total = 0;
    int small = 0;
    for (final entry in group) {
      total += 1;
      if (_isSmallPortion(entry)) {
        small += 1;
      }
    }
    if (total == 0) return false;
    return (small / total) >= ratio;
  }

  String _appendSmallPortionSuffix(
      String text, List<MealEntry> group, AppLocalizations t) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!_shouldShowSmallPortionNoteForGroup(group)) return trimmed;
    if (trimmed.contains(t.smallPortionNote)) return trimmed;
    if (t.localeName.startsWith('en')) {
      return '$trimmed (${t.smallPortionNote})';
    }
    return '$trimmed（${t.smallPortionNote}）';
  }

  List<String> _appendSmallPortionSuffixToList(
    List<String> items,
    List<MealEntry> group,
    AppLocalizations t,
  ) {
    if (items.isEmpty) return items;
    if (!_shouldShowSmallPortionNoteForGroup(group)) return items;
    final updated = List<String>.from(items);
    final lastIndex = updated.length - 1;
    if (updated[lastIndex].contains(t.smallPortionNote)) return updated;
    if (t.localeName.startsWith('en')) {
      updated[lastIndex] = '${updated[lastIndex]} (${t.smallPortionNote})';
    } else {
      updated[lastIndex] = '${updated[lastIndex]}（${t.smallPortionNote}）';
    }
    return updated;
  }

  bool _isBeverageGroup(List<MealEntry> group) {
    bool hasResult = false;
    for (final entry in group) {
      final result = entry.result;
      if (result == null) return false;
      hasResult = true;
      if (result.isBeverage != true) return false;
    }
    return hasResult;
  }

  bool isBeverageGroup(List<MealEntry> group) => _isBeverageGroup(group);

  List<List<MealEntry>> _nonBeverageGroups(Iterable<List<MealEntry>> groups) {
    return groups.where((group) => !_isBeverageGroup(group)).toList();
  }

  String? _entryDishSummary(MealEntry entry, AppLocalizations t) {
    final summaryText = entry.result?.dishSummary?.trim();
    if (summaryText != null && summaryText.isNotEmpty) {
      return summaryText;
    }
    final fallback = entry.overrideFoodName ?? entry.result?.foodName ?? '';
    if (fallback.trim().isEmpty) return null;
    return fallback.trim();
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
    final collapsed = _collapseDishSummaries(summaries, t);
    if (collapsed.isEmpty) return '';
    if (collapsed.length == 1) {
      return _appendSmallPortionSuffix(collapsed.first, group, t);
    }
    final joiner = t.localeName.startsWith('en') ? ', ' : '、';
    final combined = collapsed.join(joiner);
    return _appendSmallPortionSuffix(combined, group, t);
  }

  List<String> _collapseDishSummaries(List<String> items, AppLocalizations t,
      {int maxItems = 3}) {
    final cleaned = <String>[];
    final seen = <String>{};
    for (final item in items) {
      final text = item.trim();
      if (text.isEmpty) continue;
      if (seen.add(text)) {
        cleaned.add(text);
      }
    }
    if (cleaned.isEmpty) return [];
    if (cleaned.length <= maxItems) {
      return cleaned;
    }
    final shown = cleaned.take(maxItems).toList();
    final total = cleaned.length;
    final joiner = t.localeName.startsWith('en') ? ', ' : '、';
    final prefix = shown.join(joiner);
    final suffix =
        t.localeName.startsWith('en') ? '... + $total items' : '...等 $total 項';
    return ['$prefix$suffix'];
  }

  String _newId() {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 31);
    return '$seed-$rand';
  }

  void _syncSelectedDateToLatestEntryIfNeeded() {
    if (entries.isEmpty) return;
    final target = _dateOnly(_selectedDate);
    final hasDataOnSelected =
        entries.any((entry) => _isSameDate(entry.time, target));
    if (hasDataOnSelected) return;
    final latest = entries.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
    _selectedDate = _dateOnly(latest.time);
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
    final deletedCustom =
        overrides['deleted_custom_foods'] as Map<String, dynamic>?;
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
    _mockSubscriptionActive = _meta[_kMockSubscriptionKey] == 'true';
    _mockSubscriptionPlanId = _meta[_kMockSubscriptionPlanKey];
    _iapSubscriptionActive = _meta[_kIapSubscriptionKey] == 'true';
    final rawPlan = (_meta[_kAccessPlanKey] ?? '').trim();
    _accessPlan = rawPlan.isEmpty ? 'unknown' : rawPlan;
    _backendEntitlements.clear();
    final rawEntitlements = _meta[_kAccessEntitlementsKey];
    if (rawEntitlements != null && rawEntitlements.trim().isNotEmpty) {
      for (final part in rawEntitlements.split(',')) {
        final value = part.trim();
        if (value.isNotEmpty) {
          _backendEntitlements.add(value);
        }
      }
    }
    _loadChatFromMeta();
  }

  void _loadChatFromMeta() {
    _chatMessages.clear();
    final raw = _meta[_kChatHistoryKey];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              _chatMessages.add(ChatMessage.fromJson(item));
            } else if (item is Map) {
              _chatMessages.add(ChatMessage.fromJson(
                  item.map((k, v) => MapEntry(k.toString(), v))));
            }
          }
        }
      } catch (_) {}
    }
    _chatSummary = _meta[_kChatSummaryKey] ?? '';
  }

  void _refreshChatAvatarBytes() {
    final raw = profile.chatAvatarBase64;
    if (raw.isEmpty) {
      _chatAvatarBytes = null;
      return;
    }
    try {
      _chatAvatarBytes = base64Decode(raw);
    } catch (_) {
      _chatAvatarBytes = null;
    }
  }

  Uint8List _normalizeChatAvatar(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final size = min(decoded.width, decoded.height);
      final cropped = img.copyCrop(
        decoded,
        x: ((decoded.width - size) / 2).round(),
        y: ((decoded.height - size) / 2).round(),
        width: size,
        height: size,
      );
      final resized = img.copyResize(cropped, width: 128, height: 128);
      return Uint8List.fromList(img.encodePng(resized));
    } catch (_) {
      return bytes;
    }
  }

  Future<void> updateChatAvatar(Uint8List? bytes) async {
    Uint8List? normalized;
    String encoded = '';
    if (bytes != null && bytes.isNotEmpty) {
      normalized = _normalizeChatAvatar(bytes);
      encoded = base64Encode(normalized);
    }
    _chatAvatarBytes = normalized;
    updateField((p) => p.chatAvatarBase64 = encoded);
  }

  Future<void> _persistChat() async {
    _meta[_kChatHistoryKey] =
        json.encode(_chatMessages.map((msg) => msg.toJson()).toList());
    _meta[_kChatSummaryKey] = _chatSummary;
    await _saveOverrides();
  }

  void _trimChatHistory({int maxMessages = 60, int keepRecent = 20}) {
    if (_chatMessages.length <= maxMessages) return;
    if (keepRecent <= 0) {
      _chatMessages.clear();
      return;
    }
    final start = max(0, _chatMessages.length - keepRecent);
    final recent = _chatMessages.sublist(start);
    _chatMessages
      ..clear()
      ..addAll(recent);
  }

  List<Map<String, dynamic>> _chatMessagesForApi({int maxItems = 16}) {
    if (_chatMessages.isEmpty) return const [];
    final start = max(0, _chatMessages.length - maxItems);
    final slice = _chatMessages.sublist(start);
    return slice
        .map((msg) => {
              'role': msg.role,
              'content': msg.content,
            })
        .toList();
  }

  Map<String, dynamic> _chatProfileSnapshot(DateTime date) {
    return {
      'height_cm': profile.heightCm,
      'weight_kg': profile.weightKg,
      'age': profile.age,
      'gender': profile.gender,
      'chat_avatar': profile.chatAvatarBase64,
      'tone': profile.tone,
      'persona': profile.persona,
      'activity_level': dailyActivityLevel(date),
      'target_calorie_range': targetCalorieRangeValue(date),
      'goal': profile.goal,
      'plan_speed': profile.planSpeed,
    };
  }

  List<Map<String, dynamic>> _recentDaysForChat(AppLocalizations t) {
    final today = _dateOnly(DateTime.now());
    final days = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final entriesForDay = entriesForDate(date);
      final groups = mealGroupsForDateAll(date);
      final summary = buildDaySummary(date, t);
      final consumed =
          entriesForDay.isEmpty ? null : dailyConsumedCalorieMid(date).round();
      final targetMid = targetCalorieMid(date);
      final remaining = consumed == null || targetMid == null
          ? null
          : (targetMid - consumed).round();
      days.add({
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'has_data': entriesForDay.isNotEmpty,
        'meal_count': groups.length,
        'meal_labels': entriesForDay.isNotEmpty ? dayMealLabels(date, t) : '',
        'calorie_range': summary?.calorieRange ?? t.calorieUnknown,
        'summary': daySummaryText(date, t),
        'consumed_kcal': consumed,
        'remaining_kcal': remaining,
        'target_range': targetCalorieRangeValue(date),
        'macros': summary?.macros.isNotEmpty == true
            ? _roundMacros(summary!.macros)
            : null,
      });
    }
    return days;
  }

  List<Map<String, dynamic>> _todayMealsForChat(AppLocalizations t) {
    final today = _dateOnly(DateTime.now());
    final groups = mealGroupsForDateAll(today);
    if (groups.isEmpty) return const [];
    final meals = <Map<String, dynamic>>[];
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
      final collapsedSummaries = _appendSmallPortionSuffixToList(
        _collapseDishSummaries(dishSummaries, t),
        group,
        t,
      );
      final items = <Map<String, dynamic>>[];
      for (final entry in group) {
        final result = entry.result;
        final foodName =
            (entry.overrideFoodName ?? result?.foodName ?? '').trim();
        final calorieRange =
            (entry.overrideCalorieRange ?? result?.calorieRange ?? '').trim();
        final macros = result?.macros.isNotEmpty == true
            ? _roundMacros(result!.macros)
            : null;
        items.add({
          'time': entry.time.toIso8601String(),
          'food_name': foodName,
          'food_items': result?.foodItems ?? const [],
          'calorie_range': calorieRange,
          'portion_percent': entry.portionPercent,
          'note': (entry.note ?? '').trim(),
          'dish_summary': (result?.dishSummary ?? '').trim(),
          'macros': macros,
          'is_beverage': result?.isBeverage,
          'is_food': result?.isFood,
          'non_food_reason': result?.nonFoodReason,
          'reference_used': result?.referenceUsed,
        });
      }
      meals.add({
        'meal_type': _mealTypeKey(group.first.type),
        'meal_label': _mealTypeLabel(group.first.type, t),
        'time': group.first.time.toIso8601String(),
        'calorie_range': summary?.calorieRange ?? '',
        'macros': summary?.macros.isNotEmpty == true
            ? _roundMacros(summary!.macros)
            : null,
        'dish_summaries': collapsedSummaries,
        'items': items,
      });
    }
    return meals;
  }

  String? _lastMealTimeForChat(DateTime now) {
    final groups = _nonBeverageGroups(mealGroupsForDateAll(_dateOnly(now)));
    if (groups.isEmpty) return null;
    final latest = groups.first;
    if (latest.isEmpty) return null;
    final lastEntry = latest.first;
    return lastEntry.time.toIso8601String();
  }

  double? _fastingHoursForChat(DateTime now) {
    final lastMealRaw = _lastMealTimeForChat(now);
    if (lastMealRaw == null || lastMealRaw.isEmpty) return null;
    final lastMeal = DateTime.tryParse(lastMealRaw);
    if (lastMeal == null) return null;
    final diff = now.difference(lastMeal).inMinutes / 60.0;
    return diff < 0 ? 0 : double.parse(diff.toStringAsFixed(1));
  }

  Future<void> sendChatMessage(
      String message, String locale, AppLocalizations t) async {
    if (!canUseFeature(AppFeature.chat)) return;
    final text = message.trim();
    if (text.isEmpty) return;
    if (_chatSending) return;
    _chatSending = true;
    _chatError = null;
    final userMsg = ChatMessage.user(text);
    _chatMessages.add(userMsg);
    notifyListeners();
    await _persistChat();
    final today = _dateOnly(DateTime.now());
    final now = DateTime.now();
    final payload = {
      'lang': locale,
      'profile': _chatProfileSnapshot(today),
      'days': _recentDaysForChat(t),
      'today_meals': _todayMealsForChat(t),
      'context': {
        'now': now.toIso8601String(),
        'last_meal_time': _lastMealTimeForChat(now),
        'fasting_hours': _fastingHoursForChat(now),
      },
      if (_chatSummary.trim().isNotEmpty) 'summary': _chatSummary.trim(),
      'messages': _chatMessagesForApi(),
    };
    try {
      final response = await _api.chat(payload, _accessToken());
      final reply = (response['reply'] as String?)?.trim() ?? '';
      final summary = (response['summary'] as String?)?.trim() ?? '';
      if (reply.isNotEmpty) {
        _chatMessages.add(ChatMessage.assistant(reply));
      }
      if (summary.isNotEmpty) {
        _chatSummary = summary;
      }
      _trimChatHistory();
      await _persistChat();
    } catch (e) {
      String reasonText;
      if (e is ChatApiException) {
        if (e.statusCode == 401 || e.statusCode == 402) {
          reasonText = t.chatErrorReasonAuth;
        } else if (e.statusCode == 429) {
          reasonText = t.chatErrorReasonQuota;
        } else if (e.statusCode >= 500) {
          reasonText = t.chatErrorReasonServer;
        } else {
          reasonText = t.chatErrorReasonUnknown;
        }
      } else {
        reasonText = t.chatErrorReasonNetwork;
      }
      final reply =
          '${t.chatErrorReplyBase}（${t.chatErrorReasonPrefix}$reasonText）';
      _chatMessages.add(ChatMessage.assistant(reply));
      _trimChatHistory();
      await _persistChat();
      _chatError = null;
    } finally {
      _chatSending = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    _chatMessages.clear();
    _chatSummary = '';
    _chatError = null;
    await _persistChat();
    notifyListeners();
  }

  Future<MealAdvice> suggestNowMealAdvice(
      AppLocalizations t, String locale) async {
    if (!canUseFeature(AppFeature.suggest)) {
      throw Exception('subscription_required');
    }
    final now = DateTime.now();
    final mealType = resolveMealType(now);
    final mealDate = _dateOnly(now);
    final dayGroups = mealGroupsForDateAll(mealDate);
    final mealGroups = _nonBeverageGroups(dayGroups);
    final daySummary = buildDaySummary(mealDate, t);
    final consumedKcal = dailyConsumedCalorieMid(mealDate).round();
    final targetMid = targetCalorieMid(mealDate);
    final remainingKcal =
        targetMid == null ? null : (targetMid - consumedKcal).round();
    final lastMealInfo = _lastMealInfo(now);
    Map<String, double>? lastMealMacros;
    if (mealGroups.isNotEmpty) {
      final lastGroup = mealGroups.first;
      final lastSummary = buildMealSummary(lastGroup, t);
      lastMealMacros = lastSummary?.macros;
    }
    final recentAdvice = _collectRecentMealAdvice(mealDate, t);
    final dishSummaries = <String>[];
    for (final dayGroup in mealGroups) {
      for (final entry in dayGroup) {
        final summaryText = _entryDishSummary(entry, t);
        if (summaryText != null && summaryText.isNotEmpty) {
          dishSummaries.add(summaryText);
        }
      }
    }
    final collapsedSummaries = _collapseDishSummaries(dishSummaries, t);
    final dayMealSummaries = <String>[];
    for (final dayGroup in mealGroups) {
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
      final collapsedDaySummaries = _appendSmallPortionSuffixToList(
        _collapseDishSummaries(dayDishSummaries, t),
        dayGroup,
        t,
      );
      final dishText = collapsedDaySummaries.isEmpty
          ? ''
          : collapsedDaySummaries.join(' / ');
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
      'day_meal_count': mealGroups.length,
      'day_meal_summaries': dayMealSummaries,
      'today_consumed_kcal': consumedKcal > 0 ? consumedKcal : null,
      'today_remaining_kcal': remainingKcal,
      'today_macros': daySummary?.macros.isNotEmpty == true
          ? _roundMacros(daySummary!.macros)
          : null,
      'last_meal_macros': lastMealMacros == null || lastMealMacros.isEmpty
          ? null
          : _roundMacros(lastMealMacros),
      if (lastMealInfo.isNotEmpty) ...lastMealInfo,
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
        convenience:
            (response['convenience'] as String?) ?? t.nextConvenienceHint,
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

  Future<void> signUpSupabase(String email, String password,
      {String? nickname}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) return;
    final trimmedNickname = (nickname ?? '').trim();
    await _supabase.client.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: trimmedNickname.isEmpty ? null : {'nickname': trimmedNickname},
      emailRedirectTo: _supabaseRedirectUrl(),
    );
    if (trimmedNickname.isNotEmpty) {
      updateField((p) => p.name = trimmedNickname);
    }
    updateField((p) => p.email = trimmedEmail);
    _applySupabaseNickname(_supabase.currentUser);
    await refreshAccessStatus();
    notifyListeners();
  }

  Future<void> signInSupabase(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) return;
    await _supabase.client.auth
        .signInWithPassword(email: trimmedEmail, password: password);
    updateField((p) => p.email = trimmedEmail);
    _applySupabaseNickname(_supabase.currentUser);
    await refreshAccessStatus();
    await _runAutoSync();
    _syncSelectedDateToLatestEntryIfNeeded();
    notifyListeners();
  }

  Future<void> resendVerificationEmail(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return;
    await _supabase.client.auth.resend(
      type: OtpType.signup,
      email: trimmedEmail,
      emailRedirectTo: _supabaseRedirectUrl(),
    );
  }

  Future<void> signOutSupabase() async {
    await _supabase.client.auth.signOut();
    await refreshAccessStatus();
    notifyListeners();
  }

  Future<void> switchAccount() async {
    await _supabase.client.auth.signOut();
    await _clearLocalDataForAccountSwitch();
    await refreshAccessStatus();
    notifyListeners();
  }

  Future<void> resetSupabasePassword(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return;
    await _supabase.client.auth.resetPasswordForEmail(
      trimmedEmail,
      redirectTo: _supabaseRedirectUrl(),
    );
  }

  String? _supabaseRedirectUrl() {
    return kIsWeb ? kSupabaseEmailRedirectUrlWeb : kSupabaseEmailRedirectUrlApp;
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
            : entries.where((entry) =>
                entry.updatedAt != null && entry.updatedAt!.isAfter(since)))
        .where((entry) => entry.id.isNotEmpty)
        .toList();
    for (final entry in entries) {
      if (_failedMealSyncIds.contains(entry.id) &&
          !entriesToSync.any((e) => e.id == entry.id)) {
        entriesToSync.add(entry);
      }
    }
    final foodsToSync = (since == null
            ? customFoods
            : customFoods.where((food) => food.updatedAt.isAfter(since)))
        .where((food) => food.id.isNotEmpty)
        .toList();
    for (final food in customFoods) {
      if (_failedCustomFoodSyncIds.contains(food.id) &&
          !foodsToSync.any((f) => f.id == food.id)) {
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
      if (id is String &&
          _failedMealDeleteSyncIds.contains(id) &&
          !deletionsToSync.contains(deleted)) {
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
    final settingsToSync = settingsUpdatedAt != null &&
        (since == null || settingsUpdatedAt.isAfter(since));
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
        await client
            .from(kSupabaseMealsTable)
            .upsert(mealPayloads)
            .select('id');
        _failedMealSyncIds.removeAll(entriesToSync.map((e) => e.id));
        _failedMealDeleteSyncIds.removeAll(
          deletionsToSync
              .map((e) => (e['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
        );
        if (report != null) {
          report.pushedMeals += entriesToSync.length;
          report.pushedMealDeletes += deletionsToSync.length;
        }
      } catch (_) {
        _failedMealSyncIds.addAll(entriesToSync.map((e) => e.id));
        _failedMealDeleteSyncIds.addAll(
          deletionsToSync
              .map((e) => (e['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
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
        await client
            .from(kSupabaseCustomFoodsTable)
            .upsert(foodPayloads)
            .select('id');
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
          customDeletionsToSync
              .map((e) => (e['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
        );
        await _saveOverrides();
        rethrow;
      }
      if (deletePayloads.isNotEmpty) {
        try {
          await client
              .from(kSupabaseCustomFoodsTable)
              .upsert(deletePayloads)
              .select('id');
          _failedCustomFoodDeleteSyncIds.removeAll(
            customDeletionsToSync
                .map((e) => (e['id'] ?? '').toString())
                .where((id) => id.isNotEmpty),
          );
          if (report != null) {
            report.pushedCustomDeletes += deletePayloads.length;
          }
        } catch (_) {
          _failedCustomFoodDeleteSyncIds.addAll(
            customDeletionsToSync
                .map((e) => (e['id'] ?? '').toString())
                .where((id) => id.isNotEmpty),
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
      await client
          .from(kSupabaseUserSettingsTable)
          .upsert(settingsPayload)
          .select('user_id');
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

  Future<List<Map<String, dynamic>>> _fetchPagedRows(
    dynamic Function(int from, int to) fetchPage, {
    int pageSize = 1000,
  }) async {
    final all = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await fetchPage(from, from + pageSize - 1);
      if (page is! List) break;
      for (final row in page) {
        if (row is Map<String, dynamic>) {
          all.add(row);
        } else if (row is Map) {
          all.add(row.map((key, value) => MapEntry(key.toString(), value)));
        }
      }
      if (page.length < pageSize) break;
      from += pageSize;
    }
    return all;
  }

  Future<void> syncFromSupabase({
    SyncReport? report,
    DateTime? sinceOverride,
    bool allowPrune = true,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('Supabase not signed in');
    }
    final client = _supabase.client;
    final settingsRow = await _fetchRemoteSettingsRow(user.id);
    if (settingsRow != null) {
      final remoteUpdatedAt =
          DateTime.tryParse(settingsRow['updated_at'] as String? ?? '');
      final localUpdatedAt = _settingsUpdatedAt();
      if (remoteUpdatedAt != null &&
          (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
        final profileJson = settingsRow['profile_json'];
        if (profileJson is Map<String, dynamic>) {
          _applyProfile(profileJson);
        } else if (profileJson is Map) {
          _applyProfile(profileJson.map((k, v) => MapEntry(k.toString(), v)));
        }
        _normalizeProfileGoalAndPlan();
        final overridesJson = settingsRow['overrides_json'];
        if (overridesJson is Map<String, dynamic>) {
          _applySettingsOverrides(overridesJson);
        } else if (overridesJson is Map) {
          _applySettingsOverrides(
              overridesJson.map((k, v) => MapEntry(k.toString(), v)));
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
    final since = sinceOverride ?? _localSyncAt();
    final existingEntries = {
      for (final entry in entries) entry.id: entry,
    };
    dynamic mealsQuery() {
      var base =
          client.from(kSupabaseMealsTable).select().eq('user_id', user.id);
      if (since != null) {
        final iso = since.toIso8601String();
        base = base.or('updated_at.gt.$iso,deleted_at.gt.$iso');
      }
      return base.order('id', ascending: true);
    }

    final rows =
        await _fetchPagedRows((from, to) => mealsQuery().range(from, to));
    if (rows is List) {
      final remoteIds = <String>{};
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final entryId = row['id'] as String?;
        if (entryId != null) {
          remoteIds.add(entryId);
        }
        final deletedAt = row['deleted_at'] as String?;
        final remoteUpdatedAt =
            DateTime.tryParse(row['updated_at'] as String? ?? '');
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
        if (existing != null &&
            existing.imageBytes.isNotEmpty &&
            existing.imageHash == row['image_hash']) {
          imageBytes = existing.imageBytes;
        } else {
          imageBytes = await _downloadImageIfAvailable(
            bucket: kSupabaseMealImagesBucket,
            path: imagePath,
          );
        }
        final resolvedImageBytes = imageBytes ?? _namePlaceholderBytes;
        Uint8List? labelBytes;
        if (existing != null &&
            existing.labelImageBytes != null &&
            labelPath != null &&
            labelPath.isNotEmpty) {
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
      // Remove local entries missing from remote on full sync only.
      if (since == null && allowPrune && remoteIds.isNotEmpty) {
        // Remove local entries that no longer exist remotely (full sync only)
        final toRemove =
            entries.where((e) => !remoteIds.contains(e.id)).toList();
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
    dynamic foodsQuery() {
      var base = client
          .from(kSupabaseCustomFoodsTable)
          .select()
          .eq('user_id', user.id);
      if (since != null) {
        final iso = since.toIso8601String();
        base = base.or('updated_at.gt.$iso,deleted_at.gt.$iso');
      }
      return base.order('id', ascending: true);
    }

    final foodRows =
        await _fetchPagedRows((from, to) => foodsQuery().range(from, to));
    if (foodRows is List) {
      final remoteFoodIds = <String>{};
      for (final row in foodRows) {
        if (row is! Map<String, dynamic>) continue;
        final foodId = row['id'] as String?;
        if (foodId != null) {
          remoteFoodIds.add(foodId);
        }
        final deletedAt = row['deleted_at'] as String?;
        final remoteUpdatedAt =
            DateTime.tryParse(row['updated_at'] as String? ?? '');
        if (deletedAt != null && deletedAt.isNotEmpty) {
          if (foodId != null) {
            final existing = existingFoods[foodId];
            if (existing != null &&
                remoteUpdatedAt != null &&
                existing.updatedAt.isAfter(remoteUpdatedAt)) {
              _failedCustomFoodSyncIds.add(foodId);
              continue;
            }
            customFoods.removeWhere((food) => food.id == foodId);
            _deletedCustomFoods.remove(foodId);
            if (report != null) report.pulledCustomDeletes += 1;
          }
          continue;
        }
        final existing = foodId == null ? null : existingFoods[foodId];
        if (existing != null &&
            remoteUpdatedAt != null &&
            existing.updatedAt.isAfter(remoteUpdatedAt)) {
          _failedCustomFoodSyncIds.add(existing.id);
          continue;
        }
        final imagePath = row['image_path'] as String?;
        final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
        Uint8List? bytes;
        if (existing != null &&
            updatedAt != null &&
            existing.updatedAt.isAtSameMomentAs(updatedAt)) {
          bytes = existing.imageBytes;
        } else {
          bytes = await _downloadImageIfAvailable(
            bucket: kSupabaseMealImagesBucket,
            path: imagePath,
          );
        }
        final resolvedBytes =
            bytes ?? existing?.imageBytes ?? _namePlaceholderBytes;
        final food = CustomFood(
          id: row['id'] as String,
          name: (row['name'] as String?) ?? '',
          summary: (row['summary'] as String?) ?? '',
          calorieRange: (row['calorie_range'] as String?) ?? '',
          suggestion: (row['suggestion'] as String?) ?? '',
          macros: _parseMacros(row['macros']),
          imageBytes: resolvedBytes,
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ??
              DateTime.now(),
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
      if (since == null && allowPrune && remoteFoodIds.isNotEmpty) {
        final toRemove = existingFoods.keys
            .where((id) => !remoteFoodIds.contains(id))
            .toList();
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
    _syncSelectedDateToLatestEntryIfNeeded();
    notifyListeners();
  }

  void setSyncInProgress(bool value) {
    if (_syncing == value) return;
    _syncing = value;
    notifyListeners();
  }

  void setLastSyncError(String? value) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isEmpty) {
      value = null;
    }
    if (_lastSyncError == value) return;
    _lastSyncError = value;
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
    final remoteSettingsUpdatedAt =
        await _fetchRemoteSettingsUpdatedAt(user.id);
    final hasLocalSettings = localSettingsUpdatedAt != null;
    final hasLocalMeals = entries.isNotEmpty;
    final hasLocalCustomFoods = customFoods.isNotEmpty;
    final hasLocalData = hasLocalMeals || hasLocalCustomFoods;

    bool changed = false;
    if (remoteSyncAt == null) {
      if (!hasLocalData && !hasLocalSettings) {
        await syncFromSupabase(
            report: report, sinceOverride: localSyncAt, allowPrune: true);
        changed = report.hasChanges;
        if (changed) {
          final now = DateTime.now().toUtc();
          await _storeRemoteSyncAt(user.id, now);
          await _storeLocalSyncAt(now);
        }
        _meta['last_sync_fingerprint'] = _syncFingerprint();
        await _saveOverrides();
        _lastSyncReport = report;
        _lastSyncError = null;
        return changed;
      }
      // Remote has no sync_meta yet. Pull first without pruning local data.
      await syncFromSupabase(
          report: report, sinceOverride: localSyncAt, allowPrune: false);
      if (report.hasChanges) {
        changed = true;
      }
      final pushed = await syncToSupabase(report: report);
      if (pushed) {
        changed = true;
        final now = DateTime.now().toUtc();
        await _storeRemoteSyncAt(user.id, now);
        await _storeLocalSyncAt(now);
      } else if (changed) {
        // If we only pulled, still establish sync_meta for future diffs.
        final now = DateTime.now().toUtc();
        await _storeRemoteSyncAt(user.id, now);
        await _storeLocalSyncAt(now);
      }
      _meta['last_sync_fingerprint'] = _syncFingerprint();
      await _saveOverrides();
      _lastSyncReport = report;
      _lastSyncError = null;
      return changed;
    }

    // 1) Pull remote changes first using the previous local sync time.
    final shouldPullData = remoteSyncAt != null &&
        (localSyncAt == null || remoteSyncAt.isAfter(localSyncAt));
    final shouldPullSettings = remoteSettingsUpdatedAt != null &&
        (localSettingsUpdatedAt == null ||
            remoteSettingsUpdatedAt.isAfter(localSettingsUpdatedAt));
    // If local has no meal entries (e.g., reinstall/cleared local cache),
    // force one full pull even when sync fingerprint says up-to-date.
    final needFullMealPull = !hasLocalMeals;
    final shouldPull = shouldPullData || shouldPullSettings || needFullMealPull;
    if (shouldPull) {
      final isFullPull = needFullMealPull;
      await syncFromSupabase(
        report: report,
        sinceOverride: isFullPull ? null : localSyncAt,
        // Skip prune during full pull to avoid deleting local-only rows prematurely.
        allowPrune: !isFullPull,
      );
      if (remoteSyncAt != null &&
          (localSyncAt == null ||
              remoteSyncAt.isAfter(localSyncAt) ||
              isFullPull)) {
        await _storeLocalSyncAt(remoteSyncAt);
      }
      changed = true;
    }

    // 2) Then push local changes (if any).
    final pushed = await syncToSupabase(report: report);
    if (pushed) {
      changed = true;
      final now = DateTime.now().toUtc();
      await _storeRemoteSyncAt(user.id, now);
      await _storeLocalSyncAt(now);
    }

    // 3) Update fingerprint after sync to avoid stale "no change" state
    _meta['last_sync_fingerprint'] = _syncFingerprint();
    await _saveOverrides();
    _lastSyncReport = report;
    _lastSyncError = null;
    return changed;
  }

  Future<bool> retryFailedSync() async {
    if (!hasFailedSync) return false;
    final user = _supabase.currentUser;
    if (user == null) {
      throw Exception('Supabase not signed in');
    }
    final report = SyncReport();
    final changed = await syncToSupabase(report: report);
    if (changed) {
      final now = DateTime.now().toUtc();
      await _storeRemoteSyncAt(user.id, now);
      await _storeLocalSyncAt(now);
    }
    _lastSyncReport = report;
    _lastSyncError = null;
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
    final String result = await _supabase.client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true),
        )
        .timeout(const Duration(seconds: 12));
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

  Map<String, dynamic> _mealEntryToRow(
      MealEntry entry, String userId, String? imagePath, String? labelPath) {
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
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.tryParse(row['updated_at'] as String),
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.tryParse(row['deleted_at'] as String),
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
      'failed_custom_food_delete_sync_ids':
          _failedCustomFoodDeleteSyncIds.toList(),
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
    return profile.language == 'en'
        ? const Locale('en')
        : const Locale('zh', 'TW');
  }

  void _scheduleAutoFinalize() {
    _autoFinalizeTimer?.cancel();
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day,
        profile.dailySummaryTime.hour, profile.dailySummaryTime.minute);
    final next =
        now.isAfter(target) ? target.add(const Duration(days: 1)) : target;
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
    final targetDate =
        weekStart.add(Duration(days: profile.weeklySummaryWeekday - 1));
    final target = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      profile.dailySummaryTime.hour,
      profile.dailySummaryTime.minute,
    );
    final next =
        now.isAfter(target) ? target.add(const Duration(days: 7)) : target;
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
        key.startsWith('day_finalized:') ||
        key == _kMockSubscriptionKey ||
        key == _kMockSubscriptionPlanKey ||
        key == _kIapSubscriptionKey ||
        key == _kAccessCheckAtKey ||
        key == _kAccessGraceHoursKey ||
        key == _kAccessPlanKey ||
        key == _kAccessEntitlementsKey;
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
          parsed[key.toString()] =
              value.map((k, v) => MapEntry(k, v.toString()));
        } else if (value is Map) {
          parsed[key.toString()] =
              value.map((k, v) => MapEntry(k.toString(), v.toString()));
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
    _mockSubscriptionActive = _meta[_kMockSubscriptionKey] == 'true';
    _mockSubscriptionPlanId = _meta[_kMockSubscriptionPlanKey];
    _iapSubscriptionActive = _meta[_kIapSubscriptionKey] == 'true';
    final rawPlan = (_meta[_kAccessPlanKey] ?? '').trim();
    _accessPlan = rawPlan.isEmpty ? 'unknown' : rawPlan;
    _backendEntitlements.clear();
    final rawEntitlements = _meta[_kAccessEntitlementsKey];
    if (rawEntitlements != null && rawEntitlements.trim().isNotEmpty) {
      for (final part in rawEntitlements.split(',')) {
        final value = part.trim();
        if (value.isNotEmpty) {
          _backendEntitlements.add(value);
        }
      }
    }
  }

  void setMockSubscriptionActive(bool value, {String? planId}) {
    _mockSubscriptionActive = value;
    _meta[_kMockSubscriptionKey] = value ? 'true' : 'false';
    if (value && planId != null) {
      _mockSubscriptionPlanId = planId;
      _meta[_kMockSubscriptionPlanKey] = planId;
    } else if (!value) {
      _mockSubscriptionPlanId = null;
      _meta.remove(_kMockSubscriptionPlanKey);
    }
    _touchSettingsUpdatedAt();
    notifyListeners();
    // ignore: discarded_futures
    _saveOverrides();
  }

  void setAccessGraceHours(int hours) {
    final value = hours.clamp(1, 168);
    _meta[_kAccessGraceHoursKey] = value.toString();
    _touchSettingsUpdatedAt();
    notifyListeners();
    // ignore: discarded_futures
    _saveOverrides();
  }

  ProductDetails? productById(String id) {
    for (final product in _iapProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> initIap() async {
    if (_iapInitialized) return;
    _iapInitialized = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _iapAvailable = await _iap.isAvailable();
    if (!_iapAvailable) {
      notifyListeners();
      return;
    }
    _iapSubscription ??=
        _iap.purchaseStream.listen(_onPurchaseUpdated, onError: (error) {
      _iapLastError = error.toString();
      _iapProcessing = false;
      notifyListeners();
    });
    final response =
        await _iap.queryProductDetails({kIapMonthlyId, kIapYearlyId});
    if (response.error != null) {
      _iapLastError = response.error!.message;
    }
    _iapProducts = response.productDetails;
    notifyListeners();
    await refreshIapStatus();
  }

  Future<void> refreshIapStatus() async {
    if (!_iapAvailable) return;
    _iapProcessing = true;
    _iapLastError = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _iapLastError = e.toString();
    } finally {
      _iapProcessing = false;
      notifyListeners();
    }
  }

  Future<void> buySubscription(String productId) async {
    if (!_iapAvailable) {
      _iapLastError = 'IAP unavailable';
      notifyListeners();
      return;
    }
    final product = productById(productId);
    if (product == null) {
      _iapLastError = 'Product not found';
      notifyListeners();
      return;
    }
    _iapProcessing = true;
    _iapLastError = null;
    notifyListeners();
    try {
      final param = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _iapProcessing = false;
      _iapLastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> restoreIapPurchases() async {
    if (!_iapAvailable) {
      _iapLastError = 'IAP unavailable';
      notifyListeners();
      return;
    }
    _iapProcessing = true;
    _iapLastError = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _iapLastError = e.toString();
    } finally {
      _iapProcessing = false;
      notifyListeners();
    }
  }

  bool _isIapProduct(String productId) {
    return productId == kIapMonthlyId || productId == kIapYearlyId;
  }

  void _setIapActive(bool value) {
    _iapSubscriptionActive = value;
    _meta[_kIapSubscriptionKey] = value ? 'true' : 'false';
    _touchSettingsUpdatedAt();
    notifyListeners();
    // ignore: discarded_futures
    _saveOverrides();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    bool active = _iapSubscriptionActive;
    for (final purchase in purchases) {
      if (_isIapProduct(purchase.productID)) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          active = true;
        } else if (purchase.status == PurchaseStatus.error) {
          _iapLastError = purchase.error?.message ?? 'Purchase error';
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    _iapProcessing = false;
    if (active != _iapSubscriptionActive) {
      _setIapActive(active);
    } else {
      notifyListeners();
    }
  }

  Map<String, dynamic> _profileToMap() {
    return {
      'name': profile.name,
      'email': profile.email,
      'gender': profile.gender,
      'chat_assistant_name': profile.chatAssistantName,
      'chat_avatar': profile.chatAvatarBase64,
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
      'breakfast_reminder_enabled': profile.breakfastReminderEnabled,
      'lunch_reminder_enabled': profile.lunchReminderEnabled,
      'dinner_reminder_enabled': profile.dinnerReminderEnabled,
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
      'plate_asset': profile.plateAsset,
      'theme_asset': profile.themeAsset,
      'text_scale': profile.textScale,
      'nutrition_chart': profile.nutritionChartStyle,
      'nutrition_value_mode': profile.nutritionValueMode,
      'glow_enabled': profile.glowEnabled,
      'exercise_suggestion_type': profile.exerciseSuggestionType,
      'calorie_history_days': profile.calorieHistoryDays,
    };
  }

  void _applyProfile(Map<String, dynamic> data) {
    profile
      ..name = (data['name'] as String?) ?? profile.name
      ..email = (data['email'] as String?) ?? profile.email
      ..gender = (data['gender'] as String?) ?? profile.gender
      ..chatAssistantName =
          (data['chat_assistant_name'] as String?) ?? profile.chatAssistantName
      ..chatAvatarBase64 =
          (data['chat_avatar'] as String?) ?? profile.chatAvatarBase64
      ..containerType =
          (data['container_type'] as String?) ?? profile.containerType
      ..containerSize =
          (data['container_size'] as String?) ?? profile.containerSize
      ..containerDepth =
          (data['container_depth'] as String?) ?? profile.containerDepth
      ..containerDiameterCm =
          _parseInt(data['container_diameter_cm'], profile.containerDiameterCm)
      ..containerCapacityMl =
          _parseInt(data['container_capacity_ml'], profile.containerCapacityMl)
      ..dietType = (data['diet_type'] as String?) ?? profile.dietType
      ..dietNote = (data['diet_note'] as String?) ?? profile.dietNote
      ..tone = (data['tone'] as String?) ?? profile.tone
      ..persona = (data['persona'] as String?) ?? profile.persona
      ..activityLevel =
          (data['activity_level'] as String?) ?? profile.activityLevel
      ..heightCm = _parseInt(data['height_cm'], profile.heightCm)
      ..weightKg = _parseInt(data['weight_kg'], profile.weightKg)
      ..age = _parseInt(data['age'], profile.age)
      ..goal = (data['goal'] as String?) ?? profile.goal
      ..planSpeed = (data['plan_speed'] as String?) ?? profile.planSpeed
      ..dailySummaryTime = _parseTime(
          data['daily_summary_time'] as String?, profile.dailySummaryTime)
      ..weeklySummaryWeekday = _parseInt(
          data['weekly_summary_weekday'], profile.weeklySummaryWeekday)
      ..breakfastReminderEnabled =
          (data['breakfast_reminder_enabled'] as bool?) ??
              profile.breakfastReminderEnabled
      ..lunchReminderEnabled = (data['lunch_reminder_enabled'] as bool?) ??
          profile.lunchReminderEnabled
      ..dinnerReminderEnabled = (data['dinner_reminder_enabled'] as bool?) ??
          profile.dinnerReminderEnabled
      ..breakfastStart =
          _parseTime(data['breakfast_start'] as String?, profile.breakfastStart)
      ..breakfastEnd =
          _parseTime(data['breakfast_end'] as String?, profile.breakfastEnd)
      ..brunchStart =
          _parseTime(data['brunch_start'] as String?, profile.brunchStart)
      ..brunchEnd = _parseTime(data['brunch_end'] as String?, profile.brunchEnd)
      ..lunchStart =
          _parseTime(data['lunch_start'] as String?, profile.lunchStart)
      ..lunchEnd = _parseTime(data['lunch_end'] as String?, profile.lunchEnd)
      ..afternoonTeaStart = _parseTime(
          data['afternoon_tea_start'] as String?, profile.afternoonTeaStart)
      ..afternoonTeaEnd = _parseTime(
          data['afternoon_tea_end'] as String?, profile.afternoonTeaEnd)
      ..dinnerStart =
          _parseTime(data['dinner_start'] as String?, profile.dinnerStart)
      ..dinnerEnd = _parseTime(data['dinner_end'] as String?, profile.dinnerEnd)
      ..lateSnackStart = _parseTime(
          data['late_snack_start'] as String?, profile.lateSnackStart)
      ..lateSnackEnd =
          _parseTime(data['late_snack_end'] as String?, profile.lateSnackEnd)
      ..language = (data['language'] as String?) ?? profile.language
      ..apiBaseUrl = profile.apiBaseUrl
      ..plateAsset = (data['plate_asset'] as String?) ?? profile.plateAsset
      ..themeAsset = (data['theme_asset'] as String?) ?? profile.themeAsset
      ..textScale =
          (data['text_scale'] as num?)?.toDouble() ?? profile.textScale
      ..nutritionChartStyle =
          (data['nutrition_chart'] as String?) ?? profile.nutritionChartStyle
      ..nutritionValueMode = (data['nutrition_value_mode'] as String?) ??
          profile.nutritionValueMode
      ..glowEnabled = (data['glow_enabled'] as bool?) ?? profile.glowEnabled
      ..exerciseSuggestionType =
          (data['exercise_suggestion_type'] as String?) ??
              profile.exerciseSuggestionType
      ..calorieHistoryDays =
          _parseInt(data['calorie_history_days'], profile.calorieHistoryDays);
    _refreshChatAvatarBytes();
    if (profile.nutritionValueMode == 'percent') {
      profile.nutritionValueMode = 'amount';
    }
    if (profile.apiBaseUrl != kDefaultApiBaseUrl) {
      profile.apiBaseUrl = kDefaultApiBaseUrl;
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

  Map<String, dynamic> _lastMealInfo(DateTime referenceTime,
      {String? excludeMealId}) {
    final candidates = entries.where((entry) {
      if (!entry.time.isBefore(referenceTime)) return false;
      if (entry.result?.isBeverage == true) return false;
      final mealId = entry.mealId ?? entry.id;
      if (excludeMealId != null && mealId == excludeMealId) return false;
      return true;
    }).toList();
    if (candidates.isEmpty) return {};
    candidates.sort((a, b) => b.time.compareTo(a.time));
    final last = candidates.first;
    final hours = referenceTime.difference(last.time).inMinutes / 60.0;
    return {
      'last_meal_time': last.time.toIso8601String(),
      'fasting_hours': double.parse(hours.clamp(0, 9999).toStringAsFixed(2)),
    };
  }

  Map<String, dynamic> lastMealInfo(DateTime referenceTime,
      {String? excludeMealId}) {
    return _lastMealInfo(referenceTime, excludeMealId: excludeMealId);
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

class MealReminder {
  MealReminder({
    required this.type,
    required this.date,
  });

  final MealType type;
  final DateTime date;
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
    required this.chatAssistantName,
    required this.chatAvatarBase64,
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
    required this.breakfastReminderEnabled,
    required this.lunchReminderEnabled,
    required this.dinnerReminderEnabled,
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
    required this.calorieHistoryDays,
  });

  String name;
  String email;
  String gender;
  String chatAssistantName;
  String chatAvatarBase64;
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
  bool breakfastReminderEnabled;
  bool lunchReminderEnabled;
  bool dinnerReminderEnabled;
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
  int calorieHistoryDays;

  factory UserProfile.initial() {
    return UserProfile(
      name: '小明',
      email: 'xiaoming123@gmail.com',
      gender: 'unspecified',
      chatAssistantName: '',
      chatAvatarBase64: '',
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
      goal: kGoalValueLoseFat,
      planSpeed: kPlanSpeedValueStable,
      dailySummaryTime: const TimeOfDay(hour: 21, minute: 0),
      weeklySummaryWeekday: DateTime.sunday,
      breakfastReminderEnabled: true,
      lunchReminderEnabled: true,
      dinnerReminderEnabled: true,
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
      calorieHistoryDays: 7,
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
