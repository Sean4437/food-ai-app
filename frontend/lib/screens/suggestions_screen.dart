import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import '../state/app_state.dart';
import '../models/analysis_result.dart';
import '../models/custom_food.dart';
import '../models/meal_entry.dart';
import '../widgets/plate_photo.dart';
import '../widgets/nutrition_chart.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  QuickCaptureAnalysis? _analysis;
  MealAdvice? _instantAdvice;
  Uint8List? _previewBytes;
  bool _loading = false;
  String? _error;
  bool _showSaveActions = false;
  bool _hideFloatingCard = false;
  MealEntry? _savedEntry;
  int _portionPercent = 100;
  String? _containerType;
  String? _containerSize;
  String _referenceObject = 'none';
  final TextEditingController _referenceLengthController = TextEditingController();
  String? _overrideCalorieRange;
  String? _displayCalorieRange;
  late final AnimationController _scanController;
  double _progressValue = 0;
  int _statusIndex = 0;
  bool _finishingProgress = false;
  Timer? _progressTimer;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCaptureFromCamera());
  }

  
  @override
  void dispose() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _scanController.dispose();
    _referenceLengthController.dispose();
    super.dispose();
  }

  Future<void> _startCapture({required ImageSource source}) async {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _analysis = null;
      _instantAdvice = null;
      _previewBytes = null;
      _showSaveActions = false;
      _savedEntry = null;
      _portionPercent = 100;
      _containerType = null;
      _containerSize = null;
      _referenceObject = 'none';
      _referenceLengthController.text = '';
      _overrideCalorieRange = null;
      _displayCalorieRange = null;
    });
    final file = await _picker.pickImage(source: source);
    if (!mounted) return;
    if (file == null) return;
    final preview = await file.readAsBytes();
    setState(() {
      _loading = true;
      _error = null;
      _previewBytes = preview;
    });
    _startSmartProgress();
    final app = AppStateScope.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final historyContext = app.buildAiContext();
    try {
      final analysis = await app.analyzeQuickCapture(
        file,
        locale,
        historyContext: historyContext.isEmpty ? null : historyContext,
        referenceObject: _referenceObject == 'none' || _referenceObject == 'manual' ? null : _referenceObject,
        referenceLengthCm: _referenceObject == 'manual' ? _parsedReferenceLength() : null,
      );
      if (!mounted) return;
      if (analysis == null) {
        setState(() {
          _error = AppLocalizations.of(context)!.analyzeFailed;
          _loading = false;
          _previewBytes = null;
        });
        return;
      }
      _analysis = analysis;
      _savedEntry = null;
      _applyAnalysisDefaults(analysis.result);
      _hideFloatingCard = false;
      _instantAdvice = null;
      _previewBytes = null;
      _showSaveActions = analysis.result.isFood != false;
      _completeSmartProgress(() {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      });
    } catch (err) {
      if (!mounted) return;
      _stopSmartProgress();
      setState(() {
        _error = err.toString();
        _loading = false;
        _previewBytes = null;
      });
    }
  }

  Future<void> _startCaptureFromCamera() async {
    await _startCapture(source: ImageSource.camera);
  }

  Future<void> _startCaptureFromGallery() async {
    await _startCapture(source: ImageSource.gallery);
  }

  Future<void> _requestNowAdvice() async {
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
      _instantAdvice = null;
      _previewBytes = null;
      _showSaveActions = false;
      _savedEntry = null;
    });
    _startSmartProgress();
    try {
      final advice = await app.suggestNowMealAdvice(t, locale);
      if (!mounted) return;
      _instantAdvice = advice;
      _previewBytes = null;
      _completeSmartProgress(() {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      });
    } catch (err) {
      if (!mounted) return;
      _stopSmartProgress();
      setState(() {
        _error = err.toString();
        _loading = false;
        _previewBytes = null;
      });
    }
  }

  Future<void> _saveIfNeeded() async {
    if (_analysis == null) return;
    if (_analysis!.result.isFood == false) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final saved = await app.saveQuickCapture(
      _analysis!,
      portionPercent: _portionPercent,
      containerType: _containerType,
      containerSize: _containerSize,
      overrideCalorieRange: _overrideCalorieRange,
    );
    if (!mounted) return;
    setState(() {
      _showSaveActions = false;
      _savedEntry = saved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.logSuccess)),
    );
  }

  Future<void> _editFoodName() async {
    if (_analysis == null) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final controller = TextEditingController(text: _analysis!.result.foodName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editFoodName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.foodNameLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(t.save)),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _instantAdvice = null;
    _startSmartProgress();
    final historyContext = app.buildAiContext();
    try {
      final updated = await app.reanalyzeQuickCapture(
        _analysis!,
        locale,
        historyContext: historyContext.isEmpty ? null : historyContext,
        foodName: result.trim(),
        containerType: _containerType,
        containerSize: _containerSize,
        referenceObject: _referenceObject == 'none' || _referenceObject == 'manual' ? null : _referenceObject,
        referenceLengthCm: _referenceObject == 'manual' ? _parsedReferenceLength() : null,
      );
      if (!mounted) return;
      _analysis = updated;
      _savedEntry = null;
      _applyAnalysisDefaults(updated.result, keepUserSelections: true);
      _hideFloatingCard = false;
      _instantAdvice = null;
      _previewBytes = null;
      _showSaveActions = updated.result.isFood != false;
      _completeSmartProgress(() {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      });
    } catch (err) {
      if (!mounted) return;
      _stopSmartProgress();
      setState(() {
        _error = err.toString();
        _loading = false;
        _previewBytes = null;
      });
    }
  }

  Future<void> _useCustomFood() async {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    if (app.customFoods.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.customEmpty)),
      );
      return;
    }
    final selected = await showModalBottomSheet<CustomFood>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t.customSelectTitle, style: AppTextStyles.title2(context)),
            const SizedBox(height: 12),
            for (final food in app.customFoods)
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(food.imageBytes, width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text(food.name, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(food.summary, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                onTap: () => Navigator.of(context).pop(food),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

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
            final dateLabel = '${pickedDate.year}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}';
            final timeLabel = pickedTime.format(context);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.customConfirmTitle, style: AppTextStyles.title2(context)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('${t.customConfirmDate}:', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
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
                      Text('${t.customConfirmTime}:', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
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
                      Text('${t.customConfirmMealType}:', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final result = await _showMealTypePicker(app, t, pickedMealType);
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
    await app.saveCustomFoodUsage(selected, dateTime, pickedMealType);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.customUseSaved)),
    );
  }

  Future<MealType?> _showMealTypePicker(AppState app, AppLocalizations t, MealType current) async {
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
                trailing: option == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _parseAdviceSections(String suggestion) {
    final sections = <String, String>{};
    final lines = suggestion
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final line in lines) {
      final normalized = _normalizeAdviceLine(line);
      final lower = normalized.toLowerCase();
      if (_startsWithAny(normalized, ['搭配', '可以吃', '建議吃', '適合吃', '可吃', '可以怎麼吃', '可以喝', '建議喝', '適合喝', '可喝', '可以怎麼喝']) ||
          lower.startsWith('can eat') ||
          lower.startsWith('can drink')) {
        sections['can'] = _cleanAdviceValue(_splitAdviceValue(normalized), 'can');
        continue;
      }
      if (_startsWithAny(normalized, ['不建議', '不建議吃', '避免', '不推薦', '不建議喝', '少吃', '少喝', '避免吃', '避免喝']) ||
          lower.startsWith('avoid')) {
        sections['avoid'] = _cleanAdviceValue(_splitAdviceValue(normalized), 'avoid');
        continue;
      }
      if (_startsWithAny(normalized, ['建議份量', '建議份量上限', '份量上限', '上限', '份量建議']) ||
          lower.startsWith('portion') ||
          lower.startsWith('limit')) {
        sections['limit'] = _cleanAdviceValue(_splitAdviceValue(normalized), 'limit');
        continue;
      }
    }
    return sections;
  }

  bool _startsWithAny(String value, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) return true;
    }
    return false;
  }

  String _normalizeAdviceLine(String line) {
    var cleaned = line.trimLeft();
    cleaned = cleaned.replaceFirst(RegExp(r'^[•\-\–—*]+\s*'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^(\d+|[一二三四五六七八九十]+)[、.)]\s*'), '');
    return cleaned.trim();
  }

  String _splitAdviceValue(String line) {
    for (final separator in ['：', ':', ' - ', '-', '—', '–', '－']) {
      if (line.contains(separator)) {
        return line.split(separator).last.trim();
      }
    }
    return line.trim();
  }

  Map<String, String> _fallbackAdviceSections(String suggestion) {
    final cleaned = suggestion.trim();
    if (cleaned.isEmpty) return {};
    List<String> parts = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      parts = cleaned
          .split(RegExp(r'[。；;]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (parts.length < 2) {
      parts = cleaned
          .split(RegExp(r'[，、]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (parts.isEmpty) return {};
    return {
      'can': parts.isNotEmpty ? _cleanAdviceValue(parts[0], 'can') : '',
      'avoid': parts.length > 1 ? _cleanAdviceValue(parts[1], 'avoid') : '',
      'limit': parts.length > 2 ? _cleanAdviceValue(parts[2], 'limit') : '',
    };
  }

  String _stripAdviceLabel(String text) {
    var result = _normalizeAdviceLine(text);
    const prefixes = [
      '搭配',
      '可以吃',
      '建議吃',
      '適合吃',
      '可吃',
      '可以怎麼吃',
      '可以喝',
      '建議喝',
      '適合喝',
      '可喝',
      '可以怎麼喝',
      '不建議',
      '不建議吃',
      '避免',
      '不推薦',
      '不建議喝',
      '少吃',
      '少喝',
      '避免吃',
      '避免喝',
      '建議份量',
      '建議份量上限',
      '份量上限',
      '上限',
      '份量建議',
      'can eat',
      'good choices',
      'can drink',
      'avoid',
      'avoid drinking',
      'portion limit',
      'suggested portion',
      'portion',
      'limit',
    ];
    for (final prefix in prefixes) {
      if (result.toLowerCase().startsWith(prefix)) {
        result = result.substring(prefix.length).trim();
        break;
      }
    }
    result = result.replaceFirst(RegExp(r'^[:：—–\-]+'), '').trim();
    return result;
  }

  String _cleanAdviceValue(String value, String key) {
    var cleaned = _stripAdviceLabel(value);
    cleaned = cleaned.replaceFirst(RegExp(r'^[、，,;；]+'), '').trim();
    if (key == 'can') {
      cleaned = cleaned.replaceFirst(
        RegExp(r'^(可以|建議|適合)?\s*(搭配|配|加點|加入|多搭配|多加)\s*'),
        '',
      );
    }
    if (key == 'avoid') {
      cleaned = cleaned.replaceFirst(RegExp(r'^(避免|不建議|不推薦|少|盡量少|盡量避免)\s*'), '');
    }
    if (key == 'limit') {
      cleaned = cleaned.replaceFirst(RegExp(r'^(份量|份量上限|建議份量|上限|控制在)\s*'), '');
    }
    return cleaned.trim();
  }

  Widget _buildScanOverlay(double size) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            final value = _scanController.value;
            return Stack(
              children: [
                Container(color: Colors.white.withOpacity(0.02)),
                CustomPaint(
                  painter: _ProgressArcPainter(
                    progress: _progressValue,
                    rotation: value,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  size: Size(size, size),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _startSmartProgress() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _finishingProgress = false;
    setState(() {
      _progressValue = 0;
      _statusIndex = 0;
    });
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted || !_loading) return;
      setState(() {
        _statusIndex = (_statusIndex + 1) % 3;
      });
    });
    _animateProgress(0.6, const Duration(milliseconds: 1000), () {
      _animateProgress(0.9, const Duration(milliseconds: 4000), () {
        _animateProgress(0.95, const Duration(milliseconds: 8000));
      });
    });
  }

  void _stopSmartProgress() {
    _progressTimer?.cancel();
    _statusTimer?.cancel();
    _finishingProgress = false;
  }

  void _completeSmartProgress(VoidCallback onDone) {
    _finishingProgress = true;
    _progressTimer?.cancel();
    _animateProgress(1.0, const Duration(milliseconds: 400), () {
      _statusTimer?.cancel();
      onDone();
    });
  }

  void _animateProgress(double target, Duration duration, [VoidCallback? onComplete]) {
    _progressTimer?.cancel();
    final start = _progressValue;
    final startTime = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_loading && !_finishingProgress) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final t = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      final eased = 1 - math.pow(1 - t, 2).toDouble();
      final nextValue = start + (target - start) * eased;
      if (mounted) {
        setState(() {
          _progressValue = nextValue;
        });
      }
      if (t >= 1) {
        timer.cancel();
        if (onComplete != null) {
          onComplete();
        }
      }
    });
  }

  Widget _buildAdviceCard(AppLocalizations t) {
    if (_analysis == null) {
      return Text(t.suggestInstantMissing, style: AppTextStyles.caption(context).copyWith(color: Colors.black54));
    }
    final suggestion = _analysis!.result.suggestion.trim();
    if (suggestion.isEmpty) {
      return Text(t.suggestInstantMissing, style: AppTextStyles.caption(context).copyWith(color: Colors.black54));
    }
    var sections = _parseAdviceSections(suggestion);
    if (sections.length < 3) {
      final fallback = _fallbackAdviceSections(suggestion);
      sections = {
        ...fallback,
        ...sections,
      };
    }
    final canText = (sections['can'] ?? '').trim();
    final avoidText = (sections['avoid'] ?? '').trim();
    final limitText = (sections['limit'] ?? '').trim();
    final isDrink = _analysis?.result.isBeverage == true;
    final canLabel = isDrink ? t.suggestInstantCanDrink : t.suggestInstantCanEat;
    final avoidLabel = isDrink ? t.suggestInstantAvoidDrink : t.suggestInstantAvoid;
    final limitLabel = isDrink ? t.suggestInstantDrinkLimit : t.suggestInstantLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _adviceRow(canLabel, canText.isEmpty ? '-' : canText),
        const SizedBox(height: 8),
        _adviceRow(avoidLabel, avoidText.isEmpty ? '-' : avoidText),
        const SizedBox(height: 8),
        _adviceRow(limitLabel, limitText.isEmpty ? '-' : limitText),
      ],
    );
  }

  String _labelWithColon(String title) {
    final trimmed = title.trimRight();
    if (trimmed.endsWith('：') || trimmed.endsWith(':')) {
      return trimmed;
    }
    return '$trimmed：';
  }

  Widget _adviceRow(String title, String? value) {
    final displayTitle = _labelWithColon(title);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayTitle, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value ?? '-', style: AppTextStyles.caption(context).copyWith(color: Colors.black87, height: 1.4)),
        ),
      ],
    );
  }

  List<String> _normalizeContainerSelection(String? type, String? size) {
    final rawType = (type ?? '').trim().toLowerCase();
    final rawSize = (size ?? '').trim().toLowerCase();
    const validTypes = {'bowl', 'plate', 'box', 'cup', 'unknown'};
    const validSizes = {'small', 'medium', 'large', 'none'};
    var nextType = validTypes.contains(rawType) ? rawType : 'unknown';
    var nextSize = validSizes.contains(rawSize) ? rawSize : 'none';
    if (nextSize == 'none') {
      nextSize = 'medium';
    }
    return [nextType, nextSize];
  }

  void _applyAnalysisDefaults(AnalysisResult result, {bool keepUserSelections = false}) {
    final normalized = _normalizeContainerSelection(result.containerGuessType, result.containerGuessSize);
    if (!keepUserSelections) {
      _portionPercent = 100;
      _containerType = normalized[0];
      _containerSize = normalized[1];
    } else {
      _portionPercent = _portionPercent.clamp(10, 200);
      _containerType ??= normalized[0];
      _containerSize ??= normalized[1];
    }
    _overrideCalorieRange = null;
    _displayCalorieRange = _scaledCalorieRangeText(
      result.calorieRange,
      _portionPercent,
      containerType: _containerType,
      containerSize: _containerSize,
    );
  }

  void _updatePortionPercent(int value) {
    final next = value.clamp(10, 200).toInt();
    setState(() {
      _portionPercent = next;
      _displayCalorieRange = _scaledCalorieRangeText(
        _overrideCalorieRange ?? _analysis?.result.calorieRange ?? '',
        _portionPercent,
        containerType: _containerType,
        containerSize: _containerSize,
      );
    });
    if (_savedEntry != null) {
      final app = AppStateScope.of(context);
      app.updateEntryPortionPercent(_savedEntry!, next);
    }
  }

  void _updateContainerType(String value) {
    final normalized = _normalizeContainerSelection(value, _containerSize);
    setState(() {
      _containerType = normalized[0];
      _containerSize = normalized[1];
      _displayCalorieRange = _scaledCalorieRangeText(
        _overrideCalorieRange ?? _analysis?.result.calorieRange ?? '',
        _portionPercent,
        containerType: _containerType,
        containerSize: _containerSize,
      );
    });
    if (_savedEntry != null) {
      final app = AppStateScope.of(context);
      app.updateEntryContainer(_savedEntry!, _containerType, _containerSize);
    }
  }

  void _updateContainerSize(String value) {
    final normalized = _normalizeContainerSelection(_containerType, value);
    setState(() {
      _containerType = normalized[0];
      _containerSize = normalized[1];
      _displayCalorieRange = _scaledCalorieRangeText(
        _overrideCalorieRange ?? _analysis?.result.calorieRange ?? '',
        _portionPercent,
        containerType: _containerType,
        containerSize: _containerSize,
      );
    });
    if (_savedEntry != null) {
      final app = AppStateScope.of(context);
      app.updateEntryContainer(_savedEntry!, _containerType, _containerSize);
    }
  }

  double? _parsedReferenceLength() {
    final raw = _referenceLengthController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> _updateReferenceObject(String value) async {
    if (value == _referenceObject) return;
    setState(() {
      _referenceObject = value;
      if (value != 'manual') {
        _referenceLengthController.text = '';
      }
    });
    if (_analysis == null) return;
    if (value == 'manual') return;
    await _reanalyzeWithAdjustments();
  }

  Future<void> _updateReferenceLength() async {
    if (_analysis == null) return;
    final length = _parsedReferenceLength();
    if (length == null) return;
    await _reanalyzeWithAdjustments();
  }

  Future<void> _editCalorieRange() async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _overrideCalorieRange ?? _analysis?.result.calorieRange ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editCalorieTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.editCalorieHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(t.editCalorieClear),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    final next = result.trim();
    setState(() {
      _overrideCalorieRange = next.isEmpty ? null : next;
      _displayCalorieRange = _scaledCalorieRangeText(
        _overrideCalorieRange ?? _analysis?.result.calorieRange ?? '',
        _portionPercent,
        containerType: _containerType,
        containerSize: _containerSize,
      );
    });
    if (_savedEntry != null) {
      final app = AppStateScope.of(context);
      app.updateEntryCalorieOverride(_savedEntry!, _overrideCalorieRange);
    }
  }

  Widget _buildChipGroup({
    required List<MapEntry<String, String>> options,
    required String value,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.key),
            selected: option.value == value,
            onSelected: (_) => onSelected(option.value),
          ),
      ],
    );
  }

  Widget _buildIconChipGroup({
    required List<_IconChipOption> options,
    required String value,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: option.showLabel
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconChipGlyph(option),
                      const SizedBox(height: 2),
                      Text(option.label),
                    ],
                  )
                : Semantics(
                    label: option.label,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconChipGlyph(option),
                      ],
                    ),
                  ),
            selected: option.value == value,
            onSelected: (_) => onSelected(option.value),
            labelStyle: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          ),
      ],
    );
  }

  Widget _iconChipGlyph(_IconChipOption option) {
    if (option.emoji != null && option.emoji!.isNotEmpty) {
      return Text(
        option.emoji!,
        style: const TextStyle(fontSize: 18, height: 1),
      );
    }
    if (option.icon != null) {
      return Icon(option.icon, size: 20);
    }
    return const SizedBox(height: 20, width: 20);
  }

  Widget _buildPortionContainerSection(AppLocalizations t) {
    final theme = Theme.of(context);
    final normalized = _normalizeContainerSelection(_containerType, _containerSize);
    final currentType = normalized[0];
    final currentSize = normalized[1];
    final typeOptions = <_IconChipOption>[
      _IconChipOption(emoji: '🍜', value: 'bowl', label: t.containerTypeBowl, showLabel: false),
      _IconChipOption(emoji: '🍽️', value: 'plate', label: t.containerTypePlate, showLabel: false),
      _IconChipOption(emoji: '🍱', value: 'box', label: t.containerTypeBox, showLabel: false),
      _IconChipOption(emoji: '🥤', value: 'cup', label: t.containerTypeCup, showLabel: false),
      _IconChipOption(emoji: '❓', value: 'unknown', label: t.containerTypeUnknown, showLabel: false),
    ];
    final sizeOptions = <MapEntry<String, String>>[
      MapEntry(t.containerSizeSmall, 'small'),
      MapEntry(t.containerSizeMedium, 'medium'),
      MapEntry(t.containerSizeLarge, 'large'),
    ];
    final referenceOptions = <MapEntry<String, String>>[
      MapEntry(t.referenceObjectNone, 'none'),
      MapEntry(t.referenceObjectCard, 'card'),
      MapEntry(t.referenceObjectCoin10, 'coin_10'),
      MapEntry(t.referenceObjectCoin5, 'coin_5'),
      MapEntry(t.referenceObjectManual, 'manual'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.portionLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('${_portionPercent}%', style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.2),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor: theme.colorScheme.primary.withOpacity(0.12),
                ),
                child: Slider(
                  value: _portionPercent.toDouble(),
                  min: 10,
                  max: 200,
                  divisions: 19,
                  label: '${_portionPercent}%',
                  onChanged: (value) => _updatePortionPercent(value.round()),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
        Text(t.containerTypeLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _buildIconChipGroup(options: typeOptions, value: currentType, onSelected: _updateContainerType),
        const SizedBox(height: 12),
        Text(t.containerSizeLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _buildChipGroup(options: sizeOptions, value: currentSize, onSelected: _updateContainerSize),
        const SizedBox(height: 12),
        _buildReferenceAdjustSection(t, referenceOptions),
      ],
    );
  }

  Widget _buildReferenceAdjustSection(
    AppLocalizations t,
    List<MapEntry<String, String>> referenceOptions,
  ) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 6),
      title: Text(
        t.referenceObjectLabel,
        style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        t.referenceLengthHint,
        style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _buildChipGroup(options: referenceOptions, value: _referenceObject, onSelected: _updateReferenceObject),
        ),
        if (_referenceObject == 'manual') ...[
          const SizedBox(height: 10),
          Text(t.referenceLengthLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _referenceLengthController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: t.referenceLengthHint),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _updateReferenceLength,
                child: Text(t.referenceLengthApply),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _scaledCalorieRangeText(
    String raw,
    int portionPercent, {
    String? containerType,
    String? containerSize,
  }) {
    final percent = portionPercent.clamp(10, 200) / 100.0;
    final sizeFactor = _containerSizeFactorFor(containerSize ?? _containerSize);
    final typeFactor = _containerTypeFactorFor(containerType ?? _containerType);
    final factor = percent * sizeFactor * typeFactor;
    final hasKcal = raw.toLowerCase().contains('kcal');
    final normalized = raw
        .replaceAll('\uFF5E', '-') // fullwidth tilde
        .replaceAll('~', '-')
        .replaceAll('\u2013', '-') // en dash
        .replaceAll('\u2014', '-'); // em dash
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(normalized);
    if (match != null) {
      final low = int.tryParse(match.group(1) ?? '');
      final high = int.tryParse(match.group(2) ?? '');
      if (low != null && high != null) {
        final scaledLow = (low * factor).round();
        final scaledHigh = (high * factor).round();
        return hasKcal ? '$scaledLow-$scaledHigh kcal' : '$scaledLow-$scaledHigh';
      }
    }
    final single = RegExp(r'(\d+)').firstMatch(normalized);
    if (single != null) {
      final value = int.tryParse(single.group(1) ?? '');
      if (value != null) {
        final scaled = (value * factor).round();
        return hasKcal ? '$scaled kcal' : '$scaled';
      }
    }
    return raw;
  }

  String _macroDisplayValue(String key, double value, int portionPercent) {
    final percent = portionPercent.clamp(10, 200) / 100.0;
    final sizeFactor = _containerSizeFactor();
    final scaled = value * percent * sizeFactor * _containerTypeFactor();
    if (key == 'sodium') {
      return '${scaled.round()}mg';
    }
    return '${scaled.round()}g';
  }

  double _containerSizeFactor() {
    final size = (_containerSize ?? '').toLowerCase();
    switch (size) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      case 'medium':
      default:
        return 1.0;
    }
  }

  double _containerTypeFactor() {
    final type = (_containerType ?? '').toLowerCase();
    switch (type) {
      case 'plate':
        return 1.1;
      case 'box':
        return 1.05;
      case 'cup':
        return 0.9;
      case 'bowl':
      case 'unknown':
      default:
        return 1.0;
    }
  }

  double _containerSizeFactorFor(String? size) {
    final value = (size ?? '').toLowerCase();
    switch (value) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      case 'medium':
      default:
        return 1.0;
    }
  }

  double _containerTypeFactorFor(String? type) {
    final value = (type ?? '').toLowerCase();
    switch (value) {
      case 'plate':
        return 1.1;
      case 'box':
        return 1.05;
      case 'cup':
        return 0.9;
      case 'bowl':
      case 'unknown':
      default:
        return 1.0;
    }
  }

  double? _rangeMidValue(String? rangeText) {
    if (rangeText == null || rangeText.trim().isEmpty) return null;
    final normalized = rangeText
        .replaceAll('\uFF5E', '-')
        .replaceAll('~', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-');
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(normalized);
    if (match != null) {
      final low = double.tryParse(match.group(1) ?? '');
      final high = double.tryParse(match.group(2) ?? '');
      if (low != null && high != null) {
        return (low + high) / 2;
      }
    }
    final single = RegExp(r'(\d+)').firstMatch(normalized);
    if (single != null) {
      return double.tryParse(single.group(1) ?? '');
    }
    return null;
  }

  double? _recentMealAverage(AppState app, {MealType? mealType}) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final groups = <String, List<MealEntry>>{};
    for (final entry in app.entries) {
      if (entry.time.isBefore(cutoff)) continue;
      if (mealType != null && entry.type != mealType) continue;
      final key = entry.mealId ?? entry.id;
      groups.putIfAbsent(key, () => []).add(entry);
    }
    if (groups.isEmpty) return null;
    final mealTotals = <double>[];
    for (final group in groups.values) {
      double total = 0;
      for (final entry in group) {
        final baseRange = entry.overrideCalorieRange ?? entry.labelResult?.calorieRange ?? entry.result?.calorieRange;
        final mid = _rangeMidValue(baseRange);
        if (mid == null) continue;
        final portion = entry.portionPercent.clamp(10, 200) / 100.0;
        final factor = portion * _containerSizeFactorFor(entry.containerSize) * _containerTypeFactorFor(entry.containerType);
        total += mid * factor;
      }
      if (total > 0) {
        mealTotals.add(total);
      }
    }
    if (mealTotals.isEmpty) return null;
    final sum = mealTotals.fold<double>(0, (acc, v) => acc + v);
    return sum / mealTotals.length;
  }

  Widget _buildEnergyBar(AppState app, AppLocalizations t, AnalysisResult analysis) {
    final current = _calorieMidValue(_overrideCalorieRange ?? analysis.calorieRange);
    if (current == null || current <= 0) return const SizedBox.shrink();
    final mealType = app.resolveMealType(DateTime.now());
    final avg = _recentMealAverage(app, mealType: mealType) ?? _recentMealAverage(app);
    if (avg == null || avg <= 0) return const SizedBox.shrink();
    final max = math.max(avg * 1.6, avg + 200);
    final acceptRatio = (avg / max).clamp(0.05, 0.95);
    final currentRatio = (current / max).clamp(0.0, 1.0);
    const okColor = Color(0xFF7FCF9A);
    const highColor = Color(0xFFF4B183);
    const barHeight = 24.0;
    const indicatorSize = 14.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final indicatorLeft = (width * currentRatio).clamp(0.0, width - indicatorSize);
            return SizedBox(
              height: barHeight,
              child: Stack(
                children: [
                  Container(
                    height: barHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [okColor, highColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Text(
                            t.suggestInstantEnergyOk,
                            style: AppTextStyles.caption(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            t.suggestInstantEnergyHigh,
                            style: AppTextStyles.caption(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: indicatorLeft,
                    top: (barHeight - indicatorSize) / 2,
                    child: Container(
                      width: indicatorSize,
                      height: indicatorSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildProteinRangeBar(AppLocalizations t, double consumed, List<int> range) {
    final theme = Theme.of(context);
    final minTarget = range[0].toDouble();
    final maxTarget = range[1].toDouble();
    final maxScale = math.max(maxTarget * 1.2, consumed * 1.1 + 1);
    final currentRatio = (consumed / maxScale).clamp(0.0, 1.0);
    final startRatio = (minTarget / maxScale).clamp(0.0, 1.0);
    final endRatio = (maxTarget / maxScale).clamp(0.0, 1.0);
    const barHeight = 16.0;
    const indicatorSize = 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.proteinIntakeTodayLabel,
              style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${consumed.round()}g',
              style: AppTextStyles.caption(context).copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final rangeLeft = width * startRatio;
            final rangeWidth = width * (endRatio - startRatio);
            final indicatorLeft = (width * currentRatio).clamp(0.0, width - indicatorSize);
            return SizedBox(
              height: barHeight,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  if (rangeWidth > 0)
                    Positioned(
                      left: rangeLeft,
                      child: Container(
                        height: barHeight,
                        width: rangeWidth,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  Positioned(
                    left: indicatorLeft,
                    top: (barHeight - indicatorSize) / 2,
                    child: Container(
                      width: indicatorSize,
                      height: indicatorSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('${range[0]}g', style: AppTextStyles.caption(context).copyWith(color: Colors.black45)),
            const Spacer(),
            Text('${range[1]}g', style: AppTextStyles.caption(context).copyWith(color: Colors.black45)),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroSection(AppLocalizations t, AnalysisResult analysis) {
    final adjusted = _scaledMacros(analysis.macros);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.macroLabel, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        NutritionChart(
          macros: adjusted,
          style: NutritionChartStyle.donut,
          t: t,
          valueMode: NutritionValueMode.amount,
          calories: _calorieMidValue(_overrideCalorieRange ?? analysis.calorieRange),
        ),
      ],
    );
  }

  Map<String, double> _scaledMacros(Map<String, double> macros) {
    final percent = _portionPercent.clamp(10, 200) / 100.0;
    final factor = percent * _containerSizeFactor() * _containerTypeFactor();
    return {
      'protein': (macros['protein'] ?? 0) * factor,
      'carbs': (macros['carbs'] ?? 0) * factor,
      'fat': (macros['fat'] ?? 0) * factor,
      'sodium': (macros['sodium'] ?? 0) * factor,
    };
  }

  double? _calorieMidValue(String? rangeText) {
    if (rangeText == null || rangeText.trim().isEmpty) return null;
    final normalized = rangeText
        .replaceAll('\uFF5E', '-')
        .replaceAll('~', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-');
    final match = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(normalized);
    if (match != null) {
      final low = double.tryParse(match.group(1) ?? '');
      final high = double.tryParse(match.group(2) ?? '');
      if (low != null && high != null) {
        final percent = _portionPercent.clamp(10, 200) / 100.0;
        final factor = percent * _containerSizeFactor() * _containerTypeFactor();
        return ((low + high) / 2) * factor;
      }
    }
    final single = RegExp(r'(\d+)').firstMatch(normalized);
    if (single != null) {
      final value = double.tryParse(single.group(1) ?? '');
      if (value != null) {
        final percent = _portionPercent.clamp(10, 200) / 100.0;
        final factor = percent * _containerSizeFactor() * _containerTypeFactor();
        return value * factor;
      }
    }
    return null;
  }

  Future<void> _reanalyzeWithAdjustments() async {
    if (_analysis == null) return;
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final historyContext = app.buildAiContext();
    setState(() {
      _loading = true;
      _error = null;
    });
    _startSmartProgress();
    try {
      final updated = await app.reanalyzeQuickCapture(
        _analysis!,
        locale,
        historyContext: historyContext.isEmpty ? null : historyContext,
        foodName: _analysis!.result.foodName,
        containerType: _containerType,
        containerSize: _containerSize,
        portionPercent: _portionPercent,
        referenceObject: _referenceObject == 'none' || _referenceObject == 'manual' ? null : _referenceObject,
        referenceLengthCm: _referenceObject == 'manual' ? _parsedReferenceLength() : null,
      );
      if (!mounted) return;
      _analysis = updated;
      _savedEntry = null;
      _applyAnalysisDefaults(updated.result, keepUserSelections: true);
      _hideFloatingCard = false;
      _instantAdvice = null;
      _previewBytes = null;
      _showSaveActions = true;
      _completeSmartProgress(() {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      });
    } catch (err) {
      if (!mounted) return;
      _stopSmartProgress();
      setState(() {
        _error = t.reestimateFailedKeepLast;
        _loading = false;
      });
    }
  }

  Widget _buildInstantAdviceFromModel(AppLocalizations t, MealAdvice advice) {
    final labels = <String, String>{
      t.nextSelfCookLabel: '🍳',
      t.nextConvenienceLabel: '🏪',
      t.nextBentoLabel: '🍱',
      t.nextOtherLabel: '🌿',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _adviceRow('${labels[t.nextSelfCookLabel] ?? ''} ${t.nextSelfCookLabel}'.trim(), advice.selfCook),
        const SizedBox(height: 8),
        _adviceRow('${labels[t.nextConvenienceLabel] ?? ''} ${t.nextConvenienceLabel}'.trim(), advice.convenience),
        const SizedBox(height: 8),
        _adviceRow('${labels[t.nextBentoLabel] ?? ''} ${t.nextBentoLabel}'.trim(), advice.bento),
        const SizedBox(height: 8),
        _adviceRow('${labels[t.nextOtherLabel] ?? ''} ${t.nextOtherLabel}'.trim(), advice.other),
      ],
    );
  }

  Widget _buildAnalysisCardContent(AppLocalizations t, AppState app, AnalysisResult analysis) {
    if (analysis.isFood == false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🥹', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.suggestInstantNonFood,
                  style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if ((analysis.nonFoodReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              analysis.nonFoodReason!.trim(),
              style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
            ),
          ],
        ],
      );
    }
    final baseRange = _overrideCalorieRange ?? analysis.calorieRange;
    final adjustedRange = _displayCalorieRange ??
        _scaledCalorieRangeText(
          baseRange,
          _portionPercent,
          containerType: _containerType,
          containerSize: _containerSize,
        );
    final proteinRange = app.proteinTargetRangeGrams();
    final baseProteinConsumed = app.dailyProteinConsumedGrams((_analysis?.time ?? DateTime.now()));
    final adjustedMacros = _scaledMacros(analysis.macros);
    final currentProtein = _savedEntry == null ? (adjustedMacros['protein'] ?? 0) : 0;
    final proteinConsumed = (baseProteinConsumed + currentProtein).round();
    final referenceUsed = (analysis.referenceUsed ?? '').trim();
    final referenceLabel = referenceUsed.isEmpty ? t.referenceObjectNone : referenceUsed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _editFoodName,
              icon: const Icon(Icons.edit, size: 18),
              tooltip: t.editFoodName,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                analysis.foodName,
                style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '${adjustedRange} ${t.estimated}',
                style: AppTextStyles.title2(context).copyWith(fontWeight: FontWeight.w700, color: Colors.black87),
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 8),
        _buildEnergyBar(app, t, analysis),
        const SizedBox(height: 6),
        Text(
          '${t.referenceObjectLabel}：$referenceLabel',
          style: AppTextStyles.caption(context).copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
        if (proteinRange != null) ...[
          const SizedBox(height: 12),
          _buildProteinRangeBar(t, proteinConsumed.toDouble(), proteinRange),
        ],
        const SizedBox(height: 12),
        Text(
          analysis.isBeverage == true ? t.suggestInstantDrinkAdviceTitle : t.suggestInstantAdviceTitle,
          style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildAdviceCard(t),
        if (_showSaveActions) ...[
          const SizedBox(height: 14),
          Text(t.suggestInstantSavePrompt, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _showSaveActions = false);
                  },
                  child: Text(t.suggestInstantSkipSave),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveIfNeeded,
                  child: Text(t.suggestInstantSave),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _buildPortionContainerSection(t),
        const SizedBox(height: 12),
        _buildMacroSection(t, analysis),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loading ? null : _reanalyzeWithAdjustments,
            child: Text(t.suggestInstantReestimate),
          ),
        ),
        const SizedBox(height: 12),
        Text(t.suggestInstantRecentHint, style: AppTextStyles.caption(context).copyWith(color: Colors.black45)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final analysis = _analysis?.result;
    final showFloatingCard = analysis != null && !_hideFloatingCard;
    final showAdviceCard = _instantAdvice != null && !showFloatingCard;
    final showPreview = _analysis == null && _previewBytes != null;
    final media = MediaQuery.of(context);
    final cardWidth = (media.size.width - 32).clamp(280.0, 340.0);
    final cardHeight = (media.size.height * 0.7).clamp(420.0, 620.0);
    final innerWidth = (cardWidth - 20).clamp(260.0, 320.0);
    final innerHeight = (cardHeight - 16).clamp(380.0, 600.0);
    final plateSize = (cardHeight * 0.42).clamp(180.0, 250.0);
    final imageSize = (plateSize * 0.72).clamp(140.0, 200.0);
    final buttonWidth = (cardWidth * 0.7).clamp(160.0, 220.0);
    final contentVerticalPadding = (cardHeight * 0.1).clamp(24.0, 60.0);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, (showFloatingCard || showAdviceCard) ? 260 : 16),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                  Text(
                                    t.suggestTitle,
                                    style: AppTextStyles.title1(context),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t.suggestInstantHint,
                                    style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: SizedBox(
                                      width: cardWidth,
                                      height: cardHeight,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.22),
                                                borderRadius: BorderRadius.circular(28),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.center,
                                            child: Container(
                                              width: innerWidth,
                                              height: innerHeight,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.4),
                                                borderRadius: BorderRadius.circular(26),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(vertical: contentVerticalPadding),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                          if (_analysis != null || showPreview)
                                            Center(
                                              child: SizedBox(
                                                width: plateSize,
                                                height: plateSize,
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    AnimatedOpacity(
                                                      opacity: _loading ? _progressValue.clamp(0.0, 1.0) : 1.0,
                                                      duration: const Duration(milliseconds: 200),
                                                      child: PlatePhoto(
                                                        imageBytes: _analysis?.imageBytes ?? _previewBytes!,
                                                        plateAsset: plateAsset,
                                                        plateSize: plateSize,
                                                        imageSize: imageSize,
                                                        tilt: 0,
                                                      ),
                                                    ),
                                                    if (_loading) _buildScanOverlay(plateSize),
                                                  ],
                                                ),
                                              ),
                                            )
                                            else
                                              Center(
                                                child: SizedBox(
                                                  width: plateSize,
                                                  height: plateSize,
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.12),
                                                            blurRadius: 26,
                                                            offset: const Offset(0, 16),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Image.asset(plateAsset, fit: BoxFit.contain),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          if (_loading)
                                            Builder(builder: (context) {
                                              final steps = [
                                                t.suggestInstantStepDetect,
                                                t.suggestInstantStepEstimate,
                                                t.suggestInstantStepAdvice,
                                              ];
                                              final statusText = steps[_statusIndex % steps.length];
                                              final percent = (_progressValue * 100).clamp(0, 100).round();
                                              return Column(
                                                children: [
                                                  Text(
                                                    '$percent%',
                                                    style: AppTextStyles.body(context).copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    statusText,
                                                    style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                                                  ),
                                                ],
                                              );
                                            })
                                          else if (_error != null)
                                            Text(_error!, style: AppTextStyles.caption(context).copyWith(color: Colors.redAccent))
                                          else
                                            Center(
                                              child: SizedBox(
                                                width: buttonWidth,
                                              child: ElevatedButton.icon(
                                                  onPressed: _startCaptureFromCamera,
                                                  icon: const Text('📷', style: TextStyle(fontSize: 18)),
                                                  label: Text(
                                                    _analysis == null ? t.suggestInstantStart : t.suggestInstantRetake,
                                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: theme.colorScheme.primary,
                                                    foregroundColor: Colors.white,
                                                    side: BorderSide(color: theme.colorScheme.primary),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: SizedBox(
                                              width: buttonWidth,
                                              child: OutlinedButton.icon(
                                                onPressed: _startCaptureFromGallery,
                                                icon: const Text('🖼️', style: TextStyle(fontSize: 18)),
                                                label: Text(t.suggestInstantPickGallery, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: theme.colorScheme.primary,
                                                  side: BorderSide(color: theme.colorScheme.primary),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: SizedBox(
                                              width: buttonWidth,
                                              child: OutlinedButton.icon(
                                                onPressed: _requestNowAdvice,
                                                icon: const Text('🍽️', style: TextStyle(fontSize: 18)),
                                                label: Text(t.suggestInstantNowEat, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: theme.colorScheme.primary,
                                                  side: BorderSide(color: theme.colorScheme.primary),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Center(
                                            child: SizedBox(
                                              width: buttonWidth,
                                              child: OutlinedButton.icon(
                                                onPressed: _useCustomFood,
                                                icon: const Text('🔖', style: TextStyle(fontSize: 18)),
                                                label: Text(
                                                  '${t.customUse} - ${app.customFoods.length}${t.customCountUnit}',
                                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: theme.colorScheme.primary,
                                                  side: BorderSide(color: theme.colorScheme.primary),
                                                ),
                                              ),
                                            ),
                                          ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (kDebugMode)
                                    Builder(builder: (context) {
                                      final app = AppStateScope.of(context);
                                      final now = DateTime.now();
                                      final mealDate = DateTime(now.year, now.month, now.day);
                                      final consumed = app.dailyConsumedCalorieMid(mealDate).round();
                                      final target = app.targetCalorieMid(mealDate);
                                      final remaining = target == null ? null : (target - consumed).round();
                                      final info = app.lastMealInfo(now);
                                      final lastTime = info['last_meal_time']?.toString() ?? '-';
                                      final fasting = info['fasting_hours']?.toString() ?? '-';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Debug: remaining=${remaining ?? '-'} kcal | last=$lastTime | fasting=${fasting}h',
                                          style: AppTextStyles.caption(context).copyWith(color: Colors.black45),
                                        ),
                                      );
                                    }),

                                ],
                              ),
                            ),
                          ),
                        ),
              if (showFloatingCard)
                DraggableScrollableSheet(
                  initialChildSize: 0.45,
                  minChildSize: 0.3,
                  maxChildSize: 0.88,
                  builder: (context, controller) => Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 22,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => _hideFloatingCard = true),
                              icon: const Text('✖️', style: TextStyle(fontSize: 16)),
                              tooltip: t.cancel,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildAnalysisCardContent(t, app, analysis!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showAdviceCard)
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.3,
                  maxChildSize: 0.75,
                  builder: (context, controller) => Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22), bottom: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 22,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(
                              onPressed: () => setState(() => _instantAdvice = null),
                              icon: const Text('??', style: TextStyle(fontSize: 16)),
                              tooltip: t.cancel,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: controller,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🍽️ ${t.suggestInstantNowEat}',
                                  style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                _buildInstantAdviceFromModel(t, _instantAdvice!),
                              ],
                            ),
                          ),
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

class _IconChipOption {
  const _IconChipOption({
    this.icon,
    this.emoji,
    required this.value,
    required this.label,
    this.showLabel = true,
  });

  final IconData? icon;
  final String? emoji;
  final String value;
  final String label;
  final bool showLabel;
}


class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter({
    required this.progress,
    required this.rotation,
    required this.color,
  });

  final double progress;
  final double rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

      final center = Offset(w * 0.5, h * 0.5);
      final radius = math.min(w, h) * 0.36;
    final trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final progressPaint = Paint()
      ..color = color.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final spinnerPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = (progress.clamp(0.0, 1.0)) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );

    final spinnerSweep = math.pi * 0.6;
    final spinnerStart = rotation * math.pi * 2 - math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 6),
      spinnerStart,
      spinnerSweep,
      false,
      spinnerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rotation != rotation || oldDelegate.color != color;
  }
}
