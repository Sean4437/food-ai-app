import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../widgets/plate_photo.dart';
import 'meal_items_screen.dart';

class DayMealsScreen extends StatefulWidget {
  const DayMealsScreen({super.key, required this.date});

  final DateTime date;

  @override
  State<DayMealsScreen> createState() => _DayMealsScreenState();
}

class _DayMealsScreenState extends State<DayMealsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.86);
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _mealTypeLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.lunch:
        return t.lunch;
      case MealType.dinner:
        return t.dinner;
      case MealType.lateSnack:
        return t.lateSnack;
      case MealType.other:
        return t.other;
    }
  }

  Widget _photoStack(List<MealEntry> group) {
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = group.length;
        if (count == 0) return const SizedBox.shrink();
        const maxPlate = 280.0;
        const minPlate = 200.0;
        const minSpacing = 30.0;
        const desiredSpacing = 90.0;
        const offsetY = 8.0;
        final maxWidth = constraints.maxWidth;
        var plateSize = maxPlate;
        var offsetX = desiredSpacing;
        if (count > 1) {
          final needed = plateSize + (count - 1) * offsetX;
          if (needed > maxWidth) {
            offsetX = ((maxWidth - plateSize) / (count - 1)).clamp(minSpacing, desiredSpacing);
            if (plateSize + (count - 1) * offsetX > maxWidth) {
              plateSize = (maxWidth - (count - 1) * minSpacing).clamp(minPlate, maxPlate);
              offsetX = ((maxWidth - plateSize) / (count - 1)).clamp(minSpacing, desiredSpacing);
            }
          }
        } else {
          offsetX = 0;
        }
        final imageSize = plateSize * 0.7;
        final stackHeight = plateSize + (count - 1) * offsetY;
        final stackWidth = plateSize + (count - 1) * offsetX;
        return SizedBox(
          height: stackHeight,
          width: stackWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < count; i++)
                Positioned(
                  left: i * offsetX,
                  top: i * offsetY,
                  child: PlatePhoto(
                    imageBytes: group[i].imageBytes,
                    plateAsset: plateAsset,
                    plateSize: plateSize,
                    imageSize: imageSize,
                    tilt: -0.08,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _mealPreviewCard(BuildContext context, List<MealEntry> group) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MealItemsScreen(group: group)),
      ),
      child: SizedBox(
        height: 300,
        child: Center(child: _photoStack(group)),
      ),
    );
  }

  Widget _thumbnailRow(List<MealEntry> group) {
    final sorted = List<MealEntry>.from(group)..sort((a, b) => b.time.compareTo(a.time));
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final entry = sorted[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(entry.imageBytes, width: 54, height: 54, fit: BoxFit.cover),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: sorted.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final groups = app.mealGroupsForDateAll(widget.date);
    if (_pageIndex >= groups.length) {
      _pageIndex = 0;
    }
    final currentGroup = groups.isNotEmpty ? groups[_pageIndex] : null;
    final summary = currentGroup == null ? null : app.buildMealSummary(currentGroup, t);
    final formatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());

    return Scaffold(
      appBar: AppBar(
        title: Text('${t.dayMealsTitle} • ${formatter.format(widget.date)}'),
        backgroundColor: const Color(0xFFF3F5FB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (groups.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(t.noEntries),
              )
            else ...[
              SizedBox(
                height: 340,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemCount: groups.length,
                  itemBuilder: (context, index) => _mealPreviewCard(context, groups[index]),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentGroup != null)
                      Text(
                        _mealTypeLabel(currentGroup.first.type, t),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    const SizedBox(height: 8),
                    Text('${t.mealTotal}: ${summary?.calorieRange ?? t.calorieUnknown}', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    Text(t.nextMealTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(summary?.advice ?? t.nextMealHint, style: const TextStyle(color: Colors.black54)),
                    if (currentGroup != null) ...[
                      const SizedBox(height: 14),
                      _thumbnailRow(currentGroup),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
