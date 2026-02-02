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
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            id TEXT PRIMARY KEY,
            time INTEGER NOT NULL,
            type TEXT NOT NULL,
            portion TEXT,
            portion_percent INTEGER,
            container_type TEXT,
            container_size TEXT,
            override_calorie_range TEXT,
            meal_id TEXT,
            filename TEXT NOT NULL,
            note TEXT,
            override_food_name TEXT,
            image_hash TEXT,
            last_analyzed_note TEXT,
            last_analyzed_food_name TEXT,
            image_bytes BLOB NOT NULL,
            result_json TEXT,
            error TEXT,
            updated_at INTEGER,
            deleted_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_table ADD COLUMN override_food_name TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_table ADD COLUMN image_hash TEXT');
          await db.execute('ALTER TABLE $_table ADD COLUMN last_analyzed_note TEXT');
          await db.execute('ALTER TABLE $_table ADD COLUMN last_analyzed_food_name TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE $_table ADD COLUMN portion TEXT');
          await db.execute('ALTER TABLE $_table ADD COLUMN meal_id TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE $_table ADD COLUMN portion_percent INTEGER');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE $_table ADD COLUMN updated_at INTEGER');
          await db.execute('ALTER TABLE $_table ADD COLUMN deleted_at INTEGER');
        }
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE $_table ADD COLUMN container_type TEXT');
          await db.execute('ALTER TABLE $_table ADD COLUMN container_size TEXT');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE $_table ADD COLUMN override_calorie_range TEXT');
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

  @override
  Future<String> exportJson() async {
    final db = _db;
    if (db == null) return '[]';
    final rows = await db.query(_table, orderBy: 'time DESC');
    return json.encode(rows);
  }

  @override
  Future<void> clearAll() async {
    final db = _db;
    if (db == null) return;
    await db.delete(_table);
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
      portionPercent: _portionPercentFromRow(row),
      overrideCalorieRange: row['override_calorie_range'] as String?,
      containerType: row['container_type'] as String?,
      containerSize: row['container_size'] as String?,
      updatedAt: _parseEpoch(row['updated_at']),
      deletedAt: _parseEpoch(row['deleted_at']),
      mealId: row['meal_id'] as String?,
      note: row['note'] as String?,
      overrideFoodName: row['override_food_name'] as String?,
      imageHash: row['image_hash'] as String?,
      lastAnalyzedNote: row['last_analyzed_note'] as String?,
      lastAnalyzedFoodName: row['last_analyzed_food_name'] as String?,
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
      'portion': _portionStringFromPercent(entry.portionPercent),
      'portion_percent': entry.portionPercent,
      'container_type': entry.containerType,
      'container_size': entry.containerSize,
      'override_calorie_range': entry.overrideCalorieRange,
      'meal_id': entry.mealId,
      'filename': entry.filename,
      'note': entry.note,
      'override_food_name': entry.overrideFoodName,
      'image_hash': entry.imageHash,
      'updated_at': entry.updatedAt?.millisecondsSinceEpoch,
      'deleted_at': entry.deletedAt?.millisecondsSinceEpoch,
      'last_analyzed_note': entry.lastAnalyzedNote,
      'last_analyzed_food_name': entry.lastAnalyzedFoodName,
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

  int _portionPercentFromRow(Map<String, Object?> row) {
    final percent = row['portion_percent'];
    if (percent is int) return percent;
    if (percent is num) return percent.round();
    return _portionPercentFromString(row['portion'] as String?);
  }

  DateTime? _parseEpoch(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  int _portionPercentFromString(String? value) {
    switch (value) {
      case 'full':
        return 100;
      case 'half':
        return 50;
      case 'bite':
        return 25;
    }
    return 100;
  }

  String _portionStringFromPercent(int percent) {
    if (percent >= 90) return 'full';
    if (percent >= 45) return 'half';
    return 'bite';
  }
}
