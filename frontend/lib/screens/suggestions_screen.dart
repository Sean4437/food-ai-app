import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'dart:async';
import 'dart:math' as math;
import '../state/app_state.dart';
import '../models/analysis_result.dart';
import '../models/custom_food.dart';
import '../models/food_name_suggestion.dart';
import '../models/meal_entry.dart';
import '../widgets/plate_photo.dart';
import '../widgets/nutrition_chart.dart';
import '../widgets/app_background.dart';
import '../widgets/subscription_paywall.dart';
import '../design/text_styles.dart';
import '../services/api_service.dart';
import '../services/gallery_save_types.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  QuickCaptureAnalysis? _analysis;
  MealAdvice? _instantAdvice;
  Uint8List? _previewBytes;
  bool _loading = false;
  String? _error;
  bool _hideFloatingCard = false;
  MealEntry? _savedEntry;
  int _portionPercent = 100;
  String? _containerType;
  String? _containerSize;
  int _lastAnalyzedPortionPercent = 100;
  String? _lastAnalyzedContainerType;
  String? _lastAnalyzedContainerSize;
  String? _lastAnalyzedCalorieOverride;
  bool _adviceNeedsReestimate = false;
  String _referenceObject = 'none';
  final TextEditingController _referenceLengthController =
      TextEditingController();
  String? _overrideCalorieRange;
  String? _displayCalorieRange;
  ImageSource? _captureSource;
  bool _cameraPhotoSyncHandled = false;
  late final AnimationController _scanController;
  double _progressValue = 0;
  int _statusIndex = 0;
  bool _finishingProgress = false;
  Timer? _progressTimer;
  Timer? _statusTimer;

  // ignore: unused_element
  String _subscriptionRequiredMessage() {
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    return isZh ? '此功能需訂閱後才能使用' : 'This feature requires subscription.';
  }

  Future<bool> _ensureFeatureAccess(AppState app, AppFeature feature) async {
    if (app.canUseFeature(feature)) return true;
    final t = AppLocalizations.of(context)!;
    await showSubscriptionPaywall(context, app, t);
    return app.canUseFeature(feature);
  }

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppStateScope.of(context);
      if (!app.canUseFeature(AppFeature.analyze)) return;
      unawaited(_startCaptureFromCamera());
    });
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
    final app = AppStateScope.of(context);
    if (!await _ensureFeatureAccess(app, AppFeature.analyze)) return;
    setState(() {
      _loading = false;
      _error = null;
      _analysis = null;
      _instantAdvice = null;
      _previewBytes = null;
      _savedEntry = null;
      _portionPercent = 100;
      _containerType = null;
      _containerSize = null;
      _referenceObject = 'none';
      _referenceLengthController.text = '';
      _overrideCalorieRange = null;
      _displayCalorieRange = null;
      _lastAnalyzedPortionPercent = 100;
      _lastAnalyzedContainerType = null;
      _lastAnalyzedContainerSize = null;
      _lastAnalyzedCalorieOverride = null;
      _adviceNeedsReestimate = false;
      _captureSource = null;
      _cameraPhotoSyncHandled = false;
    });
    final file = await _picker.pickImage(source: source);
    if (!mounted) return;
    if (file == null) return;
    final preview = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _previewBytes = preview;
      _captureSource = source;
    });
    _startSmartProgress();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final historyContext = app.buildAiContext();
    try {
      final analysis = await app.analyzeQuickCapture(
        file,
        locale,
        historyContext: historyContext.isEmpty ? null : historyContext,
        referenceObject:
            _referenceObject == 'none' || _referenceObject == 'manual'
                ? null
                : _referenceObject,
        referenceLengthCm:
            _referenceObject == 'manual' ? _parsedReferenceLength() : null,
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
      _applyAnalysisDefaults(analysis.result);
      _hideFloatingCard = false;
      _instantAdvice = null;
      _previewBytes = null;
      await _persistCurrentAnalysis(announceSaved: true, syncToGallery: true);
      if (!mounted) return;
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
        _error = _analysisErrorMessage(err);
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
    final input = await _promptNameInput(t, app, locale);
    if (!mounted) return;
    final inputName = input?.name.trim() ?? '';
    if (inputName.isEmpty) return;
    final normalizedInput = _normalizeLookupName(inputName);
    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
      _instantAdvice = null;
      _previewBytes = null;
      _savedEntry = null;
      _captureSource = null;
    });
    _startSmartProgress();
    try {
      final candidates = await app.suggestFoodNameOptions(
        inputName,
        locale,
        limit: 24,
      );
      final selectedSuggestion = input?.selectedSuggestion;
      final hasExplicitSelection = selectedSuggestion != null;
      final hasExactCandidate = candidates.any(
        (item) =>
            item.source != FoodNameSuggestionSource.custom &&
            _normalizeLookupName(item.name) == normalizedInput,
      );
      if (!hasExplicitSelection && !hasExactCandidate) {
        throw NameLookupException('catalog_not_found');
      }
      await app.analyzeNameAndSave(
        inputName,
        locale,
        explicitSuggestion: selectedSuggestion,
      );
      if (!mounted) return;
      _instantAdvice = null;
      _previewBytes = null;
      _completeSmartProgress(() {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.logSuccess)),
      );
    } on NameLookupException catch (err) {
      if (!mounted) return;
      _stopSmartProgress();
      final message = _nameLookupMessage(err.code);
      setState(() {
        _error = message;
        _loading = false;
        _previewBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (err) {
      if (!mounted) return;
      _stopSmartProgress();
      setState(() {
        _error = _analysisErrorMessage(err);
        _loading = false;
        _previewBytes = null;
      });
    }
  }

  String _normalizeLookupName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _suggestionSourceLabel(FoodNameSuggestionSource source) {
    final isZh = _isZh();
    switch (source) {
      case FoodNameSuggestionSource.custom:
        return isZh ? '自訂' : 'Custom';
      case FoodNameSuggestionSource.catalog:
        return isZh ? '資料庫' : 'Catalog';
      case FoodNameSuggestionSource.beverage:
        return isZh ? '飲料' : 'Drink';
    }
  }

  IconData _suggestionSourceIcon(FoodNameSuggestionSource source) {
    switch (source) {
      case FoodNameSuggestionSource.custom:
        return Icons.bookmark_outline;
      case FoodNameSuggestionSource.catalog:
        return Icons.restaurant_menu_outlined;
      case FoodNameSuggestionSource.beverage:
        return Icons.local_drink_outlined;
    }
  }

  Future<FoodNameInputResult?> _promptNameInput(
    AppLocalizations t,
    AppState app,
    String locale,
  ) async {
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    final controller = TextEditingController();
    Timer? debounce;
    var requestToken = 0;
    var suggestions = <FoodNameSuggestion>[];
    var isSearching = false;

    Future<void> refreshSuggestions(
      String keyword,
      BuildContext dialogContext,
      void Function(VoidCallback fn) setDialogState,
    ) async {
      final query = keyword.trim();
      final token = ++requestToken;

      if (query.isEmpty) {
        if (!dialogContext.mounted) return;
        setDialogState(() {
          suggestions = const [];
          isSearching = false;
        });
        return;
      }

      if (dialogContext.mounted) {
        setDialogState(() => isSearching = true);
      }

      try {
        final result =
            await app.suggestFoodNameOptions(query, locale, limit: 24);
        if (!dialogContext.mounted || token != requestToken) return;
        setDialogState(() {
          suggestions = result;
          isSearching = false;
        });
      } catch (_) {
        if (!dialogContext.mounted || token != requestToken) return;
        setDialogState(() {
          suggestions = const [];
          isSearching = false;
        });
      }
    }

    final result = await showDialog<FoodNameInputResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final hasInput = controller.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(t.suggestInstantNameSubmit),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: t.suggestInstantNameHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) {
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 350), () {
                        refreshSuggestions(
                          controller.text,
                          dialogContext,
                          setDialogState,
                        );
                      });
                    },
                    onSubmitted: (value) => Navigator.of(dialogContext).pop(
                      FoodNameInputResult(name: value.trim()),
                    ),
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (hasInput) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: suggestions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Text(
                                isZh
                                    ? '目前沒有資料庫建議，你仍可提交這個名稱。'
                                    : 'No database suggestions yet. You can still submit this name.',
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.black54),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 0.5,
                              ),
                              itemBuilder: (context, index) {
                                final suggestion = suggestions[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    _suggestionSourceIcon(suggestion.source),
                                    size: 18,
                                  ),
                                  title: Text(suggestion.name),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: suggestion.isCustom
                                          ? const Color(0xFFEAF7EF)
                                          : suggestion.source ==
                                                  FoodNameSuggestionSource
                                                      .catalog
                                              ? const Color(0xFFF2F5F9)
                                              : const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _suggestionSourceLabel(suggestion.source),
                                      style: Theme.of(dialogContext)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: suggestion.isCustom
                                                ? const Color(0xFF2F8F5B)
                                                : suggestion.source ==
                                                        FoodNameSuggestionSource
                                                            .catalog
                                                    ? const Color(0xFF5B6B7A)
                                                    : const Color(0xFF9A6500),
                                          ),
                                    ),
                                  ),
                                  onTap: () => Navigator.of(dialogContext).pop(
                                    FoodNameInputResult(
                                      name: suggestion.name,
                                      selectedSuggestion: suggestion,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(
                  FoodNameInputResult(name: controller.text.trim()),
                ),
                child: Text(t.suggestInstantNameSubmit),
              ),
            ],
          );
        },
      ),
    );
    debounce?.cancel();
    controller.dispose();
    final trimmed = result?.name.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return FoodNameInputResult(
      name: trimmed,
      selectedSuggestion: result?.selectedSuggestion,
    );
  }

  String _nameLookupMessage(String code) {
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    switch (code) {
      case 'custom_not_found':
        return isZh
            ? '這筆自訂餐目前不存在，請重新選擇。'
            : 'This custom meal is no longer available. Please choose again.';
      case 'catalog_not_found':
        return isZh
            ? '目前資料庫尚未收錄這個食物，已幫你記錄，後續會更新。'
            : 'Not in catalog yet. We recorded this query and will add it in a future update.';
      case 'catalog_unavailable':
        return isZh
            ? '資料庫暫時不可用，請稍後再試。'
            : 'Food database is temporarily unavailable. Please try again later.';
      case 'subscription_required':
        return isZh
            ? '目前資料庫尚未收錄這個食物，後續會更新。若要立即估算可升級使用 AI。'
            : 'Not in catalog yet. We will add it in a future update. Upgrade to use AI estimate now.';
      case 'ai_unavailable':
        return isZh
            ? 'AI 估算暫時不可用，請稍後再試。'
            : 'AI estimate is temporarily unavailable. Please try again later.';
      case 'ai_model_unavailable':
        return isZh
            ? 'AI 模型目前暫時不可用，系統會自動切換，請稍後再試。'
            : 'AI model is temporarily unavailable. The system will auto-fallback. Please try again.';
      case 'ai_connection_error':
        return isZh
            ? 'AI 連線暫時異常，請稍後再試。'
            : 'Temporary AI connection issue. Please try again.';
      case 'ai_auth_error':
        return isZh
            ? 'AI 金鑰設定異常，請聯絡管理員。'
            : 'AI key configuration issue. Please contact support.';
      case 'ai_invalid_response':
      case 'ai_failed':
        return isZh
            ? 'AI 分析暫時失敗，請稍後再試。'
            : 'AI analysis failed temporarily. Please try again.';
      default:
        return isZh ? '名稱查詢失敗。' : 'Name lookup failed.';
    }
  }

  String _analysisErrorMessage(Object err) {
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    if (err is NameLookupException && err.code == 'custom_not_found') {
      return isZh
          ? '這筆自訂餐目前不存在，請重新選擇。'
          : 'This custom meal is no longer available. Please choose again.';
    }
    if (err is ApiException) {
      switch (err.code) {
        case 'subscription_required':
          return isZh ? '此功能需訂閱後才能使用。' : 'This feature requires subscription.';
        case 'analyze_rate_limited':
          return isZh
              ? '分析太頻繁了，請稍後再試。'
              : 'Too many analysis requests. Please try again later.';
        case 'ai_model_unavailable':
          return isZh
              ? 'AI 模型目前暫時不可用，系統會自動切換，請稍後再試。'
              : 'AI model is temporarily unavailable. The system will auto-fallback. Please try again.';
        case 'ai_connection_error':
          return isZh
              ? 'AI 連線暫時異常，請稍後再試。'
              : 'Temporary AI connection issue. Please try again.';
        case 'ai_auth_error':
          return isZh
              ? 'AI 金鑰設定異常，請聯絡管理員。'
              : 'AI key configuration issue. Please contact support.';
        case 'ai_invalid_response':
        case 'ai_failed':
          return isZh
              ? 'AI 分析暫時失敗，請稍後再試。'
              : 'AI analysis failed temporarily. Please try again.';
      }
    }
    final raw = err.toString();
    if (raw.contains('subscription_required')) {
      return isZh ? '此功能需訂閱後才能使用。' : 'This feature requires subscription.';
    }
    return isZh ? '分析失敗，請稍後再試。' : 'Analysis failed. Please try again.';
  }

  String _autoSavedMessage() {
    return _isZh() ? '已自動存到紀錄。' : 'Saved to your log automatically.';
  }

  String _deleteSavedMessage() {
    return _isZh() ? '已刪除此筆紀錄。' : 'This saved item was deleted.';
  }

  Future<void> _persistCurrentAnalysis({
    bool announceSaved = false,
    bool syncToGallery = false,
  }) async {
    if (_analysis == null) return;
    final app = AppStateScope.of(context);
    final saved = await app.saveQuickCapture(
      _analysis!,
      existing: _savedEntry,
      portionPercent: _portionPercent,
      containerType: _containerType,
      containerSize: _containerSize,
      overrideCalorieRange: _overrideCalorieRange,
    );
    if (!mounted) return;
    setState(() {
      _savedEntry = saved;
    });
    if (!announceSaved) return;
    String message = _autoSavedMessage();
    if (syncToGallery) {
      final galleryMessage = await _syncCameraPhotoIfNeeded(app);
      if (!mounted) return;
      if (galleryMessage != null && galleryMessage.trim().isNotEmpty) {
        message = galleryMessage;
      }
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _syncCameraPhotoIfNeeded(AppState app) async {
    if (_cameraPhotoSyncHandled ||
        _captureSource != ImageSource.camera ||
        _analysis == null) {
      return null;
    }
    _cameraPhotoSyncHandled = true;
    final filename =
        _analysis!.file.name.isNotEmpty ? _analysis!.file.name : 'capture.jpg';
    final result = await app.syncCameraCaptureToSystemGallery(
      _analysis!.originalBytes,
      filename: filename,
      creationDate: _savedEntry?.time ?? _analysis!.time,
    );
    switch (result.status) {
      case GallerySaveStatus.permissionDenied:
        return _isZh()
            ? '已存到 MiraMeal，但未取得系統相簿權限。'
            : 'Saved in MiraMeal, but gallery permission was not granted.';
      case GallerySaveStatus.failed:
        return _isZh()
            ? '已存到 MiraMeal，但未能寫入系統相簿。'
            : 'Saved in MiraMeal, but the image could not be written to the system gallery.';
      case GallerySaveStatus.saved:
      case GallerySaveStatus.disabled:
      case GallerySaveStatus.notSupported:
        return null;
    }
  }

  Future<void> _deleteSavedEntry() async {
    final entry = _savedEntry;
    if (entry == null || !mounted) return;
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_isZh() ? '刪除這筆紀錄？' : 'Delete this saved item?'),
            content: Text(
              _isZh()
                  ? '這會從 MiraMeal 紀錄中移除這張照片與分析結果。'
                  : 'This removes the photo and analysis from your MiraMeal log.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(_isZh() ? '取消' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(_isZh() ? '刪除' : 'Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete || !mounted) return;
    final app = AppStateScope.of(context);
    app.removeEntry(entry);
    setState(() {
      _analysis = null;
      _instantAdvice = null;
      _previewBytes = null;
      _savedEntry = null;
      _hideFloatingCard = true;
      _error = null;
      _captureSource = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_deleteSavedMessage())));
  }

  bool _isZh() => Localizations.localeOf(context).languageCode.startsWith('zh');

  Future<void> _editFoodName() async {
    if (_analysis == null) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    if (!await _ensureFeatureAccess(app, AppFeature.analyze)) return;
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    final controller = TextEditingController(text: _analysis!.result.foodName);
    Timer? debounce;
    var requestToken = 0;
    var suggestions = <FoodNameSuggestion>[];
    var isSearching = false;

    Future<void> refreshSuggestions(
      String keyword,
      BuildContext dialogContext,
      void Function(VoidCallback fn) setDialogState,
    ) async {
      final query = keyword.trim();
      final token = ++requestToken;

      if (query.isEmpty) {
        if (!dialogContext.mounted) return;
        setDialogState(() {
          suggestions = const [];
          isSearching = false;
        });
        return;
      }

      if (dialogContext.mounted) {
        setDialogState(() => isSearching = true);
      }

      final result = await app.suggestFoodNameOptions(query, locale, limit: 24);
      if (!dialogContext.mounted || token != requestToken) return;

      setDialogState(() {
        suggestions = result;
        isSearching = false;
      });
    }

    final result = await showDialog<FoodNameInputResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final hasInput = controller.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text(t.editFoodName),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: t.suggestInstantNameHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) {
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 350), () {
                        refreshSuggestions(
                          controller.text,
                          dialogContext,
                          setDialogState,
                        );
                      });
                    },
                    onSubmitted: (value) => Navigator.of(dialogContext).pop(
                      FoodNameInputResult(name: value.trim()),
                    ),
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (hasInput) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: suggestions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Text(
                                isZh
                                    ? '目前沒有資料庫建議，仍可直接送出名稱。'
                                    : 'No database suggestions yet. You can still submit this name.',
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.black54),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                thickness: 0.5,
                              ),
                              itemBuilder: (context, index) {
                                final suggestion = suggestions[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    _suggestionSourceIcon(suggestion.source),
                                    size: 18,
                                  ),
                                  title: Text(suggestion.name),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: suggestion.isCustom
                                          ? const Color(0xFFEAF7EF)
                                          : suggestion.source ==
                                                  FoodNameSuggestionSource
                                                      .catalog
                                              ? const Color(0xFFF2F5F9)
                                              : const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _suggestionSourceLabel(suggestion.source),
                                      style: Theme.of(dialogContext)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: suggestion.isCustom
                                                ? const Color(0xFF2F8F5B)
                                                : suggestion.source ==
                                                        FoodNameSuggestionSource
                                                            .catalog
                                                    ? const Color(0xFF5B6B7A)
                                                    : const Color(0xFF9A6500),
                                          ),
                                    ),
                                  ),
                                  onTap: () => Navigator.of(dialogContext).pop(
                                    FoodNameInputResult(
                                      name: suggestion.name,
                                      selectedSuggestion: suggestion,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(
                  FoodNameInputResult(name: controller.text.trim()),
                ),
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
    debounce?.cancel();
    controller.dispose();
    final nextName = result?.name.trim() ?? '';
    if (nextName.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _instantAdvice = null;
    _startSmartProgress();
    final historyContext = app.buildAiContext();
    try {
      final explicitSuggestion = result?.selectedSuggestion;
      late final QuickCaptureAnalysis updated;
      if (explicitSuggestion?.isCustom == true) {
        final customId = explicitSuggestion!.customFoodId;
        final customFood = app.customFoods.where((food) => food.id == customId);
        if (customFood.isEmpty) {
          throw NameLookupException('custom_not_found');
        }
        updated = QuickCaptureAnalysis(
          file: _analysis!.file,
          originalBytes: _analysis!.originalBytes,
          imageBytes: _analysis!.imageBytes,
          time: _analysis!.time,
          mealType: _analysis!.mealType,
          result: app.buildCustomAnalysisResult(customFood.first),
        );
      } else {
        updated = await app.reanalyzeQuickCapture(
          _analysis!,
          locale,
          historyContext: historyContext.isEmpty ? null : historyContext,
          foodName: nextName,
          containerType: _containerType,
          containerSize: _containerSize,
          referenceObject:
              _referenceObject == 'none' || _referenceObject == 'manual'
                  ? null
                  : _referenceObject,
          referenceLengthCm:
              _referenceObject == 'manual' ? _parsedReferenceLength() : null,
        );
      }
      if (!mounted) return;
      _analysis = updated;
      _applyAnalysisDefaults(updated.result, keepUserSelections: true);
      _hideFloatingCard = false;
      _instantAdvice = null;
      _previewBytes = null;
      await _persistCurrentAnalysis();
      if (!mounted) return;
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
        _error = _analysisErrorMessage(err);
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
                  child: Image.memory(food.imageBytes,
                      width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text(food.name,
                    style: AppTextStyles.body(context)
                        .copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(food.summary,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: Colors.black54)),
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
            final dateLabel =
                '${pickedDate.year}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}';
            final timeLabel = pickedTime.format(context);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.customConfirmTitle,
                      style: AppTextStyles.title2(context)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('${t.customConfirmDate}:',
                          style: AppTextStyles.body(context)
                              .copyWith(fontWeight: FontWeight.w600)),
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
                      Text('${t.customConfirmTime}:',
                          style: AppTextStyles.body(context)
                              .copyWith(fontWeight: FontWeight.w600)),
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
                      Text('${t.customConfirmMealType}:',
                          style: AppTextStyles.body(context)
                              .copyWith(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final result =
                              await _showMealTypePicker(app, t, pickedMealType);
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

  Future<MealType?> _showMealTypePicker(
      AppState app, AppLocalizations t, MealType current) async {
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
                trailing: option == current
                    ? const Text('✅', style: TextStyle(fontSize: 16))
                    : null,
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
      if (_startsWithAny(normalized, [
            '搭配',
            '一起搭',
            '可以吃',
            '建議吃',
            '適合吃',
            '可吃',
            '可以怎麼吃',
            '可以怎麼搭',
            '配一點',
            '加一點',
            '可以喝',
            '建議喝',
            '適合喝',
            '可喝',
            '可以怎麼喝'
          ]) ||
          lower.startsWith('can eat') ||
          lower.startsWith('can drink')) {
        sections['can'] =
            _cleanAdviceValue(_splitAdviceValue(normalized), 'can');
        continue;
      }
      if (_startsWithAny(normalized, [
            '不建議',
            '不建議吃',
            '避免',
            '不推薦',
            '不建議喝',
            '少吃',
            '少喝',
            '避免吃',
            '避免喝',
            '先少一點',
            '先少喝一點',
            '先避開',
            '先跳過',
            '先減少'
          ]) ||
          lower.startsWith('avoid')) {
        sections['avoid'] =
            _cleanAdviceValue(_splitAdviceValue(normalized), 'avoid');
        continue;
      }
      if (_startsWithAny(normalized, [
            '建議份量',
            '建議份量上限',
            '份量上限',
            '上限',
            '份量建議',
            '這樣吃剛好',
            '這樣喝剛好',
            '份量抓這樣'
          ]) ||
          lower.startsWith('portion') ||
          lower.startsWith('limit')) {
        sections['limit'] =
            _cleanAdviceValue(_splitAdviceValue(normalized), 'limit');
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
      '一起搭',
      '可以吃',
      '建議吃',
      '適合吃',
      '可吃',
      '可以怎麼吃',
      '可以怎麼搭',
      '配一點',
      '加一點',
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
      '先少一點',
      '先少喝一點',
      '先避開',
      '先跳過',
      '先減少',
      '建議份量',
      '建議份量上限',
      '份量上限',
      '上限',
      '份量建議',
      '這樣吃剛好',
      '這樣喝剛好',
      '份量抓這樣',
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
        RegExp(r'^(可以|建議|適合)?\s*(搭配|一起搭|配|配一點|加點|加一點|加入|多搭配|多加)\s*'),
        '',
      );
    }
    if (key == 'avoid') {
      cleaned = cleaned.replaceFirst(
          RegExp(r'^(避免|不建議|不推薦|少|盡量少|盡量避免|先少一點|先少喝一點|先避開|先跳過|先減少)\s*'), '');
    }
    if (key == 'limit') {
      cleaned = cleaned.replaceFirst(
          RegExp(r'^(份量|份量上限|建議份量|上限|控制在|這樣吃剛好|這樣喝剛好|份量抓這樣)\s*'), '');
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
                Container(color: Colors.white.withValues(alpha: 0.02)),
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

  void _animateProgress(double target, Duration duration,
      [VoidCallback? onComplete]) {
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
      return Text(t.suggestInstantMissing,
          style:
              AppTextStyles.caption(context).copyWith(color: Colors.black54));
    }
    final suggestion = _analysis!.result.suggestion.trim();
    if (suggestion.isEmpty) {
      return Text(t.suggestInstantMissing,
          style:
              AppTextStyles.caption(context).copyWith(color: Colors.black54));
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
    final canLabel =
        isDrink ? t.suggestInstantCanDrink : t.suggestInstantCanEat;
    final avoidLabel =
        isDrink ? t.suggestInstantAvoidDrink : t.suggestInstantAvoid;
    final limitLabel =
        isDrink ? t.suggestInstantDrinkLimit : t.suggestInstantLimit;
    final secondaryText = isDrink
        ? (limitText.isNotEmpty ? limitText : avoidText)
        : (avoidText.isNotEmpty ? avoidText : limitText);
    final secondaryLabel = isDrink
        ? (_isZh() ? '提醒' : 'Watch')
        : (_isZh() ? '提醒' : 'Watch');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _adviceRow(
          _isZh() ? '建議' : 'Tip',
          canText.isEmpty ? (isDrink ? '-' : '-') : '$canLabel $canText',
        ),
        if (secondaryText.isNotEmpty) ...[
          const SizedBox(height: 8),
          _adviceRow(
            secondaryLabel,
            '${secondaryText == avoidText ? avoidLabel : limitLabel} $secondaryText',
          ),
        ],
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

  Widget _buildSavedStatusRow() {
    if (_savedEntry == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Color(0xFF2F8F5B),
              ),
              const SizedBox(width: 6),
              Text(
                _isZh() ? '已自動存到紀錄' : 'Saved to your log',
                style: AppTextStyles.caption(context).copyWith(
                  color: const Color(0xFF2F8F5B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _analysisSummaryLine(AppState app, AnalysisResult analysis) {
    final proteinValue = (_scaledMacros(analysis.macros)['protein'] ?? 0).round();
    if (analysis.isBeverage == true) {
      return _isZh()
          ? '這杯飲料的熱量主要會被容量、甜度與配料拉高。'
          : 'Drink calories depend on size, sugar, and add-ons.';
    }
    if (proteinValue >= 20) {
      return _isZh()
          ? '這餐蛋白質不錯，熱量重點多半來自主食與醬料。'
          : 'Protein looks solid here; most calories likely come from starch and sauce.';
    }
    if (analysis.foodItems.length >= 3) {
      return _isZh()
          ? '先看份量與醬料，這兩個通常最容易把熱量往上拉。'
          : 'Check portion and sauce first. Those usually drive the calories up.';
    }
    return _isZh()
        ? '先確認名稱與份量，必要時再調整這餐。'
        : 'Check the meal name and portion first, then adjust if needed.';
  }

  String? _confidenceLabel(double? confidence) {
    if (confidence == null) return null;
    if (confidence >= 0.8) {
      return _isZh() ? '判讀信心高' : 'High confidence';
    }
    if (confidence >= 0.55) {
      return _isZh() ? '判讀信心中' : 'Medium confidence';
    }
    return _isZh() ? '判讀信心低' : 'Low confidence';
  }

  String _analysisSourceLabel(AnalysisResult analysis) {
    final source = analysis.source.trim().toLowerCase();
    if (source == 'custom') {
      return _isZh() ? '自訂資料' : 'Custom data';
    }
    if (source == 'label') {
      return _isZh() ? '營養標示' : 'Nutrition label';
    }
    if (source == 'catalog' || source == 'beverage_formula') {
      return _isZh() ? '資料庫估算' : 'Database estimate';
    }
    return _isZh() ? 'AI估算' : 'AI estimate';
  }

  List<Widget> _buildResultInfoChips(
    AppLocalizations t,
    AnalysisResult analysis,
    String referenceLabel,
    int proteinValue,
  ) {
    final chips = <Widget>[];
    final confidenceLabel = _confidenceLabel(analysis.confidence);
    if (analysis.isBeverage == true) {
      chips.add(_buildSummaryInfoChip(
        icon: Icons.local_drink_rounded,
        label: _isZh() ? '液體熱量' : 'Liquid calories',
      ));
      chips.add(_buildSummaryInfoChip(
        icon: Icons.straighten_rounded,
        label: _isZh() ? '容量影響大' : 'Size matters',
      ));
      chips.add(_buildSummaryInfoChip(
        icon: Icons.auto_awesome_rounded,
        label: _analysisSourceLabel(analysis),
      ));
      if (confidenceLabel != null) {
        chips.add(_buildSummaryInfoChip(
          icon: Icons.verified_outlined,
          label: confidenceLabel,
        ));
      }
      return chips.take(3).toList();
    }

    if (proteinValue > 0) {
      chips.add(_buildSummaryInfoChip(
        icon: Icons.egg_alt_outlined,
        label: _isZh() ? '蛋白質 $proteinValue g' : 'Protein $proteinValue g',
      ));
    }
    if (referenceLabel != t.referenceObjectNone) {
      chips.add(_buildSummaryInfoChip(
        icon: Icons.straighten_rounded,
        label:
            _isZh() ? '參考：$referenceLabel' : 'Reference: $referenceLabel',
      ));
    }
    if (confidenceLabel != null) {
      chips.add(_buildSummaryInfoChip(
        icon: Icons.verified_outlined,
        label: confidenceLabel,
      ));
    } else {
      chips.add(_buildSummaryInfoChip(
        icon: Icons.auto_awesome_rounded,
        label: _analysisSourceLabel(analysis),
      ));
    }
    return chips;
  }

  Widget _buildSummaryInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption(context).copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAdvicePanel(AppLocalizations t, AnalysisResult analysis) {
    final title = analysis.isBeverage == true
        ? t.suggestInstantDrinkAdviceTitle
        : t.suggestInstantAdviceTitle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFF2F8F5B),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAdviceCard(t),
        ],
      ),
    );
  }

  Future<void> _showAdjustAnalysisSheet() async {
    if (_analysis == null || !mounted) return;
    final t = AppLocalizations.of(context)!;
    final app = AppStateScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            final currentAnalysis = _analysis?.result;
            if (currentAnalysis == null) {
              return const SizedBox.shrink();
            }
            final staleAdviceMessage =
                _adviceNeedsReestimate ? _staleAdviceMessage() : null;
            final adjustedRange = _displayCalorieRange ??
                _scaledCalorieRangeText(
                  _overrideCalorieRange ?? currentAnalysis.calorieRange,
                  _portionPercent,
                  containerType: _containerType,
                  containerSize: _containerSize,
                );
            final proteinRange = app.proteinTargetRangeGrams();
            final baseProteinConsumed =
                app.dailyProteinConsumedGrams((_analysis?.time ?? DateTime.now()));
            final adjustedMacros = _scaledMacros(currentAnalysis.macros);
            final currentProtein =
                _savedEntry == null ? (adjustedMacros['protein'] ?? 0) : 0;
            final proteinConsumed = (baseProteinConsumed + currentProtein).round();

            Future<void> runAndRefresh(Future<void> Function() action) async {
              await action();
              if (sheetContext.mounted) {
                sheetSetState(() {});
              }
            }

            void refreshSheet() {
              if (sheetContext.mounted) {
                sheetSetState(() {});
              }
            }

            return SafeArea(
              top: false,
              child: FractionallySizedBox(
                heightFactor: 0.84,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isZh() ? '調整這餐' : 'Adjust this meal',
                                style: AppTextStyles.title2(context)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: t.cancel,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentAnalysis.foodName,
                                style: AppTextStyles.body(context)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$adjustedRange ${t.estimated}',
                                style: AppTextStyles.title2(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPortionContainerSection(
                                t,
                                onInteractionComplete: refreshSheet,
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        await _editCalorieRange();
                                        refreshSheet();
                                      },
                                icon: const Icon(Icons.edit_outlined),
                                label: Text(_isZh()
                                    ? '手動校正熱量'
                                    : 'Adjust calorie estimate'),
                              ),
                              if (proteinRange != null) ...[
                                const SizedBox(height: 12),
                                _buildProteinRangeBar(
                                  t,
                                  proteinConsumed.toDouble(),
                                  proteinRange,
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildMacroSection(t, currentAnalysis),
                              if (staleAdviceMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF6E8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFF4D29A),
                                    ),
                                  ),
                                  child: Text(
                                    staleAdviceMessage,
                                    style: AppTextStyles.caption(context).copyWith(
                                      color: const Color(0xFF8A5A00),
                                      height: 1.35,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () async {
                                          await runAndRefresh(
                                              _reanalyzeWithAdjustments);
                                        },
                                  icon: const Icon(Icons.auto_fix_high_rounded),
                                  label: Text(_isZh()
                                      ? '重新估算建議'
                                      : 'Reestimate advice'),
                                ),
                              ),
                              if (_savedEntry != null) ...[
                                const SizedBox(height: 20),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      Navigator.of(sheetContext).pop();
                                      await Future<void>.delayed(Duration.zero);
                                      if (!mounted) return;
                                      await _deleteSavedEntry();
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    label: Text(_isZh()
                                        ? '刪除這筆紀錄'
                                        : 'Delete this entry'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFB94A48),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _adviceRow(String title, String? value) {
    final displayTitle = _labelWithColon(title);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayTitle,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value ?? '-',
              style: AppTextStyles.caption(context)
                  .copyWith(color: Colors.black87, height: 1.4)),
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

  void _syncAdviceRefreshState() {
    _adviceNeedsReestimate = _portionPercent != _lastAnalyzedPortionPercent ||
        _containerType != _lastAnalyzedContainerType ||
        _containerSize != _lastAnalyzedContainerSize ||
        _overrideCalorieRange != _lastAnalyzedCalorieOverride;
  }

  MealType _analysisMealType(AppState app) {
    if (_savedEntry != null) return _savedEntry!.type;
    if (_analysis != null) return _analysis!.mealType;
    return app.resolveMealType(DateTime.now());
  }

  String? _analysisMealId() => _savedEntry?.mealId ?? _savedEntry?.id;

  String _staleAdviceMessage() {
    return _isZh()
        ? '目前卡片數值已依調整更新，建議內容仍以原始分析為主；如需同步更新，請點「重新估算」。'
        : 'Card values already reflect your adjustments. Advice still uses the original analysis until you tap Reestimate.';
  }

  void _applyAnalysisDefaults(AnalysisResult result,
      {bool keepUserSelections = false}) {
    final normalized = _normalizeContainerSelection(
        result.containerGuessType, result.containerGuessSize);
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
    _lastAnalyzedPortionPercent = _portionPercent;
    _lastAnalyzedContainerType = _containerType;
    _lastAnalyzedContainerSize = _containerSize;
    _lastAnalyzedCalorieOverride = _overrideCalorieRange;
    _syncAdviceRefreshState();
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
      _syncAdviceRefreshState();
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
      _syncAdviceRefreshState();
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
      _syncAdviceRefreshState();
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
    final controller = TextEditingController(
        text: _overrideCalorieRange ?? _analysis?.result.calorieRange ?? '');
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
      _syncAdviceRefreshState();
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
            labelStyle: AppTextStyles.caption(context)
                .copyWith(fontWeight: FontWeight.w600),
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
    return const Text('🔹', style: TextStyle(fontSize: 18, height: 1));
  }

  Widget _buildPortionContainerSection(
    AppLocalizations t, {
    VoidCallback? onInteractionComplete,
  }) {
    final theme = Theme.of(context);
    final normalized =
        _normalizeContainerSelection(_containerType, _containerSize);
    final currentType = normalized[0];
    final currentSize = normalized[1];
    final isDrink = _analysis?.result.isBeverage == true;
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final typeOptions = <_IconChipOption>[
      _IconChipOption(
          emoji: '🥣',
          value: 'bowl',
          label: t.containerTypeBowl,
          showLabel: false),
      _IconChipOption(
          emoji: '🍽️',
          value: 'plate',
          label: t.containerTypePlate,
          showLabel: false),
      _IconChipOption(
          emoji: '🍱',
          value: 'box',
          label: t.containerTypeBox,
          showLabel: false),
      _IconChipOption(
          emoji: '🥤',
          value: 'cup',
          label: t.containerTypeCup,
          showLabel: false),
      _IconChipOption(
          emoji: '❓',
          value: 'unknown',
          label: t.containerTypeUnknown,
          showLabel: false),
    ];

    String sizeWithMl(String baseLabel, int ml) {
      if (!isDrink) return baseLabel;
      return isZh ? '$baseLabel 約 $ml ml' : '$baseLabel (~$ml ml)';
    }

    final sizeOptions = <MapEntry<String, String>>[
      MapEntry(sizeWithMl(t.containerSizeSmall, 400), 'small'),
      MapEntry(sizeWithMl(t.containerSizeMedium, 500), 'medium'),
      MapEntry(sizeWithMl(t.containerSizeLarge, 625), 'large'),
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
        Text(t.portionLabel,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('$_portionPercent%',
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: _portionPercent.toDouble(),
                  min: 10,
                  max: 200,
                  divisions: 19,
                  label: '$_portionPercent%',
                  onChanged: (value) {
                    _updatePortionPercent(value.round());
                    onInteractionComplete?.call();
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(t.containerTypeLabel,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _buildIconChipGroup(
          options: typeOptions,
          value: currentType,
          onSelected: (value) {
            _updateContainerType(value);
            onInteractionComplete?.call();
          },
        ),
        const SizedBox(height: 12),
        Text(t.containerSizeLabel,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _buildChipGroup(
          options: sizeOptions,
          value: currentSize,
          onSelected: (value) {
            _updateContainerSize(value);
            onInteractionComplete?.call();
          },
        ),
        if (isDrink) ...[
          const SizedBox(height: 6),
          Text(
            isZh
                ? '杯量為估算值，實際容量會因品牌與容器而有差異。'
                : 'Cup volume is estimated and may vary by brand.',
            style:
                AppTextStyles.caption(context).copyWith(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 12),
        _buildReferenceAdjustSection(
          t,
          referenceOptions,
          onInteractionComplete: onInteractionComplete,
        ),
      ],
    );
  }

  Widget _buildReferenceAdjustSection(
    AppLocalizations t,
    List<MapEntry<String, String>> referenceOptions, {
    VoidCallback? onInteractionComplete,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 6),
      title: Text(
        t.referenceObjectLabel,
        style:
            AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        t.referenceLengthHint,
        style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _buildChipGroup(
            options: referenceOptions,
            value: _referenceObject,
            onSelected: (value) async {
              await _updateReferenceObject(value);
              onInteractionComplete?.call();
            },
          ),
        ),
        if (_referenceObject == 'manual') ...[
          const SizedBox(height: 10),
          Text(t.referenceLengthLabel,
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _referenceLengthController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: t.referenceLengthHint),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        await _updateReferenceLength();
                        onInteractionComplete?.call();
                      },
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
        return hasKcal
            ? '$scaledLow-$scaledHigh kcal'
            : '$scaledLow-$scaledHigh';
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

  double? _recentMealAverage(AppState app,
      {MealType? mealType, String? excludeMealId}) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final groups = <String, List<MealEntry>>{};
    for (final entry in app.entries) {
      if (entry.time.isBefore(cutoff)) continue;
      if (mealType != null && entry.type != mealType) continue;
      final key = entry.mealId ?? entry.id;
      if (excludeMealId != null && key == excludeMealId) continue;
      groups.putIfAbsent(key, () => []).add(entry);
    }
    if (groups.isEmpty) return null;
    final mealTotals = <double>[];
    for (final group in groups.values) {
      double total = 0;
      for (final entry in group) {
        final baseRange = entry.overrideCalorieRange ??
            entry.labelResult?.calorieRange ??
            entry.result?.calorieRange;
        final mid = _rangeMidValue(baseRange);
        if (mid == null) continue;
        final portion = entry.portionPercent.clamp(10, 200) / 100.0;
        final factor = portion *
            _containerSizeFactorFor(entry.containerSize) *
            _containerTypeFactorFor(entry.containerType);
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

  Widget _buildEnergyBar(
      AppState app, AppLocalizations t, AnalysisResult analysis) {
    final current =
        _calorieMidValue(_overrideCalorieRange ?? analysis.calorieRange);
    if (current == null || current <= 0) return const SizedBox.shrink();
    final mealType = _analysisMealType(app);
    final excludeMealId = _analysisMealId();
    final avg = _recentMealAverage(
          app,
          mealType: mealType,
          excludeMealId: excludeMealId,
        ) ??
        _recentMealAverage(app, excludeMealId: excludeMealId);
    if (avg == null || avg <= 0) return const SizedBox.shrink();
    final ratio = current / avg;
    String message;
    IconData icon;
    Color color;
    if (ratio >= 1.18) {
      message = _isZh() ? '比你最近同類餐點偏高一些' : 'A bit higher than your recent similar meals';
      icon = Icons.trending_up_rounded;
      color = const Color(0xFFC97A2B);
    } else if (ratio <= 0.82) {
      message = _isZh() ? '比你最近同類餐點偏輕一些' : 'A bit lighter than your recent similar meals';
      icon = Icons.trending_down_rounded;
      color = const Color(0xFF2F8F5B);
    } else {
      message = _isZh() ? '接近你最近同類餐點的常見範圍' : 'Close to your recent usual range';
      icon = Icons.check_circle_outline_rounded;
      color = const Color(0xFF4B8A6A);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption(context).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinRangeBar(
      AppLocalizations t, double consumed, List<int> range) {
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
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${consumed.round()}g',
              style: AppTextStyles.caption(context)
                  .copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final rangeLeft = width * startRatio;
            final rangeWidth = width * (endRatio - startRatio);
            final indicatorLeft =
                (width * currentRatio).clamp(0.0, width - indicatorSize);
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
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.35),
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
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
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
            Text('${range[0]}g',
                style: AppTextStyles.caption(context)
                    .copyWith(color: Colors.black45)),
            const Spacer(),
            Text('${range[1]}g',
                style: AppTextStyles.caption(context)
                    .copyWith(color: Colors.black45)),
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
        Text(t.macroLabel,
            style: AppTextStyles.body(context)
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        NutritionChart(
          macros: adjusted,
          style: NutritionChartStyle.donut,
          t: t,
          valueMode: NutritionValueMode.amount,
          calories:
              _calorieMidValue(_overrideCalorieRange ?? analysis.calorieRange),
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
        final factor =
            percent * _containerSizeFactor() * _containerTypeFactor();
        return ((low + high) / 2) * factor;
      }
    }
    final single = RegExp(r'(\d+)').firstMatch(normalized);
    if (single != null) {
      final value = double.tryParse(single.group(1) ?? '');
      if (value != null) {
        final percent = _portionPercent.clamp(10, 200) / 100.0;
        final factor =
            percent * _containerSizeFactor() * _containerTypeFactor();
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
        referenceObject:
            _referenceObject == 'none' || _referenceObject == 'manual'
                ? null
                : _referenceObject,
        referenceLengthCm:
            _referenceObject == 'manual' ? _parsedReferenceLength() : null,
      );
      if (!mounted) return;
      _analysis = updated;
      _applyAnalysisDefaults(updated.result, keepUserSelections: true);
      _hideFloatingCard = false;
      _instantAdvice = null;
      _previewBytes = null;
      await _persistCurrentAnalysis();
      if (!mounted) return;
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
        _adviceRow(
            '${labels[t.nextSelfCookLabel] ?? ''} ${t.nextSelfCookLabel}'
                .trim(),
            advice.selfCook),
        const SizedBox(height: 8),
        _adviceRow(
            '${labels[t.nextConvenienceLabel] ?? ''} ${t.nextConvenienceLabel}'
                .trim(),
            advice.convenience),
        const SizedBox(height: 8),
        _adviceRow(
            '${labels[t.nextBentoLabel] ?? ''} ${t.nextBentoLabel}'.trim(),
            advice.bento),
        const SizedBox(height: 8),
        _adviceRow(
            '${labels[t.nextOtherLabel] ?? ''} ${t.nextOtherLabel}'.trim(),
            advice.other),
      ],
    );
  }

  Widget _buildAnalysisCardContent(
      AppLocalizations t, AppState app, AnalysisResult analysis) {
    if (analysis.isFood == false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_savedEntry != null) Expanded(child: _buildSavedStatusRow()),
              if (_savedEntry == null) const Spacer(),
              IconButton(
                onPressed: () => setState(() => _hideFloatingCard = true),
                icon: const Icon(Icons.close_rounded),
                tooltip: t.cancel,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.no_food_rounded, size: 22, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.suggestInstantNonFood,
                  style: AppTextStyles.body(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if ((analysis.nonFoodReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              analysis.nonFoodReason!.trim(),
              style: AppTextStyles.caption(context)
                  .copyWith(color: Colors.black54, height: 1.4),
            ),
          ],
          if (_savedEntry != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _deleteSavedEntry,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(_isZh() ? '刪除這筆紀錄' : 'Delete this entry'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB94A48),
                ),
              ),
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
    final adjustedMacros = _scaledMacros(analysis.macros);
    final referenceUsed = (analysis.referenceUsed ?? '').trim();
    final referenceLabel =
        referenceUsed.isEmpty ? t.referenceObjectNone : referenceUsed;
    final staleAdviceMessage =
        _adviceNeedsReestimate ? _staleAdviceMessage() : null;
    final summaryLine = _analysisSummaryLine(app, analysis);
    final proteinValue = (adjustedMacros['protein'] ?? 0).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_savedEntry != null) Expanded(child: _buildSavedStatusRow()),
            if (_savedEntry == null) const Spacer(),
            IconButton(
              onPressed: () => setState(() => _hideFloatingCard = true),
              icon: const Icon(Icons.close_rounded),
              tooltip: t.cancel,
            ),
          ],
        ),
        Text(
          analysis.foodName,
          style: AppTextStyles.title2(context)
              .copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                adjustedRange,
                textAlign: TextAlign.center,
                style: AppTextStyles.title1(context).copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.estimated,
                style: AppTextStyles.caption(context).copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Color(0xFF2F8F5B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                summaryLine,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF235A3D),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        if (staleAdviceMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF4D29A)),
            ),
            child: Text(
              staleAdviceMessage,
              style: AppTextStyles.caption(context).copyWith(
                color: const Color(0xFF8A5A00),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _buildResultInfoChips(t, analysis, referenceLabel, proteinValue),
        ),
        const SizedBox(height: 10),
        _buildEnergyBar(app, t, analysis),
        _buildCompactAdvicePanel(t, analysis),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editFoodName,
                icon: const Icon(Icons.edit_outlined),
                label: Text(_isZh() ? '改名稱' : 'Rename'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAdjustAnalysisSheet,
                icon: const Icon(Icons.tune_rounded),
                label: Text(_isZh() ? '調整這餐' : 'Adjust meal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final app = AppStateScope.of(context);
    final canAnalyze = app.canUseFeature(AppFeature.analyze);
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    final plateAsset = app.profile.plateAsset.isEmpty
        ? kDefaultPlateAsset
        : app.profile.plateAsset;
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
                padding: EdgeInsets.fromLTRB(16, 16, 16,
                    (showFloatingCard || showAdviceCard) ? 260 : 16),
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
                          style: AppTextStyles.caption(context)
                              .copyWith(color: Colors.black54),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.22),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: contentVerticalPadding),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
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
                                                      opacity: _loading
                                                          ? _progressValue
                                                              .clamp(0.0, 1.0)
                                                          : 1.0,
                                                      duration: const Duration(
                                                          milliseconds: 200),
                                                      child: PlatePhoto(
                                                        imageBytes: _analysis
                                                                ?.imageBytes ??
                                                            _previewBytes!,
                                                        plateAsset: plateAsset,
                                                        plateSize: plateSize,
                                                        imageSize: imageSize,
                                                        tilt: 0,
                                                      ),
                                                    ),
                                                    if (_loading)
                                                      _buildScanOverlay(
                                                          plateSize),
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
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha:
                                                                        0.12),
                                                            blurRadius: 26,
                                                            offset:
                                                                const Offset(
                                                                    0, 16),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Image.asset(plateAsset,
                                                        fit: BoxFit.contain),
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
                                              final statusText = steps[
                                                  _statusIndex % steps.length];
                                              final percent =
                                                  (_progressValue * 100)
                                                      .clamp(0, 100)
                                                      .round();
                                              return Column(
                                                children: [
                                                  Text(
                                                    '$percent%',
                                                    style: AppTextStyles.body(
                                                            context)
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    statusText,
                                                    style: AppTextStyles
                                                            .caption(context)
                                                        .copyWith(
                                                            color:
                                                                Colors.black54),
                                                  ),
                                                ],
                                              );
                                            })
                                          else
                                            Center(
                                              child: SizedBox(
                                                width: buttonWidth,
                                                child: ElevatedButton.icon(
                                                  onPressed: canAnalyze
                                                      ? _startCaptureFromCamera
                                                      : () async {
                                                          await _ensureFeatureAccess(
                                                              app,
                                                              AppFeature
                                                                  .analyze);
                                                        },
                                                  icon: const Text('📷',
                                                      style: TextStyle(
                                                          fontSize: 18)),
                                                  label: Text(
                                                    canAnalyze
                                                        ? (_analysis == null
                                                            ? t
                                                                .suggestInstantStart
                                                            : t
                                                                .suggestInstantRetake)
                                                        : (isZh
                                                            ? '立即解鎖拍照分析'
                                                            : 'Unlock photo analysis'),
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: canAnalyze
                                                        ? theme
                                                            .colorScheme.primary
                                                        : Colors.white
                                                            .withValues(
                                                                alpha: 0.94),
                                                    foregroundColor: canAnalyze
                                                        ? Colors.white
                                                        : theme.colorScheme
                                                            .primary,
                                                    side: BorderSide(
                                                      color: canAnalyze
                                                          ? theme.colorScheme
                                                              .primary
                                                          : theme.colorScheme
                                                              .primary
                                                              .withValues(
                                                                  alpha: 0.45),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (_error != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              _error!,
                                              style:
                                                  AppTextStyles.caption(context)
                                                      .copyWith(
                                                          color:
                                                              Colors.redAccent),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                          if (!canAnalyze) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              isZh
                                                  ? '你仍可使用「輸入名稱」與「自訂義」功能'
                                                  : 'You can still use name input and custom foods.',
                                              style:
                                                  AppTextStyles.caption(context)
                                                      .copyWith(
                                                          color:
                                                              Colors.black54),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                          const SizedBox(height: 10),
                                          Center(
                                            child: SizedBox(
                                              width: buttonWidth,
                                              child: OutlinedButton.icon(
                                                onPressed:
                                                    _startCaptureFromGallery,
                                                icon: const Text('🖼️',
                                                    style: TextStyle(
                                                        fontSize: 18)),
                                                label: Text(
                                                    t.suggestInstantPickGallery,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      theme.colorScheme.primary,
                                                  side: BorderSide(
                                                      color: theme
                                                          .colorScheme.primary),
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
                                                icon: const Text('🍽️',
                                                    style: TextStyle(
                                                        fontSize: 18)),
                                                label: Text(
                                                    isZh
                                                        ? '輸入名稱'
                                                        : 'Enter name',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      theme.colorScheme.primary,
                                                  side: BorderSide(
                                                      color: theme
                                                          .colorScheme.primary),
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
                                                icon: const Text('🔖',
                                                    style: TextStyle(
                                                        fontSize: 18)),
                                                label: Text(
                                                  '${t.customUse} - ${app.customFoods.length}${t.customCountUnit}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      theme.colorScheme.primary,
                                                  side: BorderSide(
                                                      color: theme
                                                          .colorScheme.primary),
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
                            final mealDate =
                                DateTime(now.year, now.month, now.day);
                            final consumed =
                                app.dailyConsumedCalorieMid(mealDate).round();
                            final target = app.targetCalorieMid(mealDate);
                            final remaining = target == null
                                ? null
                                : (target - consumed).round();
                            final info = app.lastMealInfo(now);
                            final lastTime =
                                info['last_meal_time']?.toString() ?? '-';
                            final fasting =
                                info['fasting_hours']?.toString() ?? '-';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Debug: remaining=${remaining ?? '-'} kcal | last=$lastTime | fasting=${fasting}h',
                                style: AppTextStyles.caption(context)
                                    .copyWith(color: Colors.black45),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              if (showFloatingCard)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        maxHeight: media.size.height * 0.72,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                          child: _buildAnalysisCardContent(t, app, analysis),
                        ),
                      ),
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
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                          bottom: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
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
                              onPressed: () =>
                                  setState(() => _instantAdvice = null),
                              icon: const Text('??',
                                  style: TextStyle(fontSize: 16)),
                              tooltip: t.cancel,
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
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
                                  style: AppTextStyles.body(context)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                _buildInstantAdviceFromModel(
                                    t, _instantAdvice!),
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
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final progressPaint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final spinnerPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
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
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.color != color;
  }
}
