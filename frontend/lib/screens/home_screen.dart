import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../screens/meal_detail_screen.dart';
import '../screens/suggestions_screen.dart';
import '../screens/log_screen.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAdd(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source);
    if (xfile == null) return;
    final app = AppStateScope.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final note = _noteController.text.trim();
    await app.addEntry(xfile, locale, note: note.isEmpty ? null : note);
    if (mounted) {
      _noteController.clear();
    }
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final latest = app.latestEntry;
    final formatter = DateFormat('MM/dd HH:mm', Localizations.localeOf(context).toLanguageTag());
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>()!;

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
                      Text(t.captureTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(t.captureHint, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickAndAdd(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: Text(t.takePhoto),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(appTheme.radiusButton)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickAndAdd(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: Text(t.uploadPhoto),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(appTheme.radiusButton)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: t.optionalNoteLabel,
                          hintText: t.notePlaceholder,
                          prefixIcon: const Icon(Icons.edit_note),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(appTheme.radiusButton),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (latest != null)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailScreen(entry: latest))),
                    child: Container(
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
                          Text(t.latestMealTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(latest.image, height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 8),
                          Text(formatter.format(latest.time), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in _overallTags(latest, t))
                                _mealTag(tag, theme.colorScheme.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (latest == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appTheme.card,
                      borderRadius: BorderRadius.circular(appTheme.radiusCard),
                    ),
                    child: Text(t.latestMealEmpty, style: const TextStyle(color: Colors.black54)),
                  ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuggestionsScreen())),
                  child: Container(
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
                        Text(t.nextMealTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _mealTag(t.optionConvenienceTitle, const Color(0xFFF4C95D))),
                            const SizedBox(width: 8),
                            Expanded(child: _mealTag(t.optionBentoTitle, const Color(0xFF8AD7A4))),
                            const SizedBox(width: 8),
                            Expanded(child: _mealTag(t.optionLightTitle, theme.colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(t.homeNextMealHint, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LogScreen())),
                  child: Container(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
