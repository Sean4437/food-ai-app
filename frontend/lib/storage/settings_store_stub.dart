import 'settings_store.dart';

class SettingsStoreImpl implements SettingsStore {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _overrides;

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, dynamic>?> loadProfile() async => _profile;

  @override
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    _profile = Map<String, dynamic>.from(profile);
  }

  @override
  Future<Map<String, dynamic>?> loadOverrides() async => _overrides;

  @override
  Future<void> saveOverrides(Map<String, dynamic> overrides) async {
    _overrides = Map<String, dynamic>.from(overrides);
  }
}
