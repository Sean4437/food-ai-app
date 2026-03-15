import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';

import '../design/text_styles.dart';
import '../models/custom_food.dart';
import '../models/meal_entry.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
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
    final proteinController =
        TextEditingController(text: _macroValue(food, 'protein'));
    final carbsController =
        TextEditingController(text: _macroValue(food, 'carbs'));
    final fatController = TextEditingController(text: _macroValue(food, 'fat'));
    final sodiumController =
        TextEditingController(text: _macroValue(food, 'sodium'));

    Uint8List workingImage = food.imageBytes;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.customEditTitle),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        workingImage,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (picked == null) return;
                        final bytes = await picked.readAsBytes();
                        setDialogState(() => workingImage = bytes);
                      },
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(t.customChangePhoto),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: t.foodNameLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: summaryController,
                  decoration: InputDecoration(labelText: t.customSummaryLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: calorieController,
                  decoration: InputDecoration(labelText: t.calorieLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: suggestionController,
                  decoration:
                      InputDecoration(labelText: t.customSuggestionLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: proteinController,
                  decoration: InputDecoration(labelText: '${t.protein} (g)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: carbsController,
                  decoration: InputDecoration(labelText: '${t.carbs} (g)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fatController,
                  decoration: InputDecoration(labelText: '${t.fat} (g)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sodiumController,
                  decoration: InputDecoration(labelText: '${t.sodium} (mg)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.save),
            ),
          ],
        ),
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
      ..updatedAt = DateTime.now()
      ..imageBytes = workingImage;

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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await app.deleteCustomFood(food);
  }

  Future<MealType?> _showMealTypePicker(
    AppState app,
    AppLocalizations t,
    MealType current,
  ) async {
    final options = MealType.values;
    return showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in options)
              ListTile(
                title: Text(app.mealTypeLabel(option, t)),
                trailing: option == current
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCustomFoodWithSchedule(CustomFood food) async {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final now = DateTime.now();
    DateTime pickedDate = DateTime(now.year, now.month, now.day);
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(now);
    MealType pickedMealType = app.resolveMealType(now);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final dateLabel =
                '${pickedDate.year}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}';
            final timeLabel = pickedTime.format(context);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.customConfirmTitle,
                      style: AppTextStyles.title2(context)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${t.customConfirmDate}:',
                        style: AppTextStyles.body(context)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final result = await showDatePicker(
                            context: context,
                            initialDate: pickedDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 1),
                          );
                          if (result == null) return;
                          setModalState(() => pickedDate = result);
                        },
                        child: Text(dateLabel),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${t.customConfirmTime}:',
                        style: AppTextStyles.body(context)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final result = await showTimePicker(
                            context: context,
                            initialTime: pickedTime,
                          );
                          if (result == null) return;
                          setModalState(() {
                            pickedTime = result;
                            final dt = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                            pickedMealType = app.resolveMealType(dt);
                          });
                        },
                        child: Text(timeLabel),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${t.customConfirmMealType}:',
                        style: AppTextStyles.body(context)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final result =
                              await _showMealTypePicker(app, t, pickedMealType);
                          if (result == null) return;
                          setModalState(() => pickedMealType = result);
                        },
                        child: Text(app.mealTypeLabel(pickedMealType, t)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(t.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(t.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (confirmed != true) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    await app.saveCustomFoodUsage(food, dateTime, pickedMealType);

    if (!mounted) return;
    TabScope.of(context).setIndex(3);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.customUseSaved)),
    );
  }

  double _parseMacroValue(String value, {bool isSodium = false}) {
    var cleaned = value.trim().toLowerCase();
    cleaned = cleaned.replaceAll('%', '').replaceAll('kcal', '').trim();
    final isMg = cleaned.contains('mg');
    cleaned = cleaned.replaceAll('mg', '').replaceAll('g', '').trim();
    final numeric = double.tryParse(cleaned) ?? 0;
    if (isSodium) {
      if (isMg) return numeric;
      if (value.toLowerCase().contains('g')) return numeric * 1000;
      return numeric;
    }
    if (isMg) return numeric / 1000;
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
                  child: Text(
                    t.customEmpty,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: Colors.black54),
                  ),
                )
              else
                for (final food in app.customFoods)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _useCustomFoodWithSchedule(food),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                            child: Image.memory(
                              food.imageBytes,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: AppTextStyles.body(context)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  food.summary,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  food.calorieRange,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () => _editCustomFood(food),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: t.edit,
                              ),
                              IconButton(
                                onPressed: () => _deleteCustomFood(food),
                                icon:
                                    const Icon(Icons.delete_outline, size: 18),
                                tooltip: t.delete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
