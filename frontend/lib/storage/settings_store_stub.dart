import 'settings_store.dart';

class SettingsStoreImpl implements SettingsStore {
  Map<String, dynamic>? _profile;

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, dynamic>?> loadProfile() async => _profile;

  @override
  Future<void> saveProfile(Map<String, dynamic> profile) async {
    _profile = Map<String, dynamic>.from(profile);
  }
}
