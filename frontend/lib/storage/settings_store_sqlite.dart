import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'settings_store.dart';

class SettingsStoreImpl implements SettingsStore {
  static const _dbName = 'food_ai.db';
  static const _table = 'app_settings';
  static const _profileKey = 'profile';
  static const _overrideKey = 'overrides';
  Database? _db;

  Future<void> _ensureTable(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS $_table(key TEXT PRIMARY KEY, value TEXT)');
  }

  @override
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbName);
    _db = await openDatabase(
      dbPath,
      version: 5,
      onCreate: (db, version) async {
        await _ensureTable(db);
      },
      onOpen: (db) async {
        await _ensureTable(db);
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> loadProfile() async {
    final db = _db;
    if (db == null) return null;
    await _ensureTable(db);
    final rows = await db.query(_table, where: 'key = ?', whereArgs: [_profileKey], limit: 1);
    if (rows.isEmpty) return null;
    final value = rows.first['value'] as String?;
    if (value == null || value.isEmpty) return null;
    return json.decode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final db = _db;
    if (db == null) return;
    await _ensureTable(db);
    await db.insert(
      _table,
      {'key': _profileKey, 'value': json.encode(profile)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, dynamic>?> loadOverrides() async {
    final db = _db;
    if (db == null) return null;
    await _ensureTable(db);
    final rows = await db.query(_table, where: 'key = ?', whereArgs: [_overrideKey], limit: 1);
    if (rows.isEmpty) return null;
    final value = rows.first['value'] as String?;
    if (value == null || value.isEmpty) return null;
    return json.decode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> saveOverrides(Map<String, dynamic> overrides) async {
    final db = _db;
    if (db == null) return;
    await _ensureTable(db);
    await db.insert(
      _table,
      {'key': _overrideKey, 'value': json.encode(overrides)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
