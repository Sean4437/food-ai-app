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
  final PageController _pageController = PageController(viewportFraction: 0.86);
  int _pageIndex = 0;
  final Map<int, int> _groupSelectedIndex = {};
  bool _didApplyInitial = false;

  Widget _adviceRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
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

  Future<void> _editMealAdvice(BuildContext context, AppState app, List<MealEntry> group) async {
    if (group.isEmpty) return;
    final t = AppLocalizations.of(context)!;
    final current = app.mealAdviceForGroup(group, t);
    final selfCook = TextEditingController(text: current.selfCook);
    final convenience = TextEditingController(text: current.convenience);
    final bento = TextEditingController(text: current.bento);
    final other = TextEditingController(text: current.other);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editMealAdviceTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: selfCook, decoration: InputDecoration(labelText: t.nextSelfCookLabel)),
              TextField(controller: convenience, decoration: InputDecoration(labelText: t.nextConvenienceLabel)),
              TextField(controller: bento, decoration: InputDecoration(labelText: t.nextBentoLabel)),
              TextField(controller: other, decoration: InputDecoration(labelText: t.nextOtherLabel)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.save)),
        ],
      ),
    );
    if (result == true) {
      await app.updateMealAdvice(
        group.first.mealId ?? group.first.id,
        MealAdvice(
          selfCook: selfCook.text,
          convenience: convenience.text,
          bento: bento.text,
          other: other.text,
        ),
      );
    }
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
      return Text(t.detailAiEmpty, style: const TextStyle(color: Colors.black54));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item', style: const TextStyle(color: Colors.black54)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
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
                      Row(
                        children: [
                          Text(
                            _mealTypeLabel(currentGroup.first.type, t),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _groupTimeLabel(currentGroup),
                            style: const TextStyle(color: Colors.black45, fontSize: 12),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text('${t.mealTotal}: ${summary?.calorieRange ?? t.calorieUnknown}', style: const TextStyle(color: Colors.black54)),
                    if (currentGroup != null) ...[
                      const SizedBox(height: 14),
                      _thumbnailRow(currentGroup),
                    ],
                    if (currentGroup != null) ...[
                      const SizedBox(height: 14),
                      Text(t.dishSummaryLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _dishSummaryBlock(currentGroup, t),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(t.nextMealSectionTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (currentGroup != null)
                          IconButton(
                            onPressed: () => _editMealAdvice(context, app, currentGroup),
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                      ],
                    ),
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
            ],
          ],
        ),
      ),
    );
  }
}
