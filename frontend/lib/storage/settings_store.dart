import 'settings_store_stub.dart'
    if (dart.library.html) 'settings_store_web.dart'
    if (dart.library.io) 'settings_store_sqlite.dart';

abstract class SettingsStore {
  Future<void> init();
  Future<Map<String, dynamic>?> loadProfile();
  Future<void> saveProfile(Map<String, dynamic> profile);
  Future<Map<String, dynamic>?> loadOverrides();
  Future<void> saveOverrides(Map<String, dynamic> overrides);
}

SettingsStore createSettingsStore() => SettingsStoreImpl();
