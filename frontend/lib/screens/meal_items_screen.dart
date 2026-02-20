import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal_entry.dart';
import '../state/app_state.dart';
import 'day_meals_screen.dart';
import '../widgets/plate_photo.dart';
import '../widgets/nutrition_chart.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class MealItemsScreen extends StatefulWidget {
  const MealItemsScreen({
    super.key,
    required this.group,
    this.initialIndex,
    this.initialEntryId,
    this.autoReturnToDayMeals = false,
    this.autoReturnDate,
    this.autoReturnMealId,
  });

  final List<MealEntry> group;
  final int? initialIndex;
  final String? initialEntryId;
  final bool autoReturnToDayMeals;
  final DateTime? autoReturnDate;
  final String? autoReturnMealId;

  @override
  State<MealItemsScreen> createState() => _MealItemsScreenState();
}

class _MealItemsScreenState extends State<MealItemsScreen> {
  late final PageController _pageController;
  final ImagePicker _picker = ImagePicker();
  int _pageIndex = 0;
  Timer? _autoTimer;
  bool _autoTimerStarted = false;

  int _entryOrderAsc(MealEntry a, MealEntry b) {
    final byTime = a.time.compareTo(b.time);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState app, MealEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deleteConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.delete)),
        ],
      ),
    );
    if (result == true) {
      app.removeEntry(entry);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    final sortedForInit = List<MealEntry>.from(widget.group)
      ..sort(_entryOrderAsc);
    final maxIndex = math.max(0, sortedForInit.length - 1);
    int resolvedIndex = widget.initialIndex ?? 0;
    final targetId = widget.initialEntryId?.trim() ?? '';
    if (targetId.isNotEmpty) {
      final idIndex = sortedForInit.indexWhere((entry) => entry.id == targetId);
      if (idIndex >= 0) {
        resolvedIndex = idIndex;
      }
    }
    _pageIndex = resolvedIndex.clamp(0, maxIndex);
    _pageController =
        PageController(viewportFraction: 1, initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autoReturnToDayMeals || _autoTimerStarted) return;
    final mealId = widget.autoReturnMealId;
    final date = widget.autoReturnDate;
    if (mealId == null || date == null) return;
    _autoTimerStarted = true;
    final app = AppStateScope.of(context);
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final last = app.mealInteractionAt(mealId);
      if (last == null) return;
      if (DateTime.now().difference(last) < const Duration(minutes: 1)) return;
      timer.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DayMealsScreen(date: date, initialMealId: mealId),
        ),
      );
    });
  }

  Widget _itemCard(
      BuildContext context, AppState app, MealEntry entry, String plateAsset) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showImagePreview(context, entry),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final plateSize = math.max(240.0, math.min(320.0, maxWidth));
          final imageSize = plateSize * 0.72;
          return SizedBox(
            height: 420,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 170, 16, 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
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
                                entry.overrideFoodName ??
                                    entry.result?.foodName ??
                                    t.unknownFood,
                                style: AppTextStyles.title2(context),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: IconButton(
                                onPressed: () =>
                                    _editFoodName(context, app, entry),
                                icon: const Text('✏️',
                                    style: TextStyle(fontSize: 16)),
                                tooltip: t.editFoodName,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: IconButton(
                                onPressed: () async {
                                  await app.addCustomFoodFromEntry(entry, t);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.customAdded)),
                                  );
                                },
                                icon: const Text('📌',
                                    style: TextStyle(fontSize: 16)),
                                tooltip: t.customAdd,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: IconButton(
                                onPressed: () =>
                                    _reanalyzeEntry(context, app, entry),
                                icon: const Text('🔄',
                                    style: TextStyle(fontSize: 16)),
                                tooltip: t.reanalyzeLabel,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: IconButton(
                                onPressed: () =>
                                    _editEntryTime(context, app, entry),
                                icon: const Icon(Icons.access_time_rounded,
                                    size: 18),
                                tooltip: t.editTime,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: IconButton(
                                onPressed: () =>
                                    _confirmDelete(context, app, entry),
                                icon: const Text('🗑️',
                                    style: TextStyle(fontSize: 16)),
                                tooltip: t.delete,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        _portionSelector(context, app, entry, theme, t),
                      ],
                    ),
                  ),
                ),
                PlatePhoto(
                  imageBytes: entry.imageBytes,
                  plateAsset: plateAsset,
                  imageUrl:
                      _catalogImageForEntry(app, entry, preferThumb: false),
                  plateSize: plateSize,
                  imageSize: imageSize,
                  tilt: -0.08,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showImagePreview(BuildContext context, MealEntry entry) async {
    final app = AppStateScope.of(context);
    final imageUrl = _catalogImageForEntry(app, entry, preferThumb: false);
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Image.memory(entry.imageBytes, fit: BoxFit.contain),
                    )
                  : Image.memory(entry.imageBytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  String? _catalogImageForEntry(
    AppState app,
    MealEntry entry, {
    required bool preferThumb,
  }) {
    if (!app.isNamePlaceholderImage(entry.imageBytes)) {
      return null;
    }
    final thumb = entry.result?.catalogThumbUrl?.trim() ?? '';
    final full = entry.result?.catalogImageUrl?.trim() ?? '';
    if (preferThumb && thumb.isNotEmpty) return thumb;
    if (full.isNotEmpty) return full;
    if (thumb.isNotEmpty) return thumb;
    return null;
  }

  Future<void> _editFoodName(
      BuildContext context, AppState app, MealEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(
        text: entry.overrideFoodName ?? entry.result?.foodName ?? '');
    final locale = Localizations.localeOf(context).toLanguageTag();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editFoodName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: t.foodNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(t.save),
          ),
        ],
      ),
    );
    if (result == null) return;
    await app.updateEntryFoodName(entry, result, locale);
  }

  Future<void> _editEntryTime(
      BuildContext context, AppState app, MealEntry entry) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: entry.time,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(entry.time),
    );
    if (pickedTime == null) return;
    final nextTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    app.updateEntryTime(entry, nextTime);
  }

  Future<void> _pickLabelImage(
      BuildContext context, AppState app, MealEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 16)),
              title: Text(t.takePhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 16)),
              title: Text(t.uploadPhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source);
    if (file == null) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    await app.addLabelToEntry(entry, file, locale);
  }

  Future<void> _reanalyzeEntry(
      BuildContext context, AppState app, MealEntry entry) async {
    final locale = Localizations.localeOf(context).toLanguageTag();
    await app.reanalyzeEntry(entry, locale);
  }

  Widget _portionSelector(
    BuildContext context,
    AppState app,
    MealEntry entry,
    ThemeData theme,
    AppLocalizations t,
  ) {
    return Row(
      children: [
        Text('${t.portionLabel}${entry.portionPercent}%',
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.2),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withOpacity(0.12),
            ),
            child: Slider(
              value: entry.portionPercent.toDouble(),
              min: 10,
              max: 200,
              divisions: 19,
              label: '${entry.portionPercent}%',
              onChanged: (value) {
                app.updateEntryPortionPercent(entry, value.round());
              },
            ),
          ),
        ),
      ],
    );
  }

  String _nutritionTitle(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'en' ? 'Nutrition' : '營養成分';
  }

  bool _isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'en';
  }

  String _analysisSourceLabel(BuildContext context, MealEntry? entry) {
    final isEn = _isEnglish(context);
    if (entry == null || entry.result == null) {
      return isEn ? 'Unknown source' : '來源未知';
    }
    final reason = (entry.lastAnalyzeReason ?? '').trim().toLowerCase();
    final source = (entry.result?.source ?? '').trim().toLowerCase();
    final nutritionSource =
        (entry.result?.nutritionSource ?? '').trim().toLowerCase();
    if (reason == 'name_ai_catalog_error') {
      return isEn ? 'AI estimate (catalog unavailable)' : 'AI估算（資料庫異常）';
    }
    if (nutritionSource == 'catalog' ||
        source == 'catalog' ||
        reason == 'name_catalog') {
      return isEn ? 'Catalog' : '資料庫';
    }
    if (nutritionSource == 'beverage_formula' ||
        source == 'beverage_formula' ||
        reason == 'name_beverage_formula') {
      return isEn ? 'Beverage formula' : '飲料規則估算';
    }
    if (nutritionSource == 'custom' ||
        source == 'custom' ||
        reason == 'custom_use') {
      return isEn ? 'Custom' : '自訂';
    }
    if (nutritionSource == 'label' || source == 'label') {
      return isEn ? 'Nutrition label' : '營養標示';
    }
    if (source == 'ai' || reason == 'name_only') {
      return isEn ? 'AI estimate' : 'AI估算';
    }
    return isEn ? 'Unknown source' : '來源未知';
  }

  Color _analysisSourceColor(MealEntry? entry) {
    final reason = (entry?.lastAnalyzeReason ?? '').trim().toLowerCase();
    final source = (entry?.result?.source ?? '').trim().toLowerCase();
    final nutritionSource =
        (entry?.result?.nutritionSource ?? '').trim().toLowerCase();
    if (reason == 'name_ai_catalog_error') return const Color(0xFFD16A00);
    if (nutritionSource == 'catalog' ||
        source == 'catalog' ||
        reason == 'name_catalog') {
      return const Color(0xFF2E9B66);
    }
    if (nutritionSource == 'beverage_formula' ||
        source == 'beverage_formula' ||
        reason == 'name_beverage_formula') {
      return const Color(0xFF0D8A87);
    }
    if (nutritionSource == 'custom' ||
        source == 'custom' ||
        reason == 'custom_use') {
      return const Color(0xFF2F80ED);
    }
    if (nutritionSource == 'label' || source == 'label') {
      return const Color(0xFF6C7A89);
    }
    if (source == 'ai' || reason == 'name_only') {
      return const Color(0xFFB26A00);
    }
    return const Color(0xFF8A8A8A);
  }

  NutritionChartStyle _chartStyle(String value) {
    switch (value) {
      case 'bars':
        return NutritionChartStyle.bars;
      case 'donut':
        return NutritionChartStyle.donut;
      default:
        return NutritionChartStyle.radar;
    }
  }

  NutritionValueMode _valueMode(String value) {
    switch (value) {
      case 'amount':
        return NutritionValueMode.amount;
      case 'percent':
      default:
        return NutritionValueMode.percent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    final theme = Theme.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty
        ? kDefaultPlateAsset
        : app.profile.plateAsset;
    final sorted = List<MealEntry>.from(widget.group)..sort(_entryOrderAsc);
    if (_pageIndex >= sorted.length) {
      _pageIndex = 0;
    }
    final currentEntry = sorted.isEmpty ? null : sorted[_pageIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = math.max(0.0, screenWidth - 32);
    final isEnglish = _isEnglish(context);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.mealItemsTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 420,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _pageIndex = index),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) =>
                      _itemCard(context, app, sorted[index], plateAsset),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.mealSummaryTitle,
                                style: AppTextStyles.title2(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                () {
                                  final summary = currentEntry
                                          ?.result?.dishSummary
                                          ?.trim() ??
                                      '';
                                  if (summary.isNotEmpty) return summary;
                                  final labelName =
                                      (currentEntry?.labelResult?.labelName ??
                                              '')
                                          .trim();
                                  if (currentEntry?.labelResult != null) {
                                    return labelName.isNotEmpty
                                        ? '${t.labelSummaryFallback}：$labelName'
                                        : t.labelSummaryFallback;
                                  }
                                  return t.detailAiEmpty;
                                }(),
                                style: AppTextStyles.caption(context).copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if ((currentEntry?.lastAnalyzedNote ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  currentEntry!.lastAnalyzedNote!.trim(),
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    color: const Color(0xFFD16A00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (currentEntry
                                      ?.result?.judgementTags.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: currentEntry!.result!.judgementTags
                                      .map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tag,
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (currentEntry?.result?.foodItems.isNotEmpty ==
                                  true) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${isEnglish ? 'Foods' : '食物'}：${currentEntry!.result!.foodItems.join('、')}',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: Colors.black87),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _analysisSourceColor(currentEntry)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _analysisSourceLabel(context, currentEntry),
                                style: AppTextStyles.caption(context).copyWith(
                                  color: _analysisSourceColor(currentEntry),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                currentEntry == null
                                    ? t.calorieUnknown
                                    : app.entryCalorieRangeLabel(
                                        currentEntry, t),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (currentEntry?.result != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _nutritionTitle(context),
                                  style: AppTextStyles.title2(context),
                                ),
                              ),
                              if (currentEntry != null)
                                TextButton.icon(
                                  onPressed: () => _pickLabelImage(
                                      context, app, currentEntry),
                                  icon: const Text('🧾',
                                      style: TextStyle(fontSize: 16)),
                                  label: Text(t.addLabel),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          NutritionChart(
                            macros: app.scaledMacrosForEntry(currentEntry!),
                            style: _chartStyle(app.profile.nutritionChartStyle),
                            valueMode:
                                _valueMode(app.profile.nutritionValueMode),
                            calories: app.calorieRangeMid(
                                currentEntry!.result?.calorieRange),
                            t: t,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (currentEntry?.labelResult != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentEntry!.labelImageBytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                currentEntry!.labelImageBytes!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (currentEntry!.labelImageBytes != null)
                            const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.labelInfoTitle,
                                        style: AppTextStyles.title2(context),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => app.removeLabelFromEntry(
                                          currentEntry,
                                          Localizations.localeOf(context)
                                              .toLanguageTag()),
                                      icon: const Text('🗑️',
                                          style: TextStyle(fontSize: 16)),
                                      tooltip: t.removeLabel,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(
                                          minWidth: 36, minHeight: 36),
                                    ),
                                  ],
                                ),
                                if ((currentEntry!.labelResult!.labelName ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    currentEntry!.labelResult!.labelName!
                                        .trim(),
                                    style: AppTextStyles.caption(context)
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  '${t.calorieLabel}：${currentEntry!.labelResult!.calorieRange}',
                                  style: AppTextStyles.caption(context)
                                      .copyWith(color: Colors.black87),
                                ),
                              ],
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
    );
  }
}
