import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../screens/meal_detail_screen.dart';
import '../screens/suggestions_screen.dart';
import '../screens/log_screen.dart';
import '../screens/summary_screen.dart';
import '../models/meal_entry.dart';
import '../design/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PetalData {
  _PetalData({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double ratio;
  final Color color;
}

class _PetalPainter extends CustomPainter {
  _PetalPainter(this.petals);

  final List<_PetalData> petals;

  @override
  void paint(Canvas canvas, Size size) {
    if (petals.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.12;
    final maxLen = size.width * 0.42;
    final width = size.width * 0.18;

    for (int i = 0; i < petals.length; i++) {
      final angle = (2 * pi * i / petals.length) - pi / 2;
      _drawPetal(canvas, center, angle, baseRadius, maxLen, width, petals[i].color.withOpacity(0.18), 1.0);
      _drawPetal(canvas, center, angle, baseRadius, maxLen, width, petals[i].color.withOpacity(0.65), petals[i].ratio);
    }
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double angle,
    double baseRadius,
    double maxLen,
    double width,
    Color color,
    double ratio,
  ) {
    final dir = Offset(cos(angle), sin(angle));
    final perp = Offset(-dir.dy, dir.dx);
    final len = baseRadius + (maxLen - baseRadius) * ratio.clamp(0.1, 1.0);
    final base = center + dir * baseRadius;
    final tip = center + dir * len;
    final left = base + perp * (width / 2);
    final right = base - perp * (width / 2);
    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, right.dx, right.dy)
      ..quadraticBezierTo(base.dx, base.dy, left.dx, left.dy)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment.topCenter,
        colors: [color.withOpacity(0.9), color.withOpacity(0.2)],
      ).createShader(Rect.fromPoints(base, tip));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PetalPainter oldDelegate) {
    return oldDelegate.petals != petals;
  }
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

  double _ratioFromValue(String value, AppLocalizations t) {
    final v = value.toLowerCase();
    if (v.contains(t.levelHigh.toLowerCase()) || v.contains('high')) return 0.85;
    if (v.contains(t.levelLow.toLowerCase()) || v.contains('low')) return 0.35;
    return 0.6;
  }

  String _levelLabelFromValue(String value, AppLocalizations t) {
    final v = value.toLowerCase();
    if (v.contains(t.levelHigh.toLowerCase()) || v.contains('high')) return t.levelHigh;
    if (v.contains(t.levelLow.toLowerCase()) || v.contains('low')) return t.levelLow;
    return t.levelMedium;
  }

  List<_PetalData> _buildPetals(MealEntry entry, AppLocalizations t) {
    final result = entry.result;
    if (result == null) return [];
    final map = <String, String?>{
      t.protein: result.macros['protein'],
      t.carbs: result.macros['carbs'],
      t.fat: result.macros['fat'],
      t.sodium: result.macros['sodium'],
    };
    final colors = <String, Color>{
      t.protein: const Color(0xFF8AD7A4),
      t.carbs: const Color(0xFFF4C95D),
      t.fat: const Color(0xFFF08A7C),
      t.sodium: const Color(0xFF8AB4F8),
    };
    final petals = <_PetalData>[];
    map.forEach((label, value) {
      if (value == null || value.isEmpty) return;
      petals.add(_PetalData(
        label: '$label ${_levelLabelFromValue(value, t)}',
        ratio: _ratioFromValue(value, t),
        color: colors[label] ?? const Color(0xFF8AB4F8),
      ));
    });
    return petals;
  }

  List<Widget> _petalLabels(List<_PetalData> petals, double size) {
    if (petals.isEmpty) return [];
    final center = size / 2;
    final radius = size * 0.46;
    return [
      for (int i = 0; i < petals.length; i++)
        Positioned(
          left: center + cos((2 * pi * i / petals.length) - pi / 2) * radius - 38,
          top: center + sin((2 * pi * i / petals.length) - pi / 2) * radius - 12,
          child: SizedBox(
            width: 76,
            child: Text(
              petals[i].label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ),
    ];
  }

  Widget _flowerSummary(MealEntry entry, AppLocalizations t) {
    final result = entry.result;
    final petals = _buildPetals(entry, t);
    final size = 250.0;
    final prefix = result?.source == 'mock' ? t.mockPrefix : null;
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (petals.isNotEmpty)
                CustomPaint(size: Size(size, size), painter: _PetalPainter(petals)),
              ..._petalLabels(petals, size),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.memory(entry.imageBytes, width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 6),
                    if (prefix != null)
                      Text(prefix, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                    Text(
                      result?.calorieRange ?? '--',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 8),
          Text(result.foodName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final latest = app.latestEntryForSelectedDate;
    final formatter = DateFormat('MM/dd HH:mm', Localizations.localeOf(context).toLanguageTag());
    final dateFormatter = DateFormat('yyyy/MM/dd', Localizations.localeOf(context).toLanguageTag());
    final selectedDate = app.selectedDate;
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
                          _flowerSummary(latest, t),
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
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SummaryScreen())),
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
