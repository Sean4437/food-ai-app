import 'package:flutter/material.dart';
import 'package:food_ai_app/gen/app_localizations.dart';
import '../design/theme_controller.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _row(String title, String value, {VoidCallback? onTap, bool showChevron = true}) {
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
            Text(value, style: const TextStyle(color: Colors.black54)),
            if (showChevron)
              const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _apiRow(String title, String value, {VoidCallback? onTap}) {
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.black54),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final themeController = ThemeScope.of(context);
    final app = AppStateScope.of(context);
    final profile = app.profile;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.settingsTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
                          Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(profile.email, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                _sectionTitle(t.planSection),
                _row(
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
                const SizedBox(height: 8),
                _row(
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
                const SizedBox(height: 8),
                _row(
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
                const SizedBox(height: 8),
                _row(
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
                _sectionTitle(t.reminderSection),
                SwitchListTile(
                  value: profile.lunchReminderEnabled,
                  onChanged: (value) => app.updateField((p) => p.lunchReminderEnabled = value),
                  title: Text(t.reminderLunch),
                  secondary: const Icon(Icons.alarm),
                ),
                _row(
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
                  t.reminderDinnerTime,
                  profile.dinnerReminderTime.format(context),
                  onTap: () => _pickTime(
                    context,
                    initial: profile.dinnerReminderTime,
                    onSave: (time) => app.updateField((p) => p.dinnerReminderTime = time),
                  ),
                ),
                _sectionTitle(t.subscriptionSection),
                _row(t.subscriptionPlan, t.planMonthly),
                const SizedBox(height: 8),
                _row(
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
                const SizedBox(height: 8),
                _sectionTitle(t.apiSection),
                _apiRow(
                  t.apiBaseUrlLabel,
                  profile.apiBaseUrl,
                  onTap: () => _editApiUrl(context, app),
                ),
                const SizedBox(height: 8),
                _sectionTitle(t.layoutThemeLabel),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => themeController.loadFromAsset('assets/themes/theme_clean.json'),
                        child: Text(t.themeClean),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => themeController.loadFromAsset('assets/themes/theme_warm.json'),
                        child: Text(t.themeWarm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
