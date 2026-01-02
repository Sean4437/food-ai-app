import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../screens/meal_detail_screen.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';
import '../widgets/record_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _noteController = TextEditingController();
  final Map<String, TextEditingController> _noteControllers = {};
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _pageIndex = 0;

  @override
  void dispose() {
    _noteController.dispose();
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(MealEntry entry) {
    return _noteControllers.putIfAbsent(
      entry.id,
      () => TextEditingController(text: entry.note ?? ''),
    );
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

  Widget _mealTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  List<String> _overallTags(MealEntry entry, AppLocalizations t) {
    if (entry.result == null) return [];
    final result = entry.result!;
    final tags = <String>[];
    if (result.source == 'mock') tags.add(t.mockPrefix);
    final fat = result.macros['fat'] ?? '';
    final protein = result.macros['protein'] ?? '';
    final carbs = result.macros['carbs'] ?? '';
    if (fat.contains(t.levelHigh) || fat.toLowerCase().contains('high')) tags.add(t.tagOily);
    if (protein.contains(t.levelHigh) || protein.toLowerCase().contains('high')) tags.add(t.tagProteinOk);
    if (protein.contains(t.levelLow) || protein.toLowerCase().contains('low')) tags.add(t.tagProteinLow);
    if (carbs.contains(t.levelHigh) || carbs.toLowerCase().contains('high')) tags.add(t.tagCarbHigh);
    if (tags.isEmpty) tags.add(t.tagOk);
    return tags.take(3).toList();
  }

  Widget _mealAdviceCard(
    MealEntry entry,
    AppLocalizations t,
    ThemeData theme,
    AppTheme appTheme,
  ) {
    final formatter = DateFormat('MM/dd HH:mm', Localizations.localeOf(context).toLanguageTag());
    final prefix = entry.result?.source == 'mock' ? '${t.mockPrefix} ' : '';
    final noteController = _controllerFor(entry);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: entry))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appTheme.card,
          borderRadius: BorderRadius.circular(appTheme.radiusCard),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(entry.imageBytes, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            Text(formatter.format(entry.time), style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              '${prefix}${entry.overrideFoodName ?? entry.result?.foodName ?? t.latestMealTitle}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _overallTags(entry, t)) _mealTag(tag, theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(t.optionalNoteLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: t.notePlaceholder,
                filled: true,
                fillColor: const Color(0xFFF7F8FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  final app = AppStateScope.of(context);
                  final locale = Localizations.localeOf(context).toLanguageTag();
                  app.updateEntryNote(entry, noteController.text.trim(), locale);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(t.reanalyzeLabel),
              ),
            ),
            const SizedBox(height: 6),
            Divider(color: Colors.black.withOpacity(0.08)),
            const SizedBox(height: 6),
            Text(t.nextMealTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              entry.error != null
                  ? entry.error!
                  : '${prefix}${entry.result?.suggestion ?? t.nextMealHint}',
              style: TextStyle(color: entry.error != null ? Colors.red : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final entries = app.entriesForSelectedDate;
    final dateFormatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    final selectedDate = app.selectedDate;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;

    final ids = entries.map((e) => e.id).toSet();
    final remove = _noteControllers.keys.where((key) => !ids.contains(key)).toList();
    for (final key in remove) {
      _noteControllers[key]?.dispose();
      _noteControllers.remove(key);
    }

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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => app.shiftSelectedDate(-1),
                    ),
                    Expanded(
                      child: Text(
                        dateFormatter.format(selectedDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => app.shiftSelectedDate(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: appTheme.card,
                    borderRadius: BorderRadius.circular(appTheme.radiusCard),
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
                      Text(t.summaryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(app.todaySummary(t), style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (entries.isEmpty)
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
                          onPageChanged: (index) => setState(() => _pageIndex = index),
                          itemCount: entries.length,
                          itemBuilder: (context, index) => _mealAdviceCard(entries[index], t, theme, appTheme),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          entries.length,
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
