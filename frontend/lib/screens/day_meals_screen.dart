import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../design/text_styles.dart';
import '../widgets/plate_photo.dart';
import '../widgets/plate_polygon_stack.dart';
import 'meal_items_screen.dart';
import '../widgets/app_background.dart';

class DayMealsScreen extends StatefulWidget {
  const DayMealsScreen({
    super.key,
    required this.date,
    this.initialMealId,
  });

  final DateTime date;
  final String? initialMealId;

  @override
  State<DayMealsScreen> createState() => _DayMealsScreenState();
}

class _DayMealsScreenState extends State<DayMealsScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  int _pageIndex = 0;
  final Map<int, int> _groupSelectedIndex = {};
  bool _didApplyInitial = false;

  Widget _adviceRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: AppTextStyles.caption(context).copyWith(color: Colors.black54, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: AppTextStyles.caption(context).copyWith(color: Colors.black54))),
      ],
    );
  }

  String _groupTimeLabel(List<MealEntry> group) {
    final times = group.map((e) => e.time).toList()..sort();
    final start = times.first;
    final end = times.last;
    if (start == end) {
      return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    }
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _mealTypeLabel(MealType type, AppLocalizations t) {
    switch (type) {
      case MealType.breakfast:
        return t.breakfast;
      case MealType.brunch:
        return t.brunch;
      case MealType.lunch:
        return t.lunch;
      case MealType.afternoonTea:
        return t.afternoonTea;
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
    final displayGroup = List<MealEntry>.from(group)..sort((a, b) => a.time.compareTo(b.time));
    final selectedIndex = (_groupSelectedIndex[groupIndex] ?? 0).clamp(0, displayGroup.length - 1);
    return PlatePolygonStack(
      images: displayGroup.map((entry) => entry.imageBytes).toList(),
      plateAsset: plateAsset,
      selectedIndex: selectedIndex,
      onSelect: (index) => setState(() => _groupSelectedIndex[groupIndex] = index),
      onOpen: (index) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MealItemsScreen(
            group: displayGroup,
            initialIndex: index,
          ),
        ),
      ),
      maxPlateSize: 280,
      minPlateSize: 0,
    );
  }

  Widget _mealPreviewCard(BuildContext context, List<MealEntry> group, int groupIndex) {
    return SizedBox(
      height: 300,
      child: Center(child: _photoStack(group, groupIndex)),
    );
  }

  Widget _thumbnailRow(List<MealEntry> group) {
    final sorted = List<MealEntry>.from(group)..sort((a, b) => b.time.compareTo(a.time));
    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }
    final count = sorted.length;
    int columns;
    int rows;
    if (count <= 2) {
      columns = 1;
      rows = count;
    } else if (count <= 4) {
      columns = 2;
      rows = 2;
    } else if (count <= 9) {
      columns = 3;
      rows = 3;
    } else {
      columns = 4;
      rows = 3;
    }
    final maxItems = rows * columns;
    final items = sorted.take(maxItems).toList();
    final spacing = 6.0;
    final cellSize = columns == 4 ? 32.0 : (columns == 3 ? 40.0 : 48.0);
    final gridWidth = columns * cellSize + (columns - 1) * spacing;
    final gridHeight = rows * cellSize + (rows - 1) * spacing;
    return SizedBox(
      width: gridWidth,
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final entry = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(entry.imageBytes, fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  Widget _dishSummaryBlock(List<MealEntry> group, AppLocalizations t) {
    final items = <String>[];
    for (final entry in group) {
      final summary = entry.result?.dishSummary?.trim();
      if (summary != null && summary.isNotEmpty) {
        items.add(summary);
        continue;
      }
      final fallback = entry.overrideFoodName ?? entry.result?.foodName ?? t.unknownFood;
      if (fallback.isNotEmpty) items.add(fallback);
    }
    if (items.isEmpty) {
      return Text(t.detailAiEmpty, style: AppTextStyles.caption(context).copyWith(color: Colors.black54));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item', style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final theme = Theme.of(context);
    final groups = app.mealGroupsForDateAll(widget.date);
    if (widget.initialMealId != null && !_didApplyInitial && groups.isNotEmpty) {
      final initialIndex = groups.indexWhere(
        (group) => (group.first.mealId ?? group.first.id) == widget.initialMealId,
      );
      if (initialIndex >= 0) {
        _pageIndex = initialIndex;
        _didApplyInitial = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(initialIndex);
          }
        });
      }
    }
    if (_pageIndex >= groups.length) {
      _pageIndex = 0;
    }
    final currentGroup = groups.isNotEmpty ? groups[_pageIndex] : null;
    final summary = currentGroup == null ? null : app.buildMealSummary(currentGroup, t);
    final advice = currentGroup == null ? null : app.mealAdviceForGroup(currentGroup, t);
    final formatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    if (currentGroup != null) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        app.ensureMealAdviceForGroup(currentGroup, t, locale);
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = math.max(0.0, screenWidth - 32);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('${t.dayMealsTitle} • ${formatter.format(widget.date)}'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(t.noEntries, style: AppTextStyles.caption(context)),
                ),
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Container(
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _mealTypeLabel(currentGroup.first.type, t),
                                style: AppTextStyles.title2(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _groupTimeLabel(currentGroup),
                                style: AppTextStyles.caption(context).copyWith(color: Colors.black45),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  summary?.calorieRange ?? t.calorieUnknown,
                                  style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        if (currentGroup != null) ...[
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
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
                              Text(t.dishSummaryLabel, style: AppTextStyles.title2(context)),
                              const SizedBox(height: 6),
                              _dishSummaryBlock(currentGroup ?? const [], t),
                            ],
                          ),
                        ),
                      ),
                      if (currentGroup != null) ...[
                        const SizedBox(width: 12),
                        Container(
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
                          child: _thumbnailRow(currentGroup),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Container(
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
                        Text(t.nextMealSectionTitle, style: AppTextStyles.title2(context)),
                        const SizedBox(height: 6),
                        _adviceRow(t.nextSelfCookLabel, advice?.selfCook ?? t.nextSelfCookHint),
                        const SizedBox(height: 6),
                        _adviceRow(t.nextConvenienceLabel, advice?.convenience ?? t.nextConvenienceHint),
                        const SizedBox(height: 6),
                        _adviceRow(t.nextBentoLabel, advice?.bento ?? t.nextBentoHint),
                        const SizedBox(height: 6),
                        _adviceRow(t.nextOtherLabel, advice?.other ?? t.nextOtherHint),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}
