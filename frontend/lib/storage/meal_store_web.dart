import 'dart:convert';
import 'dart:typed_data';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import '../models/analysis_result.dart';
import '../models/meal_entry.dart';
import 'meal_store.dart';

class MealStoreImpl implements MealStore {
  static const _dbName = 'food_ai_web.db';
  static const _storeName = 'meal_entries';
  final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store(_storeName);
  Database? _db;

  @override
  Future<void> init() async {
    _db = await databaseFactoryWeb.openDatabase(_dbName);
  }

  @override
  Future<List<MealEntry>> loadAll() async {
    final db = _db;
    if (db == null) return [];
    final records = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('time', false)]),
    );
    return records.map((record) => _rowToEntry(record.value)).toList();
  }

  @override
  Future<void> upsert(MealEntry entry) async {
    final db = _db;
    if (db == null) return;
    await _store.record(entry.id).put(db, _entryToRow(entry));
  }

  @override
  Future<void> delete(String id) async {
    final db = _db;
    if (db == null) return;
    await _store.record(id).delete(db);
  }

  @override
  Future<String> exportJson() async {
    final db = _db;
    if (db == null) return '[]';
    final records = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('time', false)]),
    );
    return json.encode(records.map((record) => record.value).toList());
  }

  @override
  Future<void> clearAll() async {
    final db = _db;
    if (db == null) return;
    await _store.delete(db);
  }

  MealEntry _rowToEntry(Map<String, Object?> row) {
    final type = _mealTypeFromString(row['type'] as String? ?? 'other');
    final resultJson = row['result_json'] as String?;
    AnalysisResult? result;
    if (resultJson != null && resultJson.isNotEmpty) {
      try {
        result = AnalysisResult.fromJson(json.decode(resultJson) as Map<String, dynamic>);
      } catch (_) {}
    }
    final bytesBase64 = row['image_base64'] as String? ?? '';
    final bytes = bytesBase64.isEmpty ? Uint8List(0) : base64Decode(bytesBase64);
    final entry = MealEntry(
      id: row['id'] as String,
      imageBytes: bytes,
      filename: row['filename'] as String,
      time: DateTime.fromMillisecondsSinceEpoch(row['time'] as int),
      type: type,
      note: row['note'] as String?,
      overrideFoodName: row['override_food_name'] as String?,
    );
    entry.result = result;
    entry.error = row['error'] as String?;
    entry.loading = false;
    return entry;
  }

  Map<String, Object?> _entryToRow(MealEntry entry) {
    return {
      'id': entry.id,
      'time': entry.time.millisecondsSinceEpoch,
      'type': entry.type.name,
      'filename': entry.filename,
      'note': entry.note,
      'override_food_name': entry.overrideFoodName,
      'image_base64': base64Encode(entry.imageBytes),
      'result_json': entry.result == null ? null : json.encode(entry.result!.toJson()),
      'error': entry.error,
    };
  }

  MealType _mealTypeFromString(String value) {
    for (final type in MealType.values) {
      if (type.name == value) return type;
    }
    return MealType.other;
  }
}
