import '../models/meal_entry.dart';
import 'meal_store.dart';

class MealStoreImpl implements MealStore {
  final List<MealEntry> _entries = [];

  @override
  Future<void> init() async {}

  @override
  Future<List<MealEntry>> loadAll() async => List<MealEntry>.from(_entries);

  @override
  Future<void> upsert(MealEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      _entries.add(entry);
    } else {
      _entries[index] = entry;
    }
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }
}
