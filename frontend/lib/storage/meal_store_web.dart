import 'dart:convert';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import '../models/meal_entry.dart';
import 'meal_store.dart';

class MealStoreImpl implements MealStore {
  static const String _dbName = 'food_ai_app.db';
  static const String _storeName = 'meal_entries';

  final _store = stringMapStoreFactory.store(_storeName);
  Database? _db;

  @override
  Future<void> init() async {
    _db = await databaseFactoryWeb.openDatabase(_dbName);
  }

  @override
  Future<List<MealEntry>> loadAll() async {
    final records = await _store.find(_db!);
    return records.map((record) => MealEntry.fromJson(record.value)).toList();
  }

  @override
  Future<void> upsert(MealEntry entry) async {
    await _store.record(entry.id).put(_db!, entry.toJson());
  }

  @override
  Future<void> delete(String id) async {
    await _store.record(id).delete(_db!);
  }

  @override
  Future<String> exportJson() async {
    final records = await _store.find(_db!);
    final list = records.map((record) => record.value).toList();
    return jsonEncode(list);
  }

  @override
  Future<void> clearAll() async {
    await _store.delete(_db!);
  }
}
