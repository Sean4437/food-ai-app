import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import '../state/app_state.dart';
import '../models/custom_food.dart';
import '../models/meal_entry.dart';
import '../widgets/plate_photo.dart';
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
  Uint8List? _previewBytes;
  bool _loading = false;
  String? _error;
  bool _showSaveActions = false;
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
    super.dispose();
  }

  Future<void> _startCapture({required ImageSource source}) async {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _analysis = null;
      _previewBytes = null;
      _showSaveActions = false;
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
      );
      if (!mounted) return;
      _analysis = analysis;
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

  Future<void> _saveIfNeeded() async {
    if (_analysis == null) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    await app.saveQuickCapture(_analysis!);
    if (!mounted) return;
    setState(() {
      _showSaveActions = false;
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
    _startSmartProgress();
    final historyContext = app.buildAiContext();
    try {
      final updated = await app.reanalyzeQuickCapture(
        _analysis!,
        locale,
        historyContext: historyContext.isEmpty ? null : historyContext,
        foodName: result.trim(),
      );
      if (!mounted) return;
      _analysis = updated;
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
      final lower = line.toLowerCase();
      if (line.startsWith('可以吃') || lower.startsWith('can eat')) {
        sections['can'] = _splitAdviceValue(line);
      } else if (line.startsWith('不建議吃') || lower.startsWith('avoid')) {
        sections['avoid'] = _splitAdviceValue(line);
      } else if (line.startsWith('份量上限') || lower.startsWith('portion')) {
        sections['limit'] = _splitAdviceValue(line);
      }
    }
    return sections;
  }

  String _splitAdviceValue(String line) {
    if (line.contains('：')) {
      return line.split('：').last.trim();
    }
    if (line.contains(':')) {
      return line.split(':').last.trim();
    }
    return line.trim();
  }

  
  Widget _buildScanOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
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
                  size: Size.infinite,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: const SizedBox.shrink(),
                  ),
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
    final suggestion = _analysis!.result.suggestion;
    final sections = _parseAdviceSections(suggestion);
    if (sections.isEmpty) {
      return Text(suggestion, style: AppTextStyles.caption(context).copyWith(color: Colors.black87, height: 1.4));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _adviceRow(t.suggestInstantCanEat, sections['can']),
        const SizedBox(height: 8),
        _adviceRow(t.suggestInstantAvoid, sections['avoid']),
        const SizedBox(height: 8),
        _adviceRow(t.suggestInstantLimit, sections['limit']),
      ],
    );
  }

  Widget _adviceRow(String title, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value ?? '-', style: AppTextStyles.caption(context).copyWith(color: Colors.black87, height: 1.4)),
        ),
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
    final showPreview = _analysis == null && _previewBytes != null;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 700,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 320,
                              height: 700,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 300,
                              height: 640,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_analysis != null || showPreview)
                              Center(
                                child: Stack(
                                  children: [
                                    AnimatedOpacity(
                                      opacity: _loading ? _progressValue.clamp(0.0, 1.0) : 1.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: PlatePhoto(
                                        imageBytes: _analysis?.imageBytes ?? _previewBytes!,
                                        plateAsset: plateAsset,
                                        plateSize: 260,
                                        imageSize: 185,
                                        tilt: 0,
                                      ),
                                    ),
                                    if (_loading) _buildScanOverlay(),
                                  ],
                                ),
                              )
                            else
                              Center(
                                child: SizedBox(
                                  width: 220,
                                  height: 220,
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
                                  width: 180,
                                  child: ElevatedButton.icon(
                                    onPressed: _startCaptureFromCamera,
                                    icon: const Icon(Icons.camera_alt, color: Colors.white),
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
                                  width: 180,
                                child: OutlinedButton.icon(
                                  onPressed: _startCaptureFromGallery,
                                  icon: Icon(Icons.photo_library_outlined, size: 18, color: theme.colorScheme.primary),
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
                                width: 180,
                                child: OutlinedButton.icon(
                                  onPressed: _useCustomFood,
                                  icon: Icon(Icons.bookmark_add_outlined, size: 18, color: theme.colorScheme.primary),
                                  label: Text(
                                    '${t.customUse} · ${app.customFoods.length}${t.customCountUnit}',
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
                      ],
                    ),
                    ),
                  const SizedBox(height: 12),
                  if (analysis != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  analysis.foodName,
                                  style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                onPressed: _editFoodName,
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: t.editFoodName,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${analysis.calorieRange} ${t.estimated}', style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                          const SizedBox(height: 12),
                          Text(t.suggestInstantAdviceTitle, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
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
                          const SizedBox(height: 12),
                          Text(t.suggestInstantRecentHint, style: AppTextStyles.caption(context).copyWith(color: Colors.black45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

    final center = Offset(w * 0.5, h * 0.46);
    final radius = math.min(w, h) * 0.27;
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
