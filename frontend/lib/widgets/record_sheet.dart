import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';

enum _RecordInputMode {
  camera,
  gallery,
  name,
}

class RecordResult {
  const RecordResult({
    required this.entry,
    required this.mealId,
    required this.mealType,
    required this.date,
    required this.mealCount,
    required this.isMulti,
  });

  final MealEntry entry;
  final String mealId;
  final MealType mealType;
  final DateTime date;
  final int mealCount;
  final bool isMulti;
}

Future<String?> _promptFoodName(BuildContext context, AppLocalizations t) async {
  final controller = TextEditingController();
  final value = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(t.foodNameLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: t.suggestInstantNameHint),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.suggestInstantNameSubmit),
          ),
        ],
      );
    },
  );
  controller.dispose();
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed;
}

String _catalogFallbackMessage(BuildContext context) {
  final isEn = Localizations.localeOf(context).languageCode.toLowerCase() == 'en';
  return isEn
      ? 'Catalog lookup failed. Switched to AI estimate.'
      : '資料庫查詢失敗，已改用 AI 估算。';
}

String _nameLookupErrorMessage(BuildContext context, String code) {
  final isEn = Localizations.localeOf(context).languageCode.toLowerCase() == 'en';
  switch (code) {
    case 'catalog_not_found':
      return isEn
          ? 'No match found in the food database. Try a shorter name or add a custom food.'
          : '資料庫找不到這個食物，請改用較短名稱或先新增自訂食物。';
    case 'catalog_unavailable':
      return isEn
          ? 'Food database is temporarily unavailable. Please try again later.'
          : '資料庫暫時無法使用，請稍後再試。';
    default:
      return isEn ? 'Name lookup failed.' : '名稱查詢失敗。';
  }
}

Future<RecordResult?> showRecordSheet(
  BuildContext context,
  AppState app, {
  MealType? fixedType,
  DateTime? overrideTime,
}) async {
  final t = AppLocalizations.of(context)!;
  final mode = await showModalBottomSheet<_RecordInputMode>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.pickFromCamera),
              onTap: () => Navigator.of(context).pop(_RecordInputMode.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.pickFromGallery),
              onTap: () => Navigator.of(context).pop(_RecordInputMode.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(t.suggestInstantNameSubmit),
              subtitle: Text(t.suggestInstantNameHint),
              onTap: () => Navigator.of(context).pop(_RecordInputMode.name),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(t.cancel),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );

  if (mode == null) return null;
  if (!context.mounted) return null;
  final picker = ImagePicker();
  var isMulti = false;

  if (mode == _RecordInputMode.name) {
    final foodName = await _promptFoodName(context, t);
    if (!context.mounted) return null;
    if (foodName == null || foodName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.nameAnalyzeEmpty)),
      );
      return null;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    MealEntry entry;
    try {
      entry = await app.analyzeNameAndSave(
        foodName.trim(),
        locale,
        overrideTime: overrideTime,
        fixedType: fixedType,
      );
    } on NameLookupException catch (err) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_nameLookupErrorMessage(context, err.code))),
      );
      return null;
    } catch (_) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.analyzeFailed)),
      );
      return null;
    }
    final mealId = entry.mealId ?? entry.id;
    final date = DateTime(entry.time.year, entry.time.month, entry.time.day);
    final count = app.entriesForMealId(mealId).length;
    if ((entry.lastAnalyzeReason ?? '').trim().toLowerCase() == 'name_ai_catalog_error') {
      final message = (entry.lastAnalyzedNote ?? '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? _catalogFallbackMessage(context) : message)),
      );
    }
    return RecordResult(
      entry: entry,
      mealId: mealId,
      mealType: entry.type,
      date: date,
      mealCount: count,
      isMulti: false,
    );
  }

  if (mode == _RecordInputMode.gallery) {
    final files = await picker.pickMultiImage();
    if (!context.mounted) return null;
    if (files.isEmpty) return null;
    isMulti = files.length > 1;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entry = await app.addEntryFromFiles(
      files,
      locale,
      fixedType: fixedType,
      overrideTime: overrideTime,
    );
    if (entry == null) return null;
    final mealId = entry.mealId ?? entry.id;
    final date = DateTime(entry.time.year, entry.time.month, entry.time.day);
    final count = app.entriesForMealId(mealId).length;
    return RecordResult(
      entry: entry,
      mealId: mealId,
      mealType: entry.type,
      date: date,
      mealCount: count,
      isMulti: isMulti,
    );
  }

  final xfile = await picker.pickImage(source: ImageSource.camera);
  if (!context.mounted) return null;
  if (xfile == null) return null;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final entry = await app.addEntry(
    xfile,
    locale,
    fixedType: fixedType,
    overrideTime: overrideTime,
  );
  if (entry == null) return null;
  final mealId = entry.mealId ?? entry.id;
  final date = DateTime(entry.time.year, entry.time.month, entry.time.day);
  final count = app.entriesForMealId(mealId).length;
  return RecordResult(
    entry: entry,
    mealId: mealId,
    mealType: entry.type,
    date: date,
    mealCount: count,
    isMulti: isMulti,
  );
}
