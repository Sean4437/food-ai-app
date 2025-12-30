import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../models/analysis_result.dart';
import '../models/meal_entry.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  AppState() : _api = ApiService(baseUrl: _resolveBaseUrl());

  final ApiService _api;
  final List<MealEntry> entries = [];
  final UserProfile profile = UserProfile.initial();

  MealEntry? get latestEntry => entries.isNotEmpty ? entries.first : null;

  String dailyCalorieRangeLabel(AppLocalizations t) {
    int minSum = 0;
    int maxSum = 0;
    bool hasRange = false;
    for (final entry in entries) {
      final range = _parseCalorieRange(entry.result?.calorieRange);
      if (range == null) continue;
      minSum += range[0];
      maxSum += range[1];
      hasRange = true;
    }
    return hasRange ? '$minSum-$maxSum kcal' : t.calorieUnknown;
  }

  String todayStatusLabel(AppLocalizations t) {
    final entry = latestEntry;
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
    final entry = latestEntry;
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

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  MealType resolveMealType(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour <= 10) return MealType.breakfast;
    if (hour >= 11 && hour <= 14) return MealType.lunch;
    if (hour >= 17 && hour <= 20) return MealType.dinner;
    if (hour >= 21 || hour <= 2) return MealType.lateSnack;
    return MealType.other;
  }

  Future<MealEntry?> addEntry(
    XFile xfile,
    String locale, {
    String? note,
    MealType? fixedType,
  }) async {
    final time = await _resolveImageTime(xfile);
    final entry = MealEntry(
      image: File(xfile.path),
      time: time,
      type: fixedType ?? resolveMealType(time),
      note: note,
    );
    entries.insert(0, entry);
    notifyListeners();
    await _analyzeEntry(entry, locale);
    return entry;
  }

  void updateEntryTime(MealEntry entry, DateTime time) {
    entry.time = time;
    entry.type = resolveMealType(time);
    notifyListeners();
  }

  void updateProfile(UserProfile updated) {
    profile
      ..name = updated.name
      ..email = updated.email
      ..heightCm = updated.heightCm
      ..weightKg = updated.weightKg
      ..goal = updated.goal
      ..planSpeed = updated.planSpeed
      ..lunchReminderEnabled = updated.lunchReminderEnabled
      ..dinnerReminderEnabled = updated.dinnerReminderEnabled
      ..lunchReminderTime = updated.lunchReminderTime
      ..dinnerReminderTime = updated.dinnerReminderTime
      ..language = updated.language;
    notifyListeners();
  }

  void updateField(void Function(UserProfile profile) updater) {
    updater(profile);
    notifyListeners();
  }

  Future<void> _analyzeEntry(MealEntry entry, String locale) async {
    entry.loading = true;
    entry.error = null;
    entry.result = null;
    notifyListeners();

    try {
      final AnalysisResult res = await _api.analyzeImage(entry.image, lang: locale);
      entry.result = res;
    } catch (e) {
      entry.error = e.toString();
    } finally {
      entry.loading = false;
      notifyListeners();
    }
  }

  Future<DateTime> _resolveImageTime(XFile xfile) async {
    final exifTime = await _extractExifTime(xfile);
    if (exifTime != null) return exifTime;
    try {
      final lastModified = await xfile.lastModified();
      return lastModified;
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<DateTime?> _extractExifTime(XFile xfile) async {
    try {
      final bytes = await xfile.readAsBytes();
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

  DateTime? _parseExifDate(String value) {
    final match = RegExp(r'(\\d{4}):(\\d{2}):(\\d{2})\\s+(\\d{2}):(\\d{2}):(\\d{2})').firstMatch(value);
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

  List<int>? _parseCalorieRange(String? value) {
    if (value == null) return null;
    final match = RegExp(r'(\\d+)\\s*-\\s*(\\d+)').firstMatch(value);
    if (match == null) return null;
    final minVal = int.tryParse(match.group(1)!);
    final maxVal = int.tryParse(match.group(2)!);
    if (minVal == null || maxVal == null) return null;
    return [minVal, maxVal];
  }
}

class UserProfile {
  UserProfile({
    required this.name,
    required this.email,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.planSpeed,
    required this.lunchReminderEnabled,
    required this.dinnerReminderEnabled,
    required this.lunchReminderTime,
    required this.dinnerReminderTime,
    required this.language,
  });

  String name;
  String email;
  int heightCm;
  int weightKg;
  String goal;
  String planSpeed;
  bool lunchReminderEnabled;
  bool dinnerReminderEnabled;
  TimeOfDay lunchReminderTime;
  TimeOfDay dinnerReminderTime;
  String language;

  factory UserProfile.initial() {
    return UserProfile(
      name: '小明',
      email: 'xiaoming123@gmail.com',
      heightCm: 170,
      weightKg: 72,
      goal: '減脂',
      planSpeed: '穩定',
      lunchReminderEnabled: true,
      dinnerReminderEnabled: true,
      lunchReminderTime: const TimeOfDay(hour: 12, minute: 15),
      dinnerReminderTime: const TimeOfDay(hour: 18, minute: 45),
      language: 'zh-TW',
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
