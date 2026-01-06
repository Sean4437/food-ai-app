import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'settings_store.dart';

class SettingsStoreImpl implements SettingsStore {
  static const String _dbName = 'food_ai_app.db';
  static const String _storeName = 'app_settings';
  static const String _profileKey = 'profile';
  static const String _overrideKey = 'overrides';

  final _store = StoreRef<String, Map<String, dynamic>>(_storeName);
  Database? _db;

  @override
  Future<void> init() async {
    _db = await databaseFactoryWeb.openDatabase(_dbName);
  }

  @override
  Future<Map<String, dynamic>?> loadProfile() async {
    return _store.record(_profileKey).get(_db!);
  }

  @override
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _store.record(_profileKey).put(_db!, profile);
  }

  @override
  Future<Map<String, dynamic>?> loadOverrides() async {
    return _store.record(_overrideKey).get(_db!);
  }

  @override
  Future<void> saveOverrides(Map<String, dynamic> overrides) async {
    await _store.record(_overrideKey).put(_db!, overrides);
  }
}
