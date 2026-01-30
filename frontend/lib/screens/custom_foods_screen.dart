import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/custom_food.dart';
import '../design/text_styles.dart';
import '../widgets/app_background.dart';

class CustomFoodsScreen extends StatefulWidget {
  const CustomFoodsScreen({super.key});

  @override
  State<CustomFoodsScreen> createState() => _CustomFoodsScreenState();
}

class _CustomFoodsScreenState extends State<CustomFoodsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _editCustomFood(CustomFood food) async {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final nameController = TextEditingController(text: food.name);
    final summaryController = TextEditingController(text: food.summary);
    final calorieController = TextEditingController(text: food.calorieRange);
    final suggestionController = TextEditingController(text: food.suggestion);
    final proteinController = TextEditingController(text: _macroValue(food, 'protein'));
    final carbsController = TextEditingController(text: _macroValue(food, 'carbs'));
    final fatController = TextEditingController(text: _macroValue(food, 'fat'));
    final sodiumController = TextEditingController(text: _macroValue(food, 'sodium'));
    Uint8List? newImage;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.customEditTitle),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(newImage ?? food.imageBytes, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      final picked = await _picker.pickImage(source: ImageSource.gallery);
                      if (picked == null) return;
                      newImage = await picked.readAsBytes();
                      if (!mounted) return;
                      Navigator.of(context).pop(false);
                      _editCustomFood(food);
                    },
                    child: Text(t.customChangePhoto),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: InputDecoration(labelText: t.foodNameLabel)),
              const SizedBox(height: 8),
              TextField(controller: summaryController, decoration: InputDecoration(labelText: t.customSummaryLabel)),
              const SizedBox(height: 8),
              TextField(controller: calorieController, decoration: InputDecoration(labelText: t.calorieLabel)),
              const SizedBox(height: 8),
              TextField(controller: suggestionController, decoration: InputDecoration(labelText: t.customSuggestionLabel)),
              const SizedBox(height: 8),
              TextField(controller: proteinController, decoration: InputDecoration(labelText: '${t.protein} (g)')),
              const SizedBox(height: 8),
              TextField(controller: carbsController, decoration: InputDecoration(labelText: '${t.carbs} (g)')),
              const SizedBox(height: 8),
              TextField(controller: fatController, decoration: InputDecoration(labelText: '${t.fat} (g)')),
              const SizedBox(height: 8),
              TextField(controller: sodiumController, decoration: InputDecoration(labelText: '${t.sodium} (mg)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.save)),
        ],
      ),
    );
    if (result != true) return;
    food
      ..name = nameController.text.trim()
      ..summary = summaryController.text.trim()
      ..calorieRange = calorieController.text.trim()
      ..suggestion = suggestionController.text.trim()
      ..macros = {
        'protein': _parseMacroValue(proteinController.text),
        'carbs': _parseMacroValue(carbsController.text),
        'fat': _parseMacroValue(fatController.text),
        'sodium': _parseMacroValue(sodiumController.text, isSodium: true),
      }
      ..updatedAt = DateTime.now();
    if (newImage != null) {
      food.imageBytes = newImage!;
    }
    await app.upsertCustomFood(food);
  }

  Future<void> _deleteCustomFood(CustomFood food) async {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.customDeleteTitle),
        content: Text(t.customDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.delete)),
        ],
      ),
    );
    if (confirm != true) return;
    await app.deleteCustomFood(food);
  }

  double _parseMacroValue(String value, {bool isSodium = false}) {
    var cleaned = value.trim().toLowerCase();
    cleaned = cleaned.replaceAll('公克', 'g').replaceAll('毫克', 'mg');
    cleaned = cleaned.replaceAll('%', '').replaceAll('kcal', '').trim();
    final isMg = cleaned.contains('mg');
    cleaned = cleaned.replaceAll('mg', '').replaceAll('g', '').trim();
    final numeric = double.tryParse(cleaned) ?? 0;
    if (isSodium) {
      if (isMg) return numeric;
      if (value.toLowerCase().contains('g')) return numeric * 1000;
      return numeric; // no unit -> treat as mg
    }
    if (isMg) {
      return numeric / 1000;
    }
    return numeric;
  }

  String _macroValue(CustomFood food, String key) {
    final value = food.macros[key];
    if (value == null) return '';
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.customTabTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              if (app.customFoods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(t.customEmpty, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                )
              else
                for (final food in app.customFoods)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(food.imageBytes, width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(food.name, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(food.summary, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text(food.calorieRange, style: AppTextStyles.caption(context).copyWith(color: Colors.black87)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () => _editCustomFood(food),
                              icon: const Icon(Icons.edit, size: 20),
                              tooltip: t.edit,
                            ),
                            IconButton(
                              onPressed: () => _deleteCustomFood(food),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: t.delete,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
