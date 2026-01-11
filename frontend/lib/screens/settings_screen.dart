import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import '../utils/data_exporter.dart';
import '../design/theme_controller.dart';
import '../state/app_state.dart';
import '../widgets/app_background.dart';
import '../design/text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: AppTextStyles.caption(context).copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _row(BuildContext context, String title, String value, {VoidCallback? onTap, bool showChevron = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: Text(title)),
            Text(value, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
            if (showChevron)
              const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _apiRow(BuildContext context, String title, String value, {VoidCallback? onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                    child: Text(
                      value,
                    style: AppTextStyles.caption(context).copyWith(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
              ],
            ),
          ],
        ),
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
            Expanded(child: i + 1 < items.length ? items[i + 1] : const SizedBox()),
          ],
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return Column(children: rows);
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(t.save)),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onSave(result);
    }
  }

  Future<void> _editApiUrl(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: app.profile.apiBaseUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.apiBaseUrlLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'http://127.0.0.1:8000'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(t.save)),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      app.updateField((p) => p.apiBaseUrl = result);
      app.updateApiBaseUrl(result);
    }
  }

  Future<void> _editProfile(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: app.profile.name);
    final emailController = TextEditingController(text: app.profile.email);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: t.profileName),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: t.profileEmail),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.save)),
        ],
      ),
    );
    if (result == true) {
      app.updateField((p) {
        p.name = nameController.text.trim().isEmpty ? p.name : nameController.text.trim();
        p.email = emailController.text.trim().isEmpty ? p.email : emailController.text.trim();
      });
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
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
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

  Future<void> _exportData(BuildContext context, AppState app) async {
    final t = AppLocalizations.of(context)!;
    final data = await app.exportData();
    final exporter = createDataExporter();
    await exporter.saveJson('food-ai-export.json', data);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.exportDone)));
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.clearData)),
        ],
      ),
    );
    if (confirmed == true) {
      await app.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.clearDone)));
      }
    }
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
    final plateOptions = <String, String>{
      t.plateDefaultLabel: kDefaultPlateAsset,
      t.plateWarmLabel: 'assets/plates/plate_warm.png',
    };
    final chartOptions = <String, String>{
      t.chartRadar: 'radar',
      t.chartBars: 'bars',
      t.chartDonut: 'donut',
    };
    final currentPlateLabel = plateOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.plateAsset,
          orElse: () => MapEntry(t.plateDefaultLabel, kDefaultPlateAsset),
        )
        .key;
    final currentChartLabel = chartOptions.entries
        .firstWhere(
          (entry) => entry.value == profile.nutritionChartStyle,
          orElse: () => MapEntry(t.chartRadar, 'radar'),
        )
        .key;
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
    final toneOptions = <String, String>{
      t.toneGentle: 'gentle',
      t.toneDirect: 'direct',
      t.toneEncouraging: 'encouraging',
      t.toneBullet: 'bullet',
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
                const SizedBox(height: 12),
                Container(
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
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: const Color(0xFFEFF3FF), child: const Icon(Icons.person, color: Color(0xFF5B7CFA))),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                          Text(profile.email, style: AppTextStyles.caption(context).copyWith(color: Colors.black54)),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _editProfile(context, app),
                        child: Text(t.editProfile),
                      ),
                    ],
                  ),
                ),
                _sectionTitle(context, t.planSection),
                _grid2([
                  _row(
                    context,
                    t.heightLabel,
                    '${profile.heightCm} cm',
                    onTap: () => _editText(
                      context,
                      title: t.heightLabel,
                      initial: profile.heightCm.toString(),
                      keyboardType: TextInputType.number,
                      onSave: (value) => app.updateField((p) => p.heightCm = int.tryParse(value) ?? p.heightCm),
                    ),
                  ),
                  _row(
                    context,
                    t.weightLabel,
                    '${profile.weightKg} kg',
                    onTap: () => _editText(
                      context,
                      title: t.weightLabel,
                      initial: profile.weightKg.toString(),
                      keyboardType: TextInputType.number,
                      onSave: (value) => app.updateField((p) => p.weightKg = int.tryParse(value) ?? p.weightKg),
                    ),
                  ),
                  _row(
                    context,
                    t.ageLabel,
                    '${profile.age}',
                    onTap: () => _editText(
                      context,
                      title: t.ageLabel,
                      initial: profile.age.toString(),
                      keyboardType: TextInputType.number,
                      onSave: (value) => app.updateField((p) => p.age = int.tryParse(value) ?? p.age),
                    ),
                  ),
                  _row(
                    context,
                    t.genderLabel,
                    currentGenderLabel,
                    onTap: () => _selectOption(
                      context,
                      title: t.genderLabel,
                      current: currentGenderLabel,
                      options: genderOptions.keys.toList(),
                      onSave: (value) => app.updateField((p) => p.gender = genderOptions[value] ?? 'unspecified'),
                    ),
                  ),
                  _row(
                    context,
                    t.bmiLabel,
                    _bmiText(profile, t),
                    showChevron: false,
                  ),
                  _row(
                    context,
                    t.goalLabel,
                    profile.goal,
                    onTap: () => _selectOption(
                      context,
                      title: t.goalLabel,
                      current: profile.goal,
                      options: [t.goalLoseFat, t.goalMaintain],
                      onSave: (value) => app.updateField((p) => p.goal = value),
                    ),
                  ),
                  _row(
                    context,
                    t.planSpeedLabel,
                    profile.planSpeed,
                    onTap: () => _selectOption(
                      context,
                      title: t.planSpeedLabel,
                      current: profile.planSpeed,
                      options: [t.planSpeedStable, t.planSpeedGentle],
                      onSave: (value) => app.updateField((p) => p.planSpeed = value),
                    ),
                  ),
                  _row(
                    context,
                    t.activityLevelLabel,
                    currentActivityLabel,
                    onTap: () => _selectOption(
                      context,
                      title: t.activityLevelLabel,
                      current: currentActivityLabel,
                      options: activityOptions.keys.toList(),
                      onSave: (value) => app.updateField((p) => p.activityLevel = activityOptions[value] ?? 'light'),
                    ),
                  ),
                ]),
                _sectionTitle(context, t.adviceStyleSection),
                _grid2([
                  _row(
                    context,
                    t.toneLabel,
                    currentToneLabel,
                    onTap: () => _selectOption(
                      context,
                      title: t.toneLabel,
                      current: currentToneLabel,
                      options: toneOptions.keys.toList(),
                      onSave: (value) => app.updateField((p) => p.tone = toneOptions[value] ?? 'gentle'),
                    ),
                  ),
                  _row(
                    context,
                    t.personaLabel,
                    currentPersonaLabel,
                    onTap: () => _selectOption(
                      context,
                      title: t.personaLabel,
                      current: currentPersonaLabel,
                      options: personaOptions.keys.toList(),
                      onSave: (value) => app.updateField((p) => p.persona = personaOptions[value] ?? 'nutritionist'),
                    ),
                  ),
                ]),
                _sectionTitle(context, t.summarySettingsSection),
                _grid2([
                  _row(
                    context,
                    t.summaryTimeLabel,
                    profile.dailySummaryTime.format(context),
                    onTap: () => _pickTime(
                      context,
                      initial: profile.dailySummaryTime,
                      onSave: (time) => app.updateField((p) => p.dailySummaryTime = time),
                    ),
                  ),
                  _row(
                    context,
                    t.weeklySummaryDayLabel,
                    currentWeekdayLabel,
                    onTap: () => _selectOption(
                      context,
                      title: t.weeklySummaryDayLabel,
                      current: currentWeekdayLabel,
                      options: weekdayOptions.keys.toList(),
                      onSave: (value) => app.updateField((p) => p.weeklySummaryWeekday = weekdayOptions[value] ?? DateTime.sunday),
                    ),
                  ),
                ]),
                _sectionTitle(context, t.reminderSection),
                SwitchListTile(
                  value: profile.lunchReminderEnabled,
                  onChanged: (value) => app.updateField((p) => p.lunchReminderEnabled = value),
                  title: Text(t.reminderLunch),
                  secondary: const Icon(Icons.alarm),
                ),
                _row(
                  context,
                  t.reminderLunchTime,
                  profile.lunchReminderTime.format(context),
                  onTap: () => _pickTime(
                    context,
                    initial: profile.lunchReminderTime,
                    onSave: (time) => app.updateField((p) => p.lunchReminderTime = time),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: profile.dinnerReminderEnabled,
                  onChanged: (value) => app.updateField((p) => p.dinnerReminderEnabled = value),
                  title: Text(t.reminderDinner),
                  secondary: const Icon(Icons.alarm),
                ),
                _row(
                  context,
                  t.reminderDinnerTime,
                  profile.dinnerReminderTime.format(context),
                  onTap: () => _pickTime(
                    context,
                    initial: profile.dinnerReminderTime,
                    onSave: (time) => app.updateField((p) => p.dinnerReminderTime = time),
                  ),
                ),
                _sectionTitle(context, t.subscriptionSection),
                _grid2([
                  _row(context, t.subscriptionPlan, t.planMonthly),
                  _row(
                    context,
                    t.languageLabel,
                    profile.language == 'zh-TW' ? t.langZh : t.langEn,
                    onTap: () => _selectOption(
                      context,
                      title: t.languageLabel,
                      current: profile.language == 'zh-TW' ? t.langZh : t.langEn,
                      options: [t.langZh, t.langEn],
                      onSave: (value) => app.updateField((p) => p.language = value == t.langZh ? 'zh-TW' : 'en'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                _sectionTitle(context, t.apiSection),
                _apiRow(
                  context,
                  t.apiBaseUrlLabel,
                  profile.apiBaseUrl,
                  onTap: () => _editApiUrl(context, app),
                ),
                const SizedBox(height: 8),
                _sectionTitle(context, t.layoutThemeLabel),
                _row(
                  context,
                  t.textSizeLabel,
                  currentTextSizeLabel,
                  onTap: () => _selectOption(
                    context,
                    title: t.textSizeLabel,
                    current: currentTextSizeLabel,
                    options: textSizeOptions.keys.toList(),
                    onSave: (value) => app.updateField((p) => p.textScale = textSizeOptions[value] ?? 1.0),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          const asset = 'assets/themes/theme_clean.json';
                          themeController.loadFromAsset(asset);
                          app.updateField((p) => p.themeAsset = asset);
                        },
                        child: Text(t.themeClean),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          const asset = 'assets/themes/theme_warm.json';
                          themeController.loadFromAsset(asset);
                          app.updateField((p) => p.themeAsset = asset);
                        },
                        child: Text(t.themeWarm),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          const asset = 'assets/themes/theme_green.json';
                          themeController.loadFromAsset(asset);
                          app.updateField((p) => p.themeAsset = asset);
                        },
                        child: Text(t.themeGreen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: profile.glowEnabled,
                  onChanged: (value) => app.updateField((p) => p.glowEnabled = value),
                  title: Text(t.glowToggleLabel),
                  secondary: const Icon(Icons.blur_on),
                ),
                const SizedBox(height: 8),
                _sectionTitle(context, t.plateSection),
                _row(
                  context,
                  t.plateStyleLabel,
                  currentPlateLabel,
                  onTap: () => _selectOption(
                    context,
                    title: t.plateStyleLabel,
                    current: currentPlateLabel,
                    options: plateOptions.keys.toList(),
                    onSave: (value) => app.updateField((p) => p.plateAsset = plateOptions[value] ?? kDefaultPlateAsset),
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTitle(context, t.nutritionChartLabel),
                _row(
                  context,
                  t.nutritionChartLabel,
                  currentChartLabel,
                  onTap: () => _selectOption(
                    context,
                    title: t.nutritionChartLabel,
                    current: currentChartLabel,
                    options: chartOptions.keys.toList(),
                    onSave: (value) => app.updateField((p) => p.nutritionChartStyle = chartOptions[value] ?? 'radar'),
                  ),
                ),
                const SizedBox(height: 8),
                _sectionTitle(context, t.versionSection),
                FutureBuilder<Map<String, String>?>(
                  future: _loadVersionInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _row(context, t.versionBuild, t.usageLoading, showChevron: false);
                    }
                    final info = snapshot.data;
                    if (info == null) {
                      return _row(context, t.versionBuild, t.versionUnavailable, showChevron: false);
                    }
                    final commit = info['commit'] ?? '';
                    final shortCommit = commit.length > 7 ? commit.substring(0, 7) : commit;
                    return Column(
                      children: [
                        _row(context, t.versionBuild, info['build_time'] ?? '--', showChevron: false),
                        const SizedBox(height: 6),
                        _row(context, t.versionCommit, shortCommit.isEmpty ? '--' : shortCommit, showChevron: false),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                _sectionTitle(context, t.dataSection),
                _grid2([
                  _row(
                    context,
                    t.exportData,
                    '',
                    showChevron: false,
                    onTap: () => _exportData(context, app),
                  ),
                  _row(
                    context,
                    t.clearData,
                    '',
                    showChevron: false,
                    onTap: () => _clearData(context, app),
                  ),
                ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
