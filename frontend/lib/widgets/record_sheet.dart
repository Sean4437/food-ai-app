import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';

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

Future<RecordResult?> showRecordSheet(
  BuildContext context,
  AppState app, {
  MealType? fixedType,
  DateTime? overrideTime,
}) async {
  final t = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
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
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 18)),
              title: Text(t.pickFromCamera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 18)),
              title: Text(t.pickFromGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Text('✖️', style: TextStyle(fontSize: 18)),
              title: Text(t.cancel),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );

  if (source == null) return null;
  final picker = ImagePicker();
  bool isMulti = false;
  if (source == ImageSource.gallery) {
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return null;
    isMulti = files.length > 1;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entry = await app.addEntryFromFiles(files, locale, fixedType: fixedType, overrideTime: overrideTime);
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

  final xfile = await picker.pickImage(source: source);
  if (xfile == null) return null;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final entry = await app.addEntry(xfile, locale, fixedType: fixedType, overrideTime: overrideTime);
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
