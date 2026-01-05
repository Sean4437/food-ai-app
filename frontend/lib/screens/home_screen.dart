import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../widgets/record_sheet.dart';
import '../widgets/plate_photo.dart';
import 'day_meals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openRecordSheet(AppState app) async {
    await showRecordSheet(context, app);
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _photoStack(List<MealEntry> group) {
    final main = group.first;
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    return Center(
      child: PlatePhoto(
        imageBytes: main.imageBytes,
        plateAsset: plateAsset,
        plateSize: 300,
        imageSize: 210,
        tilt: -0.08,
      ),
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

  Widget _mealPreviewCard(
    List<MealEntry> group,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
  ) {
    final mealTypeLabel = _mealTypeLabel(group.first.type, t);
    return SizedBox(
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 300, child: _photoStack(group)),
          const SizedBox(height: 8),
          Text(
            '$mealTypeLabel • ${_groupTimeLabel(group)}',
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  double _stackOffsetX(int count) {
    if (count >= 6) return 70;
    if (count >= 4) return 90;
    return 110;
  }

  Widget _mealStackForDate(
    DateTime date,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
    AppState app,
  ) {
    final groups = app.mealGroupsForDateAll(date);
    if (groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appTheme.card,
          borderRadius: BorderRadius.circular(appTheme.radiusCard),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Text(t.latestMealEmpty, style: const TextStyle(color: Colors.black54)),
      );
    }

    const plateSize = 300.0;
    const offsetY = 12.0;
    final offsetX = _stackOffsetX(groups.length);
    final stackHeight = plateSize + (groups.length - 1) * offsetY;
    final stackWidth = plateSize + (groups.length - 1) * offsetX;
    return SizedBox(
      height: stackHeight,
      width: stackWidth,
      child: Stack(
        children: [
          for (var i = groups.length - 1; i >= 0; i--)
            Positioned(
              top: i * offsetY,
              left: i * offsetX,
              child: _mealPreviewCard(groups[i], t, theme, appTheme),
            ),
        ],
      ),
    );
  }

  Widget _dateInfoCard(
    DateTime date,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
    AppState app,
  ) {
    final summary = app.buildDaySummary(date, t);
    final formatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.card,
        borderRadius: BorderRadius.circular(appTheme.radiusCard),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
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
          Text(formatter.format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(t.dailyCalorieRange, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            summary?.calorieRange ?? t.calorieUnknown,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Text(t.tomorrowAdviceTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(summary?.advice ?? t.nextMealHint, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entries = app.entries;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;
    final dates = entries
        .map((e) => DateTime(e.time.year, e.time.month, e.time.day))
        .toSet()
        .toList();
    dates.sort((a, b) => b.compareTo(a));
    final displayDates = dates.isEmpty ? [DateTime.now()] : dates;
    if (_pageIndex >= displayDates.length) {
      _pageIndex = 0;
    }
    final activeDate = displayDates.isEmpty ? DateTime.now() : displayDates[_pageIndex];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.greetingTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(t.streakLabel, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    _statusPill(t.aiSuggest, theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 14),
                if (displayDates.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appTheme.card,
                      borderRadius: BorderRadius.circular(appTheme.radiusCard),
                    ),
                    child: Text(t.latestMealEmpty, style: const TextStyle(color: Colors.black54)),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 420,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _pageIndex = index);
                            app.setSelectedDate(displayDates[index]);
                          },
                          itemCount: displayDates.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DayMealsScreen(date: displayDates[index])),
                            ),
                            child: _mealStackForDate(displayDates[index], t, theme, appTheme, app),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          displayDates.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _pageIndex == index ? 8 : 6,
                            height: _pageIndex == index ? 8 : 6,
                            decoration: BoxDecoration(
                              color: _pageIndex == index ? theme.colorScheme.primary : Colors.black26,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _dateInfoCard(activeDate, t, theme, appTheme, app),
                    ],
                  ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () => _openRecordSheet(app),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(t.captureTitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
