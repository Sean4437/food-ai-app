import '../models/meal_entry.dart';
import 'meal_store_stub.dart'
    if (dart.library.io) 'meal_store_sqlite.dart';

abstract class MealStore {
  Future<void> init();
  Future<List<MealEntry>> loadAll();
  Future<void> upsert(MealEntry entry);
  Future<void> delete(String id);
}

MealStore createMealStore() => MealStoreImpl();
