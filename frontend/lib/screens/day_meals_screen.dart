import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../widgets/plate_photo.dart';
import '../widgets/plate_polygon_stack.dart';
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
  final Map<int, int> _groupSelectedIndex = {};

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

  Widget _photoStack(List<MealEntry> group, int groupIndex) {
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final selectedIndex = (_groupSelectedIndex[groupIndex] ?? 0).clamp(0, group.length - 1);
    return PlatePolygonStack(
      images: group.map((entry) => entry.imageBytes).toList(),
      plateAsset: plateAsset,
      selectedIndex: selectedIndex,
      onSelect: (index) => setState(() => _groupSelectedIndex[groupIndex] = index),
      onOpen: (_) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MealItemsScreen(group: group)),
      ),
      maxPlateSize: 280,
      minPlateSize: 200,
    );
  }

  Widget _mealPreviewCard(BuildContext context, List<MealEntry> group, int groupIndex) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    return SizedBox(
      height: 300,
      child: Center(child: _photoStack(group, groupIndex)),
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
                height: 400,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemCount: groups.length,
                  itemBuilder: (context, index) => Center(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _mealPreviewCard(context, groups[index], index),
                      ),
                    ),
                  ),
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
                    if (currentGroup != null) ...[
                      const SizedBox(height: 14),
                      _thumbnailRow(currentGroup),
                    ],
                    const SizedBox(height: 12),
                    Text(t.nextMealTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(summary?.advice ?? t.nextMealHint, style: const TextStyle(color: Colors.black54)),
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
