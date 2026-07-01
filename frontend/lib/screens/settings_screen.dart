import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/feature_flags.dart';
import '../config/legal_links.dart';
import '../utils/data_exporter.dart';
import '../design/theme_controller.dart';
import '../state/app_state.dart';
import '../widgets/app_background.dart';
import '../widgets/backup_password_prompt.dart';
import '../widgets/subscription_paywall.dart';
import '../design/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _skeletonBar(double width, {double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _skeletonBar(120, height: 22),
        const SizedBox(height: 12),
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.black12.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        _skeletonBar(180),
        const SizedBox(height: 8),
        _skeletonBar(260),
        const SizedBox(height: 10),
        _skeletonBar(220),
        const SizedBox(height: 10),
        _skeletonBar(200),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 10),
      child: Text(
        text,
        style: AppTextStyles.title2(context).copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  List<Widget> _spacedChildren(List<Widget> children, {double gap = 8}) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i != children.length - 1) {
        result.add(SizedBox(height: gap));
      }
    }
    return result;
  }

  Widget _sectionCard(
    BuildContext context, {
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _rowsCard(
    BuildContext context, {
    required List<Widget> rows,
    double gap = 8,
  }) {
    return _sectionCard(
      context,
      children: _spacedChildren(rows, gap: gap),
    );
  }

  Widget _sectionHint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.caption(context).copyWith(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String title,
    String value, {
    IconData? icon,
    VoidCallback? onTap,
    bool showChevron = true,
    bool dense = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: dense ? 9 : 11,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (value.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(context).copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
                if (showChevron) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(context).copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _actionRowButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback? onPressed,
    bool destructive = false,
    bool filled = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = destructive ? scheme.error : scheme.primary;
    final background = destructive
        ? scheme.error.withValues(alpha: 0.08)
        : scheme.primary.withValues(alpha: 0.08);

    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: foreground,
            backgroundColor: background,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(title),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: foreground.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(title),
      ),
    );
  }

  Widget _grid2(List<Widget> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: items[i]),
            const SizedBox(width: 10),
            Expanded(
                child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
          ],
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return Column(children: rows);
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('M/d').format(date.toLocal());
  }

  String _formatBuildTime(String value) {
    if (value.trim().isEmpty) return '--';
    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('yyyy/MM/dd HH:mm').format(date);
    } catch (_) {
      return value;
    }
  }

  Widget _themeButton(
    BuildContext context, {
    required String label,
    required String asset,
    required String currentAsset,
    required ThemeController themeController,
    required AppState app,
  }) {
    final selected = currentAsset == asset;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.primary;
    final previewColors = switch (asset) {
      'assets/themes/theme_clean.json' => [
          const Color(0xFFE6F1FF),
          const Color(0xFF5B7CFA),
          const Color(0xFFF4C95D),
        ],
      'assets/themes/theme_warm.json' => [
          const Color(0xFFFFE8D8),
          const Color(0xFFE8916A),
          const Color(0xFFF1B86A),
        ],
      'assets/themes/theme_green.json' => [
          const Color(0xFFDDF6E5),
          const Color(0xFF5FBF8A),
          const Color(0xFFF4C95D),
        ],
      'assets/themes/theme_pink.json' => [
          const Color(0xFFFDE3F0),
          const Color(0xFFE953A3),
          const Color(0xFFF4C95D),
        ],
      _ => [
          scheme.primary.withValues(alpha: 0.20),
          scheme.primary,
          scheme.surface,
        ],
    };
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor:
            selected ? color.withValues(alpha: 0.07) : scheme.surface,
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.78)
              : scheme.outline.withValues(alpha: 0.16),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        themeController.loadFromAsset(asset);
        app.updateField((p) => p.themeAsset = asset);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check_circle, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final previewColor in previewColors) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: previewColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                if (previewColor != previewColors.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _mealTimeSummary(BuildContext context, UserProfile profile) {
    return '${profile.breakfastStart.format(context)} - ${profile.lateSnackEnd.format(context)}';
  }

  Future<void> _showMealTimeSheet(
    BuildContext context,
    AppLocalizations t,
    AppState app,
  ) async {
    final isZh = app.profile.language == 'zh-TW';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        return AnimatedBuilder(
          animation: app,
          builder: (context, _) {
            final profile = app.profile;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.mealTimeSection,
                                    style: AppTextStyles.title2(sheetContext),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isZh
                                        ? '調整每一餐的開始與結束時間，讓提醒與總結更貼近你的作息。'
                                        : 'Adjust the start and end time for each meal window.',
                                    style: AppTextStyles.caption(sheetContext)
                                        .copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _grid2([
                          _row(
                            sheetContext,
                            t.breakfastStartLabel,
                            profile.breakfastStart.format(sheetContext),
                            icon: Icons.wb_sunny_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.breakfastStart,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.breakfastStart = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.breakfastEndLabel,
                            profile.breakfastEnd.format(sheetContext),
                            icon: Icons.wb_sunny_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.breakfastEnd,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.breakfastEnd = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.brunchStartLabel,
                            profile.brunchStart.format(sheetContext),
                            icon: Icons.coffee_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.brunchStart,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.brunchStart = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.brunchEndLabel,
                            profile.brunchEnd.format(sheetContext),
                            icon: Icons.coffee_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.brunchEnd,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.brunchEnd = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.lunchStartLabel,
                            profile.lunchStart.format(sheetContext),
                            icon: Icons.lunch_dining,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.lunchStart,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.lunchStart = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.lunchEndLabel,
                            profile.lunchEnd.format(sheetContext),
                            icon: Icons.lunch_dining,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.lunchEnd,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.lunchEnd = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.afternoonTeaStartLabel,
                            profile.afternoonTeaStart.format(sheetContext),
                            icon: Icons.local_cafe_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.afternoonTeaStart,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.afternoonTeaStart = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.afternoonTeaEndLabel,
                            profile.afternoonTeaEnd.format(sheetContext),
                            icon: Icons.local_cafe_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.afternoonTeaEnd,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.afternoonTeaEnd = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.dinnerStartLabel,
                            profile.dinnerStart.format(sheetContext),
                            icon: Icons.dinner_dining,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.dinnerStart,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.dinnerStart = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.dinnerEndLabel,
                            profile.dinnerEnd.format(sheetContext),
                            icon: Icons.dinner_dining,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.dinnerEnd,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.dinnerEnd = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.lateSnackStartLabel,
                            profile.lateSnackStart.format(sheetContext),
                            icon: Icons.nightlight_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.lateSnackStart,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.lateSnackStart = time),
                            ),
                          ),
                          _row(
                            sheetContext,
                            t.lateSnackEndLabel,
                            profile.lateSnackEnd.format(sheetContext),
                            icon: Icons.nightlight_outlined,
                            onTap: () => _pickTime(
                              sheetContext,
                              initial: profile.lateSnackEnd,
                              onSave: (time) => app.updateMealTimeField(
                                  (p) => p.lateSnackEnd = time),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _weekdayLabel(int weekday, AppLocalizations t) {
    switch (weekday) {
      case DateTime.monday:
        return t.weekdayMon;
      case DateTime.tuesday:
        return t.weekdayTue;
      case DateTime.wednesday:
        return t.weekdayWed;
      case DateTime.thursday:
        return t.weekdayThu;
      case DateTime.friday:
        return t.weekdayFri;
      case DateTime.saturday:
        return t.weekdaySat;
      case DateTime.sunday:
      default:
        return t.weekdaySun;
    }
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initial,
    required ValueChanged<String> onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initial);
    final t = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel)),
          ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(t.save)),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  Future<void> _showResetPasswordDialog(
      BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.syncResetPasswordTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: t.syncResetPasswordHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel)),
          ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(t.save)),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await app.resetSupabasePassword(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.syncResetPasswordSent)));
      }
    }
  }

  Future<void> _openExternalLink(
    BuildContext context,
    Uri uri, {
    required String errorMessage,
  }) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _selectOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSave,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Text(title,
                style: AppTextStyles.body(context)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final option in options)
              ListTile(
                title: Text(option),
                trailing: option == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) {
      onSave(result);
    }
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSave,
  }) async {
    final result = await showTimePicker(context: context, initialTime: initial);
    if (result != null) onSave(result);
  }

  Future<void> _pickChatAvatar(AppState app) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 92,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) return;
    await app.updateChatAvatar(bytes);
  }

  Future<void> _showChatAvatarSheet(
    BuildContext context,
    AppState app,
    AppLocalizations t,
  ) async {
    final hasAvatar =
        app.chatAvatarBytes != null && app.chatAvatarBytes!.isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.chatAvatarSheetTitle,
              style: AppTextStyles.body(context)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.chatAvatarPick),
              onTap: () => Navigator.of(context).pop('pick'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t.chatAvatarRemove),
              enabled: hasAvatar,
              onTap:
                  hasAvatar ? () => Navigator.of(context).pop('remove') : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      if (action == 'pick') {
        await _pickChatAvatar(app);
      } else if (action == 'remove') {
        await app.updateChatAvatar(null);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.syncError)),
        );
      }
    }
  }

  Future<Map<String, String>?> _loadVersionInfo() async {
    if (!kIsWeb) return null;
    try {
      final uri = Uri.base.resolve('version.json');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final commit = (data['commit'] as String?) ?? '';
      final build = (data['build_time'] as String?) ?? '';
      return {
        'commit': commit,
        'build_time': build,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _showSupabaseAuthDialog(
    BuildContext context,
    AppState app, {
    required bool isSignUp,
  }) async {
    final t = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nicknameController = TextEditingController(text: app.profile.name);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSignUp ? t.syncAuthTitleSignUp : t.syncAuthTitleSignIn),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.syncEmailLabel),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: t.syncPasswordLabel),
            ),
            if (isSignUp)
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(labelText: t.nicknameLabel),
              ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isSignUp ? t.syncSignUp : t.syncSignIn),
          ),
        ],
      ),
    );
    if (result != true) return;
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = nicknameController.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    try {
      if (isSignUp) {
        if (nickname.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(t.authNicknameRequired)));
          }
          return;
        }
        await app.signUpSupabase(email, password, nickname: nickname);
      } else {
        await app.signInSupabase(email, password);
      }
      if (context.mounted) {
        final message = isSignUp ? t.syncSignUpSuccess : t.syncSignInSuccess;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.syncError}: $err')),
        );
      }
    }
  }

  Future<void> _runSupabaseSync(
    BuildContext context,
    AppState app,
  ) async {
    final t = AppLocalizations.of(context)!;
    if (!app.isSupabaseSignedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.syncRequireLogin)));
      return;
    }
    if (app.syncInProgress) return;
    app.setSyncInProgress(true);
    try {
      final changed = await app.syncAuto();
      if (context.mounted) {
        final report = app.lastSyncReport;
        final locale = Localizations.localeOf(context);
        final summary =
            report == null ? null : _buildSyncSummary(report, t, locale);
        final message = changed
            ? (summary == null ? t.syncSuccess : '${t.syncSuccess}: $summary')
            : t.syncNoChanges;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (err) {
      final message = _formatSyncError(err, t);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      app.setSyncInProgress(false);
    }
  }

  String _formatSyncError(Object err, AppLocalizations t) {
    final text = err.toString();
    if (text.contains('not signed in') || text.contains('missing_token')) {
      return t.syncRequireLogin;
    }
    if (text.contains('storage_upload_failed')) {
      return '${t.syncError}: failed to upload data';
    }
    if (text.contains('sync_meta_write_failed')) {
      return '${t.syncError}: failed to write sync metadata';
    }
    if (text.contains('PGRST') || text.contains('Postgrest')) {
      return '${t.syncError}: server error (PostgREST)';
    }
    if (text.contains('SocketException') ||
        text.contains('TimeoutException') ||
        text.contains('timeout')) {
      return '${t.syncError}: network timeout';
    }
    return '${t.syncError}: $text';
  }

  String? _buildSyncSummary(
      SyncReport report, AppLocalizations t, Locale locale) {
    if (!report.hasChanges) return null;
    final isZh = locale.languageCode.startsWith('zh');
    if (isZh) {
      final parts = <String>[];
      if (report.pushedMeals > 0) {
        parts.add('上傳餐點 ${report.pushedMeals}');
      }
      if (report.pushedMealDeletes > 0) {
        parts.add('上傳刪除餐點 ${report.pushedMealDeletes}');
      }
      if (report.pushedCustomFoods > 0) {
        parts.add('上傳自訂食物 ${report.pushedCustomFoods}');
      }
      if (report.pushedCustomDeletes > 0) {
        parts.add('上傳刪除自訂 ${report.pushedCustomDeletes}');
      }
      if (report.pushedSettings > 0) {
        parts.add('上傳設定 ${report.pushedSettings}');
      }
      if (report.pulledMeals > 0) {
        parts.add('下載餐點 ${report.pulledMeals}');
      }
      if (report.pulledMealDeletes > 0) {
        parts.add('下載刪除餐點 ${report.pulledMealDeletes}');
      }
      if (report.pulledCustomFoods > 0) {
        parts.add('下載自訂食物 ${report.pulledCustomFoods}');
      }
      if (report.pulledCustomDeletes > 0) {
        parts.add('下載刪除自訂 ${report.pulledCustomDeletes}');
      }
      if (report.pulledSettings > 0) {
        parts.add('下載設定 ${report.pulledSettings}');
      }
      return parts.join('、');
    }
    final parts = <String>[];
    if (report.pushedMeals > 0) {
      parts.add('upload meals ${report.pushedMeals}');
    }
    if (report.pushedMealDeletes > 0) {
      parts.add('delete meals ${report.pushedMealDeletes}');
    }
    if (report.pushedCustomFoods > 0) {
      parts.add('upload custom ${report.pushedCustomFoods}');
    }
    if (report.pushedCustomDeletes > 0) {
      parts.add('delete custom ${report.pushedCustomDeletes}');
    }
    if (report.pushedSettings > 0) {
      parts.add('upload settings ${report.pushedSettings}');
    }
    if (report.pulledMeals > 0) {
      parts.add('download meals ${report.pulledMeals}');
    }
    if (report.pulledMealDeletes > 0) {
      parts.add('download deleted ${report.pulledMealDeletes}');
    }
    if (report.pulledCustomFoods > 0) {
      parts.add('download custom ${report.pulledCustomFoods}');
    }
    if (report.pulledCustomDeletes > 0) {
      parts.add('download custom deleted ${report.pulledCustomDeletes}');
    }
    if (report.pulledSettings > 0) {
      parts.add('download settings ${report.pulledSettings}');
    }
    return parts.join(', ');
  }

  Future<void> _exportData(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final data = await app.exportData();
    final exporter = createDataExporter();
    await exporter.saveJson('food-ai-export.json', data);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.exportDone)));
    }
  }

  Future<void> _clearData(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.clearData),
        content: Text(t.clearDataConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.clearData)),
        ],
      ),
    );
    if (confirmed == true) {
      await app.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.clearDone)));
      }
    }
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    AppState app,
  ) async {
    final isZh = Localizations.localeOf(context).languageCode.startsWith('zh');
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var canDelete = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(isZh ? '刪除帳號' : 'Delete account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isZh
                      ? '這會永久刪除你的帳號、雲端同步資料與相關紀錄，完成後無法復原。'
                      : 'This permanently deletes your account, synced data, and related records. This action cannot be undone.',
                ),
                const SizedBox(height: 10),
                Text(
                  app.supabaseUserEmail ?? '',
                  style: AppTextStyles.caption(context).copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  onChanged: (value) {
                    final nextCanDelete = value.trim().toUpperCase() == 'DELETE';
                    if (nextCanDelete != canDelete) {
                      setState(() => canDelete = nextCanDelete);
                    }
                  },
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText:
                        isZh ? '輸入 DELETE 以確認' : 'Type DELETE to confirm',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(isZh ? '取消' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: canDelete
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                child: Text(isZh ? '永久刪除' : 'Delete forever'),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) return;
    try {
      await app.deleteSupabaseAccount();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isZh ? '帳號已刪除，這台裝置上的登入也已清除。' : 'Account deleted and local sign-in cleared.',
          ),
        ),
      );
    } catch (err) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isZh ? '刪除帳號失敗：$err' : 'Delete account failed: $err',
          ),
        ),
      );
    }
  }

  Future<void> _showSecuritySheet(BuildContext context, AppState app) async {
    final theme = Theme.of(context);
    final isZh = Localizations.localeOf(context).languageCode.startsWith('zh');
    final email = app.supabaseUserEmail ?? '--';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isZh ? '登入與安全' : 'Sign-in & security',
                  style: AppTextStyles.title2(context),
                ),
                const SizedBox(height: 6),
                Text(
                  isZh
                      ? '管理登入方式、登出與帳號刪除。'
                      : 'Manage sign-in method, sign out, and account deletion.',
                  style: AppTextStyles.caption(context).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZh ? '目前登入帳號' : 'Signed-in email',
                        style: AppTextStyles.caption(context).copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _row(
                  sheetContext,
                  isZh ? '登入密碼' : 'Sign-in password',
                  isZh ? '設定或更新' : 'Set or update',
                  icon: Icons.lock_outline,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await showBackupPasswordSetupDialog(context, app);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await app.signOutSupabase();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(isZh ? '登出' : 'Sign out'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await _showDeleteAccountDialog(context, app);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.36),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(isZh ? '刪除帳號' : 'Delete account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _bmiText(UserProfile profile, AppLocalizations t) {
    if (profile.heightCm <= 0) return '--';
    final heightM = profile.heightCm / 100.0;
    final bmi = profile.weightKg / (heightM * heightM);
    final value = bmi.toStringAsFixed(1);
    String status;
    if (bmi < 18.5) {
      status = t.bmiUnderweight;
    } else if (bmi < 24) {
      status = t.bmiNormal;
    } else if (bmi < 27) {
      status = t.bmiOverweight;
    } else {
      status = t.bmiObese;
    }
    return '$value ($status)';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final themeController = ThemeScope.of(context);
    final app = AppStateScope.of(context);
    final profile = app.profile;
    if (!app.trialChecked) {
      return AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildSkeleton(),
              ),
            ),
          ),
        ),
      );
    }
    final plateOptions = <String, String>{
      t.plateJapanese02: 'assets/plates/plate_Japanese_02.png',
      t.plateJapanese04: 'assets/plates/plate_Japanese_04.png',
      t.plateChina01: 'assets/plates/plate_China_01.png',
      t.plateChina02: 'assets/plates/plate_China_02.png',
    };
    final chartOptions = <String, String>{
      t.chartRadar: 'radar',
      t.chartBars: 'bars',
      t.chartDonut: 'donut',
    };
    final nutritionValueOptions = <String, String>{
      t.nutritionValueAmount: 'amount',
    };
    final currentPlateLabel = plateOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.plateAsset,
          orElse: () => MapEntry(t.plateJapanese02, kDefaultPlateAsset),
        )
        .key;
    final currentChartLabel = chartOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.nutritionChartStyle,
          orElse: () => MapEntry(t.chartRadar, 'radar'),
        )
        .key;
    final currentNutritionValueLabel = nutritionValueOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.nutritionValueMode,
          orElse: () => MapEntry(t.nutritionValueAmount, 'amount'),
        )
        .key;
    final assistantDisplayName = profile.chatAssistantName.trim().isEmpty
        ? t.chatAssistantDefaultName
        : profile.chatAssistantName.trim();
    final hasChatAvatar =
        app.chatAvatarBytes != null && app.chatAvatarBytes!.isNotEmpty;
    final chatAvatarStatus =
        hasChatAvatar ? t.chatAvatarSet : t.chatAvatarUnset;
    final currentThemeAsset = profile.themeAsset;
    final isSubscribed = app.iapSubscriptionActive &&
        (app.accessPlan == 'pro' || app.accessPlan == 'plus');
    final isMockSubscription = app.mockSubscriptionActive;
    const showMockUi = kEnableWebMockSubscription && !kReleaseMode;
    final activeMockSubscription = showMockUi && isMockSubscription;
    final isWhitelisted = app.isWhitelisted;
    final isBackendPaidPlan =
        app.accessPlan == 'pro' || app.accessPlan == 'plus';
    final isTrialExpired = app.trialExpired;
    final trialEndAt = app.trialEndAt;
    final isZh = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('zh');
    final mealCueSectionTitle =
        isZh ? '餐次提示偏好' : 'Meal cue preferences';
    final mealCueSectionHint = isZh
        ? '這些選項只會影響餐次提示與整理邏輯，目前不會發送系統通知。'
        : 'These options only affect meal cues and organization. They do not send system notifications.';
    late final String subscriptionStatus;
    late final Color subscriptionColor;
    if (isSubscribed) {
      subscriptionStatus = isZh ? '已透過 iOS 訂閱' : 'Subscribed (iOS)';
      subscriptionColor = Colors.green;
    } else if (activeMockSubscription) {
      subscriptionStatus = isZh ? '測試訂閱' : 'Test subscription';
      subscriptionColor = Colors.blue;
    } else if (isWhitelisted) {
      subscriptionStatus = isZh ? '白名單' : 'Whitelisted';
      subscriptionColor = Colors.indigo;
    } else if (isBackendPaidPlan) {
      subscriptionStatus = isZh ? '已啟用伺服器方案' : 'Subscribed (server)';
      subscriptionColor = Colors.green;
    } else if (!isTrialExpired) {
      final dateText = _formatDateShort(trialEndAt);
      subscriptionStatus = dateText == '--'
          ? (isZh ? '試用中' : 'Trial active')
          : (isZh ? '試用至 $dateText' : 'Trial until $dateText');
      subscriptionColor = Colors.orange;
    } else {
      subscriptionStatus = isZh ? '已到期' : 'Expired';
      subscriptionColor = Colors.red;
    }
    final subscriptionLabelColor = subscriptionColor.withValues(alpha: 0.9);
    final subscriptionPlanLabel = isSubscribed
        ? (isZh ? 'App Store 方案' : 'App Store')
        : activeMockSubscription
            ? (app.mockSubscriptionPlanId == kIapYearlyId
                ? t.webTestPlanYearly
                : t.webTestPlanMonthly)
            : isWhitelisted
                ? (isZh ? '白名單' : 'Whitelisted')
                : isBackendPaidPlan
                    ? (isZh ? '付費方案' : 'Paid plan')
                    : t.webTestPlanNone;
    final genderOptions = <String, String>{
      t.genderUnspecified: 'unspecified',
      t.genderMale: 'male',
      t.genderFemale: 'female',
      t.genderOther: 'other',
    };
    final currentGenderLabel = genderOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.gender,
          orElse: () => MapEntry(t.genderUnspecified, 'unspecified'),
        )
        .key;
    final containerTypeOptions = <String, String>{
      t.containerTypeBowl: 'bowl',
      t.containerTypePlate: 'plate',
      t.containerTypeBox: 'box',
      t.containerTypeCup: 'cup',
      t.containerTypeUnknown: 'unknown',
    };
    final containerSizeOptions = <String, String>{
      t.containerSizeSmall: 'small',
      t.containerSizeMedium: 'medium',
      t.containerSizeLarge: 'large',
      t.containerSizeCustom: 'custom',
    };
    final containerDepthOptions = <String, String>{
      t.containerDepthShallow: 'shallow',
      t.containerDepthMedium: 'medium',
      t.containerDepthDeep: 'deep',
    };
    final currentContainerTypeLabel = containerTypeOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.containerType,
          orElse: () => MapEntry(t.containerTypeUnknown, 'unknown'),
        )
        .key;
    final currentContainerSizeLabel = containerSizeOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.containerSize,
          orElse: () => MapEntry(t.containerSizeMedium, 'medium'),
        )
        .key;
    final currentContainerDepthLabel = containerDepthOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.containerDepth,
          orElse: () => MapEntry(t.containerDepthMedium, 'medium'),
        )
        .key;
    final dietTypeOptions = <String, String>{
      t.dietTypeNone: 'none',
      t.dietTypeVegetarian: 'vegetarian',
      t.dietTypeVegan: 'vegan',
      t.dietTypePescatarian: 'pescatarian',
      t.dietTypeLowCarb: 'low_carb',
      t.dietTypeKeto: 'keto',
      t.dietTypeLowFat: 'low_fat',
      t.dietTypeHighProtein: 'high_protein',
    };
    final currentDietTypeLabel = dietTypeOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.dietType,
          orElse: () => MapEntry(t.dietTypeNone, 'none'),
        )
        .key;
    final toneOptions = <String, String>{
      t.toneGentle: 'gentle',
      t.toneDirect: 'direct',
      t.toneEncouraging: 'encouraging',
      t.toneBullet: 'bullet',
      t.toneStrict: 'strict',
    };
    final currentToneLabel = toneOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.tone,
          orElse: () => MapEntry(t.toneGentle, 'gentle'),
        )
        .key;
    final personaOptions = <String, String>{
      t.personaNutritionist: 'nutritionist',
      t.personaCoach: 'coach',
      t.personaFriend: 'friend',
      t.personaSystem: 'system',
    };
    final currentPersonaLabel = personaOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.persona,
          orElse: () => MapEntry(t.personaNutritionist, 'nutritionist'),
        )
        .key;
    final weekdayOptions = <String, int>{
      t.weekdayMon: DateTime.monday,
      t.weekdayTue: DateTime.tuesday,
      t.weekdayWed: DateTime.wednesday,
      t.weekdayThu: DateTime.thursday,
      t.weekdayFri: DateTime.friday,
      t.weekdaySat: DateTime.saturday,
      t.weekdaySun: DateTime.sunday,
    };
    final currentWeekdayLabel = _weekdayLabel(profile.weeklySummaryWeekday, t);
    final activityOptions = <String, String>{
      t.activitySedentary: 'sedentary',
      t.activityLight: 'light',
      t.activityModerate: 'moderate',
      t.activityHigh: 'high',
    };
    final exerciseOptions = <String, String>{
      t.exerciseWalking: 'walking',
      t.exerciseJogging: 'jogging',
      t.exerciseCycling: 'cycling',
      t.exerciseSwimming: 'swimming',
      t.exerciseStrength: 'strength',
      t.exerciseYoga: 'yoga',
      t.exerciseHiit: 'hiit',
      t.exerciseBasketball: 'basketball',
      t.exerciseHiking: 'hiking',
      t.exerciseNoExercise: 'none',
    };
    final textSizeOptions = <String, double>{
      t.textSizeSmall: 1.0,
      t.textSizeMedium: 1.1,
      t.textSizeLarge: 1.2,
    };
    final currentTextSizeLabel = textSizeOptions.entries
        .firstWhere(
          (entry) => (profile.textScale - entry.value).abs() < 0.01,
          orElse: () => MapEntry(t.textSizeSmall, 1.0),
        )
        .key;
    final currentActivityLabel = activityOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.activityLevel,
          orElse: () => MapEntry(t.activityLight, 'light'),
        )
        .key;
    final currentExerciseLabel = exerciseOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.exerciseSuggestionType,
          orElse: () => MapEntry(t.exerciseWalking, 'walking'),
        )
        .key;
    final goalOptions = <String, String>{
      t.goalLoseFat: kGoalValueLoseFat,
      t.goalMaintain: kGoalValueMaintain,
    };
    final currentGoalValue = AppState.normalizeGoalValue(profile.goal);
    final currentGoalLabel = goalOptions.entries
        .firstWhere(
          (entry) => entry.value == currentGoalValue,
          orElse: () => MapEntry(t.goalLoseFat, kGoalValueLoseFat),
        )
        .key;
    final planSpeedOptions = <String, String>{
      t.planSpeedStable: kPlanSpeedValueStable,
      t.planSpeedGentle: kPlanSpeedValueGentle,
    };
    final currentPlanSpeedValue =
        AppState.normalizePlanSpeedValue(profile.planSpeed);
    final currentPlanSpeedLabel = planSpeedOptions.entries
        .firstWhere(
          (entry) => entry.value == currentPlanSpeedValue,
          orElse: () => MapEntry(t.planSpeedStable, kPlanSpeedValueStable),
        )
        .key;
    final isSupabaseSignedIn = app.isSupabaseSignedIn;
    final isSyncing = app.syncInProgress;
    final supabaseEmail = app.supabaseUserEmail ?? '';
    final theme = Theme.of(context);
    final syncHeadline = isSupabaseSignedIn
        ? '${t.syncSignedInAs} $supabaseEmail'
        : t.syncNotSignedIn;
    final syncHint = isSupabaseSignedIn
        ? (isZh ? '目前資料會同步到這個帳號。' : 'Your data syncs to this account.')
        : (isZh
            ? '尚未登入，資料只保留在目前裝置。'
            : 'You are not signed in. Data stays on this device.');
    final securityTitle = isZh ? '登入與安全' : 'Sign-in & security';
    final securityValue = isZh ? '管理' : 'Manage';
    final bodyProfileTitle = isZh ? '身體資料' : 'Body profile';
    final goalsTitle = isZh ? '目標設定' : 'Goals';
    final subscriptionHint = isZh
        ? '查看目前方案、試用與白名單狀態。'
        : 'Current plan, trial, and whitelist status.';
    final trialEndsTitle = isZh ? '試用到期' : 'Trial ends';
    final whitelistTitle = isZh ? '白名單' : 'Whitelist';
    final yesText = isZh ? '是' : 'Yes';
    final noText = isZh ? '否' : 'No';
    final testingToolsTitle = isZh ? '測試工具' : 'Testing tools';
    final testPlanTitle = isZh ? '測試方案' : 'Test plan';
    final resetTestSubscriptionTitle =
        isZh ? '重設測試訂閱' : 'Reset test subscription';
    final resetTestSubscriptionDone =
        isZh ? '已清除測試訂閱' : 'Test subscription cleared';
    final notEnabledText = isZh ? '未啟用' : 'Not enabled';
    final syncActionTitle = isZh ? '立即同步' : 'Sync now';
    final syncBusyTitle = isZh ? '同步中' : 'Syncing';
    final subscriptionActionTitle = (isSubscribed ||
            isBackendPaidPlan ||
            isWhitelisted)
        ? (isZh ? '查看方案' : 'View plan')
        : (isZh ? '查看訂閱方案' : 'View plans');
    final developerSectionTitle = isZh ? '開發與測試' : 'Developer & testing';
    final dataSectionHint = isZh
        ? '匯出備份或清除目前裝置上的本機資料。'
        : 'Export a backup or clear the data stored on this device.';
    final canOpenSubscriptionPaywall =
        kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;
    final showDeveloperTools = activeMockSubscription;
    final supportSectionTitle = isZh ? '支援與法律' : 'Support & legal';
    final supportSectionHint = isZh
        ? '打開支援中心、隱私權政策與服務條款。'
        : 'Open support, privacy policy, and terms of service.';
    final supportCenterTitle = isZh ? '支援中心' : 'Support center';
    final privacyPolicyTitle = isZh ? '隱私權政策' : 'Privacy policy';
    final termsOfServiceTitle = isZh ? '服務條款' : 'Terms of service';
    final openLinkError =
        isZh ? '無法開啟連結，請稍後再試。' : 'Unable to open the link right now.';
    final supportUri = supportCenterUriForLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    final privacyUri = privacyPolicyUriForLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    final termsUri = termsOfServiceUriForLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.settingsTitle, style: AppTextStyles.title1(context)),
                  const SizedBox(height: 4),
                  Text(
                    isZh
                        ? '帳號、同步、提醒與外觀都集中整理在這裡。'
                        : 'Account, sync, reminders, and appearance are managed here.',
                    style: AppTextStyles.caption(context).copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle(context, t.syncSection),
                  _sectionCard(
                    context,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    syncHeadline,
                                    style: AppTextStyles.body(context).copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.78),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              syncHint,
                              style: AppTextStyles.caption(context).copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isSupabaseSignedIn) ...[
                        ..._spacedChildren([
                          _row(
                            context,
                            t.nicknameLabel,
                            profile.name.isEmpty ? '--' : profile.name,
                            icon: Icons.badge_outlined,
                            dense: true,
                            onTap: () => _editText(
                              context,
                              title: t.nicknameLabel,
                              initial: profile.name,
                              onSave: (value) => app.updateNickname(value),
                            ),
                          ),
                          _row(
                            context,
                            securityTitle,
                            securityValue,
                            icon: Icons.lock_outline,
                            dense: true,
                            onTap: () => _showSecuritySheet(context, app),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: isSyncing
                                ? null
                                : () => _runSupabaseSync(context, app),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            icon: isSyncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: Text(
                                isSyncing ? syncBusyTitle : syncActionTitle),
                          ),
                        ),
                      ] else ...[
                        _row(
                          context,
                          t.nicknameLabel,
                          profile.name.isEmpty ? '--' : profile.name,
                          icon: Icons.badge_outlined,
                          onTap: () => _editText(
                            context,
                            title: t.nicknameLabel,
                            initial: profile.name,
                            onSave: (value) => app.updateNickname(value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: isSyncing
                                ? null
                                : () => _showSupabaseAuthDialog(
                                      context,
                                      app,
                                      isSignUp: false,
                                    ),
                            child: Text(t.syncSignIn),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: isSyncing
                                ? null
                                : () => _showSupabaseAuthDialog(
                                      context,
                                      app,
                                      isSignUp: true,
                                    ),
                            child: Text(t.syncSignUp),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isSyncing
                                ? null
                                : () => _showResetPasswordDialog(context, app),
                            child: Text(t.syncForgotPassword),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle(context, t.chatSettingsSection),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.chatAssistantNameLabel,
                        assistantDisplayName,
                        icon: Icons.smart_toy_outlined,
                        onTap: () => _editText(
                          context,
                          title: t.chatAssistantNameLabel,
                          initial: profile.chatAssistantName,
                          onSave: (value) => app.updateField(
                            (p) => p.chatAssistantName = value.trim(),
                          ),
                        ),
                      ),
                      _row(
                        context,
                        t.chatAvatarLabel,
                        chatAvatarStatus,
                        icon: Icons.account_circle_outlined,
                        onTap: () => _showChatAvatarSheet(context, app, t),
                      ),
                    ],
                  ),
                  _sectionTitle(context, bodyProfileTitle),
                  _sectionCard(
                    context,
                    children: [
                      _grid2([
                        _row(
                          context,
                          t.heightLabel,
                          '${profile.heightCm} cm',
                          icon: Icons.straighten,
                          onTap: () => _editText(
                            context,
                            title: t.heightLabel,
                            initial: profile.heightCm.toString(),
                            keyboardType: TextInputType.number,
                            onSave: (value) => app.updateField((p) =>
                                p.heightCm = int.tryParse(value) ?? p.heightCm),
                          ),
                        ),
                        _row(
                          context,
                          t.weightLabel,
                          '${profile.weightKg} kg',
                          icon: Icons.monitor_weight,
                          onTap: () => _editText(
                            context,
                            title: t.weightLabel,
                            initial: profile.weightKg.toString(),
                            keyboardType: TextInputType.number,
                            onSave: (value) => app.updateField((p) =>
                                p.weightKg = int.tryParse(value) ?? p.weightKg),
                          ),
                        ),
                        _row(
                          context,
                          t.ageLabel,
                          '${profile.age}',
                          icon: Icons.cake,
                          onTap: () => _editText(
                            context,
                            title: t.ageLabel,
                            initial: profile.age.toString(),
                            keyboardType: TextInputType.number,
                            onSave: (value) => app.updateField(
                              (p) => p.age = int.tryParse(value) ?? p.age,
                            ),
                          ),
                        ),
                        _row(
                          context,
                          t.genderLabel,
                          currentGenderLabel,
                          icon: Icons.wc,
                          onTap: () => _selectOption(
                            context,
                            title: t.genderLabel,
                            current: currentGenderLabel,
                            options: genderOptions.keys.toList(),
                            onSave: (value) => app.updateField((p) => p.gender =
                                genderOptions[value] ?? 'unspecified'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _row(
                        context,
                        t.bmiLabel,
                        _bmiText(profile, t),
                        icon: Icons.analytics,
                        showChevron: false,
                      ),
                    ],
                  ),
                  _sectionTitle(context, goalsTitle),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.goalLabel,
                        currentGoalLabel,
                        icon: Icons.flag,
                        onTap: () => _selectOption(
                          context,
                          title: t.goalLabel,
                          current: currentGoalLabel,
                          options: goalOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.goal = goalOptions[value] ?? kGoalValueLoseFat),
                        ),
                      ),
                      _row(
                        context,
                        t.planSpeedLabel,
                        currentPlanSpeedLabel,
                        icon: Icons.speed,
                        onTap: () => _selectOption(
                          context,
                          title: t.planSpeedLabel,
                          current: currentPlanSpeedLabel,
                          options: planSpeedOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) => p
                                  .planSpeed =
                              planSpeedOptions[value] ?? kPlanSpeedValueStable),
                        ),
                      ),
                      _row(
                        context,
                        t.activityLevelLabel,
                        currentActivityLabel,
                        icon: Icons.directions_walk,
                        onTap: () => _selectOption(
                          context,
                          title: t.activityLevelLabel,
                          current: currentActivityLabel,
                          options: activityOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.activityLevel =
                                  activityOptions[value] ?? 'light'),
                        ),
                      ),
                      _row(
                        context,
                        t.commonExerciseLabel,
                        currentExerciseLabel,
                        icon: Icons.fitness_center,
                        onTap: () => _selectOption(
                          context,
                          title: t.commonExerciseLabel,
                          current: currentExerciseLabel,
                          options: exerciseOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.exerciseSuggestionType =
                                  exerciseOptions[value] ?? 'walking'),
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle(context, t.containerSection),
                  _sectionCard(
                    context,
                    children: [
                      ..._spacedChildren([
                        _row(
                          context,
                          t.containerTypeLabel,
                          currentContainerTypeLabel,
                          icon: Icons.lunch_dining,
                          onTap: () => _selectOption(
                            context,
                            title: t.containerTypeLabel,
                            current: currentContainerTypeLabel,
                            options: containerTypeOptions.keys.toList(),
                            onSave: (value) => app.updateField(
                              (p) => p.containerType =
                                  containerTypeOptions[value] ?? 'unknown',
                            ),
                          ),
                        ),
                        _row(
                          context,
                          t.containerSizeLabel,
                          currentContainerSizeLabel,
                          icon: Icons.straighten,
                          onTap: () => _selectOption(
                            context,
                            title: t.containerSizeLabel,
                            current: currentContainerSizeLabel,
                            options: containerSizeOptions.keys.toList(),
                            onSave: (value) => app.updateField(
                              (p) => p.containerSize =
                                  containerSizeOptions[value] ?? 'medium',
                            ),
                          ),
                        ),
                        if (profile.containerType == 'bowl')
                          _row(
                            context,
                            t.containerDepthLabel,
                            currentContainerDepthLabel,
                            icon: Icons.vertical_align_bottom,
                            onTap: () => _selectOption(
                              context,
                              title: t.containerDepthLabel,
                              current: currentContainerDepthLabel,
                              options: containerDepthOptions.keys.toList(),
                              onSave: (value) => app.updateField(
                                (p) => p.containerDepth =
                                    containerDepthOptions[value] ?? 'medium',
                              ),
                            ),
                          ),
                        if (profile.containerType == 'bowl')
                          _row(
                            context,
                            t.containerCapacityLabel,
                            profile.containerCapacityMl > 0
                                ? '${profile.containerCapacityMl} ml'
                                : '--',
                            icon: Icons.opacity,
                            onTap: () => _editText(
                              context,
                              title: t.containerCapacityLabel,
                              initial: profile.containerCapacityMl > 0
                                  ? profile.containerCapacityMl.toString()
                                  : '',
                              keyboardType: TextInputType.number,
                              onSave: (value) => app.updateField(
                                (p) => p.containerCapacityMl =
                                    int.tryParse(value) ?? 0,
                              ),
                            ),
                          ),
                        if (profile.containerSize == 'custom' &&
                            (profile.containerType == 'bowl' ||
                                profile.containerType == 'plate' ||
                                profile.containerType == 'box'))
                          _row(
                            context,
                            t.containerDiameterLabel,
                            profile.containerDiameterCm > 0
                                ? '${profile.containerDiameterCm} cm'
                                : '--',
                            icon: Icons.radio_button_unchecked,
                            onTap: () => _editText(
                              context,
                              title: t.containerDiameterLabel,
                              initial: profile.containerDiameterCm > 0
                                  ? profile.containerDiameterCm.toString()
                                  : '',
                              keyboardType: TextInputType.number,
                              onSave: (value) => app.updateField(
                                (p) => p.containerDiameterCm =
                                    int.tryParse(value) ??
                                        p.containerDiameterCm,
                              ),
                            ),
                          ),
                      ]),
                    ],
                  ),
                  _sectionTitle(context, t.dietPreferenceSection),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.dietTypeLabel,
                        currentDietTypeLabel,
                        icon: Icons.restaurant_menu,
                        onTap: () => _selectOption(
                          context,
                          title: t.dietTypeLabel,
                          current: currentDietTypeLabel,
                          options: dietTypeOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.dietType = dietTypeOptions[value] ?? 'none'),
                        ),
                      ),
                      _row(
                        context,
                        t.dietNoteLabel,
                        profile.dietNote.isEmpty ? '--' : profile.dietNote,
                        icon: Icons.sticky_note_2,
                        onTap: () => _editText(
                          context,
                          title: t.dietNoteLabel,
                          initial: profile.dietNote,
                          onSave: (value) =>
                              app.updateField((p) => p.dietNote = value.trim()),
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle(context, t.adviceStyleSection),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.toneLabel,
                        currentToneLabel,
                        icon: Icons.record_voice_over,
                        onTap: () => _selectOption(
                          context,
                          title: t.toneLabel,
                          current: currentToneLabel,
                          options: toneOptions.keys.toList(),
                          onSave: (value) => app.updateField(
                            (p) => p.tone = toneOptions[value] ?? 'gentle',
                          ),
                        ),
                      ),
                      _row(
                        context,
                        t.personaLabel,
                        currentPersonaLabel,
                        icon: Icons.face,
                        onTap: () => _selectOption(
                          context,
                          title: t.personaLabel,
                          current: currentPersonaLabel,
                          options: personaOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) => p.persona =
                              personaOptions[value] ?? 'nutritionist'),
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle(context, t.summarySettingsSection),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.summaryTimeLabel,
                        profile.dailySummaryTime.format(context),
                        icon: Icons.schedule,
                        onTap: () => _pickTime(
                          context,
                          initial: profile.dailySummaryTime,
                          onSave: (time) =>
                              app.updateField((p) => p.dailySummaryTime = time),
                        ),
                      ),
                      _row(
                        context,
                        t.weeklySummaryDayLabel,
                        currentWeekdayLabel,
                        icon: Icons.date_range,
                        onTap: () => _selectOption(
                          context,
                          title: t.weeklySummaryDayLabel,
                          current: currentWeekdayLabel,
                          options: weekdayOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.weeklySummaryWeekday =
                                  weekdayOptions[value] ?? DateTime.sunday),
                        ),
                      ),
                      _row(
                        context,
                        t.mealTimeSection,
                        _mealTimeSummary(context, profile),
                        icon: Icons.schedule_outlined,
                        onTap: () => _showMealTimeSheet(context, t, app),
                      ),
                    ],
                  ),
                  _sectionTitle(context, mealCueSectionTitle),
                  _sectionHint(context, mealCueSectionHint),
                  _rowsCard(
                    context,
                    rows: [
                      _switchRow(
                        context,
                        title: isZh ? '早餐時段' : 'Breakfast window',
                        icon: Icons.free_breakfast_outlined,
                        value: profile.breakfastReminderEnabled,
                        onChanged: (value) => app.updateField(
                          (p) => p.breakfastReminderEnabled = value,
                        ),
                      ),
                      _switchRow(
                        context,
                        title: isZh ? '午餐時段' : 'Lunch window',
                        icon: Icons.lunch_dining,
                        value: profile.lunchReminderEnabled,
                        onChanged: (value) => app
                            .updateField((p) => p.lunchReminderEnabled = value),
                      ),
                      _switchRow(
                        context,
                        title: isZh ? '晚餐時段' : 'Dinner window',
                        icon: Icons.nightlight_round,
                        value: profile.dinnerReminderEnabled,
                        onChanged: (value) => app.updateField(
                            (p) => p.dinnerReminderEnabled = value),
                      ),
                    ],
                  ),
                  _sectionTitle(context, t.subscriptionSection),
                  _sectionCard(
                    context,
                    children: [
                      Chip(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        label: Text(subscriptionStatus),
                        labelStyle: TextStyle(color: subscriptionLabelColor),
                        backgroundColor:
                            subscriptionColor.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 10),
                      _sectionHint(context, subscriptionHint),
                      ..._spacedChildren([
                        _row(
                          context,
                          t.subscriptionPlan,
                          subscriptionPlanLabel,
                          icon: Icons.star_border,
                          showChevron: false,
                          dense: true,
                        ),
                        _row(
                          context,
                          trialEndsTitle,
                          _formatDateShort(trialEndAt) == '--'
                              ? notEnabledText
                              : _formatDateShort(trialEndAt),
                          icon: Icons.timer_outlined,
                          showChevron: false,
                          dense: true,
                        ),
                        _row(
                          context,
                          whitelistTitle,
                          isWhitelisted ? yesText : noText,
                          icon: Icons.verified_user_outlined,
                          showChevron: false,
                          dense: true,
                        ),
                        _actionRowButton(
                          context,
                          title: subscriptionActionTitle,
                          icon: Icons.workspace_premium_outlined,
                          filled: true,
                          onPressed: canOpenSubscriptionPaywall
                              ? () => showSubscriptionPaywall(context, app, t)
                              : null,
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle(context, supportSectionTitle),
                  _sectionCard(
                    context,
                    children: [
                      _sectionHint(context, supportSectionHint),
                      ..._spacedChildren([
                        _row(
                          context,
                          supportCenterTitle,
                          '',
                          icon: Icons.support_agent_outlined,
                          onTap: () => _openExternalLink(
                            context,
                            supportUri,
                            errorMessage: openLinkError,
                          ),
                        ),
                        _row(
                          context,
                          privacyPolicyTitle,
                          '',
                          icon: Icons.privacy_tip_outlined,
                          onTap: () => _openExternalLink(
                            context,
                            privacyUri,
                            errorMessage: openLinkError,
                          ),
                        ),
                        _row(
                          context,
                          termsOfServiceTitle,
                          '',
                          icon: Icons.description_outlined,
                          onTap: () => _openExternalLink(
                            context,
                            termsUri,
                            errorMessage: openLinkError,
                          ),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle(context, t.languageLabel),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.languageLabel,
                        profile.language == 'zh-TW' ? t.langZh : t.langEn,
                        icon: Icons.language,
                        onTap: () => _selectOption(
                          context,
                          title: t.languageLabel,
                          current:
                              profile.language == 'zh-TW' ? t.langZh : t.langEn,
                          options: [t.langZh, t.langEn],
                          onSave: (value) => app.updateField((p) =>
                              p.language = value == t.langZh ? 'zh-TW' : 'en'),
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle(context, t.layoutThemeLabel),
                  _sectionCard(
                    context,
                    children: [
                      _row(
                        context,
                        t.textSizeLabel,
                        currentTextSizeLabel,
                        icon: Icons.text_fields,
                        onTap: () => _selectOption(
                          context,
                          title: t.textSizeLabel,
                          current: currentTextSizeLabel,
                          options: textSizeOptions.keys.toList(),
                          onSave: (value) => app.updateField(
                            (p) => p.textScale = textSizeOptions[value] ?? 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isZh ? '配色主題' : 'Color themes',
                        style: AppTextStyles.caption(context).copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _themeButton(
                              context,
                              label: t.themeClean,
                              asset: 'assets/themes/theme_clean.json',
                              currentAsset: currentThemeAsset,
                              themeController: themeController,
                              app: app,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _themeButton(
                              context,
                              label: t.themeWarm,
                              asset: 'assets/themes/theme_warm.json',
                              currentAsset: currentThemeAsset,
                              themeController: themeController,
                              app: app,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _themeButton(
                              context,
                              label: t.themeGreen,
                              asset: 'assets/themes/theme_green.json',
                              currentAsset: currentThemeAsset,
                              themeController: themeController,
                              app: app,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _themeButton(
                              context,
                              label: t.themePink,
                              asset: 'assets/themes/theme_pink.json',
                              currentAsset: currentThemeAsset,
                              themeController: themeController,
                              app: app,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _switchRow(
                        context,
                        title: t.glowToggleLabel,
                        icon: Icons.blur_on,
                        value: profile.glowEnabled,
                        onChanged: (value) =>
                            app.updateField((p) => p.glowEnabled = value),
                      ),
                      const SizedBox(height: 8),
                      _row(
                        context,
                        t.plateStyleLabel,
                        currentPlateLabel,
                        icon: Icons.restaurant,
                        onTap: () => _selectOption(
                          context,
                          title: t.plateStyleLabel,
                          current: currentPlateLabel,
                          options: plateOptions.keys.toList(),
                          onSave: (value) {
                            app.updateField((p) => p.plateAsset =
                                plateOptions[value] ?? kDefaultPlateAsset);
                            app.precachePlateAsset();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (app.supportsSystemGallerySync) ...[
                    _sectionTitle(context, isZh ? '拍照與照片' : 'Camera & Photos'),
                    _rowsCard(
                      context,
                      rows: [
                        _switchRow(
                          context,
                          title: isZh
                              ? '拍照時同步存到系統相簿'
                              : 'Save captured photos to system gallery',
                          subtitle: isZh
                              ? '關閉時照片只保留在 MiraMeal；開啟後會另外存一份到裝置相簿。'
                              : 'When off, photos stay only inside MiraMeal. When on, a copy is also saved to your device gallery.',
                          icon: Icons.photo_library_outlined,
                          value: profile.saveCameraPhotosToGallery,
                          onChanged: (value) => app.updateField(
                            (p) => p.saveCameraPhotosToGallery = value,
                          ),
                        ),
                      ],
                    ),
                  ],
                  _sectionTitle(context, t.nutritionChartLabel),
                  _rowsCard(
                    context,
                    rows: [
                      _row(
                        context,
                        t.nutritionChartLabel,
                        currentChartLabel,
                        icon: Icons.pie_chart,
                        onTap: () => _selectOption(
                          context,
                          title: t.nutritionChartLabel,
                          current: currentChartLabel,
                          options: chartOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.nutritionChartStyle =
                                  chartOptions[value] ?? 'radar'),
                        ),
                      ),
                      _row(
                        context,
                        t.nutritionValueLabel,
                        currentNutritionValueLabel,
                        icon: Icons.format_list_numbered,
                        onTap: () => _selectOption(
                          context,
                          title: t.nutritionValueLabel,
                          current: currentNutritionValueLabel,
                          options: nutritionValueOptions.keys.toList(),
                          onSave: (value) => app.updateField((p) =>
                              p.nutritionValueMode =
                                  nutritionValueOptions[value] ?? 'percent'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _sectionTitle(context, t.versionSection),
                  FutureBuilder<Map<String, String>?>(
                    future: _loadVersionInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _rowsCard(
                          context,
                          rows: [
                            _row(
                              context,
                              t.versionBuild,
                              t.usageLoading,
                              icon: Icons.info_outline,
                              showChevron: false,
                              dense: true,
                            ),
                          ],
                          gap: 6,
                        );
                      }
                      final info = snapshot.data;
                      if (info == null) {
                        return _rowsCard(
                          context,
                          rows: [
                            _row(
                              context,
                              t.versionBuild,
                              t.versionUnavailable,
                              icon: Icons.info_outline,
                              showChevron: false,
                              dense: true,
                            ),
                          ],
                          gap: 6,
                        );
                      }
                      final commit = info['commit'] ?? '';
                      final shortCommit =
                          commit.length > 7 ? commit.substring(0, 7) : commit;
                      return _rowsCard(
                        context,
                        rows: [
                          _row(
                            context,
                            t.versionBuild,
                            _formatBuildTime(info['build_time'] ?? '--'),
                            icon: Icons.info_outline,
                            showChevron: false,
                            dense: true,
                          ),
                          _row(
                            context,
                            t.versionCommit,
                            shortCommit.isEmpty ? '--' : shortCommit,
                            icon: Icons.code,
                            showChevron: false,
                            dense: true,
                          ),
                        ],
                        gap: 6,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _sectionTitle(context, t.dataSection),
                  _sectionCard(
                    context,
                    children: [
                      _sectionHint(context, dataSectionHint),
                      ..._spacedChildren([
                        _actionRowButton(
                          context,
                          title: t.exportData,
                          icon: Icons.file_download_outlined,
                          onPressed: () => _exportData(context, app),
                        ),
                        _actionRowButton(
                          context,
                          title: t.clearData,
                          icon: Icons.delete_outline,
                          destructive: true,
                          onPressed: () => _clearData(context, app),
                        ),
                      ]),
                    ],
                  ),
                  if (showDeveloperTools) ...[
                    const SizedBox(height: 8),
                    _sectionTitle(context, developerSectionTitle),
                    _sectionCard(
                      context,
                      children: [
                        _sectionHint(context, testingToolsTitle),
                        ..._spacedChildren([
                          _row(
                            context,
                            testPlanTitle,
                            app.mockSubscriptionPlanId == kIapYearlyId
                                ? t.webTestPlanYearly
                                : t.webTestPlanMonthly,
                            icon: Icons.science_outlined,
                            showChevron: false,
                            dense: true,
                          ),
                          _actionRowButton(
                            context,
                            title: resetTestSubscriptionTitle,
                            icon: Icons.restart_alt,
                            onPressed: () {
                              app.setMockSubscriptionActive(false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(resetTestSubscriptionDone),
                                ),
                              );
                            },
                          ),
                        ]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
