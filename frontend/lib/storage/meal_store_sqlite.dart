import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/analysis_result.dart';
import '../models/meal_entry.dart';
import 'meal_store.dart';

class MealStoreImpl implements MealStore {
  static const _dbName = 'food_ai.db';
  static const _table = 'meal_entries';
  Database? _db;

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            id TEXT PRIMARY KEY,
            time INTEGER NOT NULL,
            type TEXT NOT NULL,
            filename TEXT NOT NULL,
            note TEXT,
            override_food_name TEXT,
            image_bytes BLOB NOT NULL,
            result_json TEXT,
            error TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_table ADD COLUMN override_food_name TEXT');
        }
      },
    );
  }

  @override
  Future<List<MealEntry>> loadAll() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(_table, orderBy: 'time DESC');
    return rows.map(_rowToEntry).toList();
  }

  @override
  Future<void> upsert(MealEntry entry) async {
    final db = _db;
    if (db == null) return;
    await db.insert(_table, _entryToRow(entry), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String id) async {
    final db = _db;
    if (db == null) return;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
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
    final entry = MealEntry(
      id: row['id'] as String,
      imageBytes: row['image_bytes'] as Uint8List,
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
      'image_bytes': entry.imageBytes,
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
