import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/plate_photo.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final ImagePicker _picker = ImagePicker();
  QuickCaptureAnalysis? _analysis;
  bool _loading = false;
  String? _error;
  bool _showSaveActions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCapture());
  }

  Future<void> _startCapture() async {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _analysis = null;
      _showSaveActions = false;
    });
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    if (file == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      setState(() {
        _analysis = analysis;
        _loading = false;
        _showSaveActions = true;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
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
    final historyContext = app.buildAiContext();
    try {
      final updated = await app.reanalyzeQuickCapture(
        _analysis!,
        locale,
        historyContext: historyContext.isEmpty ? null : historyContext,
        foodName: result.trim(),
      );
      if (!mounted) return;
      setState(() {
        _analysis = updated;
        _loading = false;
        _showSaveActions = true;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString();
        _loading = false;
      });
    }
  }

  Map<String, String> _parseAdviceSections(String suggestion) {
    final sections = <String, String>{};
    final lines = suggestion
        .split(RegExp(r'[\\r\\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final line in lines) {
      if (line.startsWith('可以吃') || line.toLowerCase().startsWith('can eat')) {
        sections['can'] = _splitAdviceValue(line);
      } else if (line.startsWith('不建議吃') || line.toLowerCase().startsWith('avoid')) {
        sections['avoid'] = _splitAdviceValue(line);
      } else if (line.startsWith('份量上限') || line.toLowerCase().startsWith('portion')) {
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
    final app = AppStateScope.of(context);
    final plateAsset = app.profile.plateAsset.isEmpty ? kDefaultPlateAsset : app.profile.plateAsset;
    final analysis = _analysis?.result;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.suggestTitle),
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
                  Text(t.suggestTitle, style: AppTextStyles.title1(context)),
                  const SizedBox(height: 6),
                  Text(t.suggestInstantHint, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                  const SizedBox(height: 18),
                  if (_analysis != null)
                    Center(
                      child: PlatePhoto(
                        imageBytes: _analysis!.imageBytes,
                        plateAsset: plateAsset,
                        plateSize: 260,
                        imageSize: 185,
                        tilt: 0,
                      ),
                    )
                  else
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.black.withOpacity(0.35), size: 48),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Text(_error!, style: AppTextStyles.caption(context).copyWith(color: Colors.redAccent))
                  else
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _startCapture,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_analysis == null ? t.suggestInstantStart : t.suggestInstantRetake),
                      ),
                    ),
                  const SizedBox(height: 16),
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
