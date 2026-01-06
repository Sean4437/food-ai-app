import 'package:flutter/material.dart';
import 'dart:async';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../models/meal_entry.dart';
import '../state/app_state.dart';
import 'meal_detail_screen.dart';
import 'day_meals_screen.dart';
import '../widgets/plate_photo.dart';

class MealItemsScreen extends StatefulWidget {
  const MealItemsScreen({
    super.key,
    required this.group,
    this.autoReturnToDayMeals = false,
    this.autoReturnDate,
    this.autoReturnMealId,
  });

  final List<MealEntry> group;
  final bool autoReturnToDayMeals;
  final DateTime? autoReturnDate;
  final String? autoReturnMealId;

  @override
  State<MealItemsScreen> createState() => _MealItemsScreenState();
}

class _MealItemsScreenState extends State<MealItemsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.86);
  int _pageIndex = 0;
  Timer? _autoTimer;
  bool _autoTimerStarted = false;

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autoReturnToDayMeals || _autoTimerStarted) return;
    final mealId = widget.autoReturnMealId;
    final date = widget.autoReturnDate;
    if (mealId == null || date == null) return;
    _autoTimerStarted = true;
    final app = AppStateScope.of(context);
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final last = app.mealInteractionAt(mealId);
      if (last == null) return;
      if (DateTime.now().difference(last) < const Duration(minutes: 1)) return;
      timer.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DayMealsScreen(date: date, initialMealId: mealId),
        ),
      );
    });
  }

  Widget _itemCard(BuildContext context, MealEntry entry, String plateAsset) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showImagePreview(context, entry),
      onLongPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: entry))),
      child: SizedBox(
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: PlatePhoto(
                imageBytes: entry.imageBytes,
                plateAsset: plateAsset,
                plateSize: 320,
                imageSize: 220,
                tilt: -0.08,
              ),
            ),
            const SizedBox(height: 12),
            Text(entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('${t.portionLabel} ${entry.portionPercent}%', style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePreview(BuildContext context, MealEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(entry.imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  double _ratioFromValue(String value) {
    final v = value.toLowerCase();
    if (v.contains('高') || v.contains('high')) return 0.8;
    if (v.contains('低') || v.contains('low')) return 0.3;
    return 0.55;
  }

  Widget _ratioBar(String label, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _portionSelector(BuildContext context, AppState app, MealEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entry.portionPercent}%', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: entry.portionPercent.toDouble(),
          min: 10,
          max: 100,
          divisions: 9,
          label: '${entry.portionPercent}%',
          onChanged: (value) {
            app.updateEntryPortionPercent(entry, value.round());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final sorted = List<MealEntry>.from(widget.group)..sort((a, b) => b.time.compareTo(a.time));
    if (_pageIndex >= sorted.length) {
      _pageIndex = 0;
    }
    final currentEntry = sorted.isEmpty ? null : sorted[_pageIndex];
    final mealSummary = sorted.isEmpty ? null : app.buildMealSummary(sorted, t);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.mealItemsTitle),
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 390,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemCount: sorted.length,
                itemBuilder: (context, index) => _itemCard(context, sorted[index], plateAsset),
              ),
            ),
            const SizedBox(height: 12),
            if (currentEntry != null) ...[
              Text(t.portionLabel, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              _portionSelector(context, app, currentEntry),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.mealSummaryTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(mealSummary?.advice ?? t.detailAiEmpty, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text('${t.mealTotal}: ${mealSummary?.calorieRange ?? t.calorieUnknown}',
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (currentEntry?.result != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.detailWhyLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _ratioBar(t.protein, _ratioFromValue(currentEntry!.result!.macros['protein'] ?? ''), const Color(0xFF8AD7A4)),
                    const SizedBox(height: 10),
                    _ratioBar(t.carbs, _ratioFromValue(currentEntry.result!.macros['carbs'] ?? ''), const Color(0xFFF4C95D)),
                    const SizedBox(height: 10),
                    _ratioBar(t.fat, _ratioFromValue(currentEntry.result!.macros['fat'] ?? ''), const Color(0xFFF08A7C)),
                    const SizedBox(height: 10),
                    if ((currentEntry.result!.macros['sodium'] ?? '').isNotEmpty) ...[
                      _ratioBar(t.sodium, _ratioFromValue(currentEntry.result!.macros['sodium'] ?? ''), const Color(0xFF8AB4F8)),
                      const SizedBox(height: 10),
                    ],
                    Text('${t.calorieLabel}: ${currentEntry.result!.calorieRange}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
