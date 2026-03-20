import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../constants.dart';
import '../main.dart';
import '../models/money_entry.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _titleController = TextEditingController();
  late String _selectedLang;
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    final settingsBox = Hive.box(HiveConstants.settingsBoxName);
    _titleController.text = appTitleNotifier.value;
    _selectedLang = languageNotifier.value;
    _selectedTheme = settingsBox.get(HiveConstants.keyThemeMode, defaultValue: 'system');
    languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_onLanguageChanged);
    _titleController.dispose();
    super.dispose();
  }

  void _updateTitle(String newTitle) {
    final trimTitle = newTitle.trim();
    final settingsBox = Hive.box(HiveConstants.settingsBoxName);

    if (trimTitle.isEmpty) {
      settingsBox.delete(HiveConstants.keyAppTitle);
      appTitleNotifier.value = AppStrings.appTitle;
    } else {
      settingsBox.put(HiveConstants.keyAppTitle, trimTitle);
      appTitleNotifier.value = trimTitle;
    }

    setState(() {});
  }

  void _saveTitle() {
    final newTitle = _titleController.text;
    _updateTitle(newTitle);

    final snackText = newTitle.trim().isEmpty ? 'タイトルをデフォルトに戻しました' : 'タイトルを保存しました';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackText), duration: const Duration(seconds: 1)),
    );
  }

  void _changeLanguage(String lang) {
    setState(() {
      _selectedLang = lang;
    });
    final settingsBox = Hive.box(HiveConstants.settingsBoxName);
    settingsBox.put(HiveConstants.keyLanguage, lang);
    // languageNotifierを更新すると、main.dartのValueListenableBuilder3が
    // アプリ全体をリビルドする
    languageNotifier.value = lang;
    AppStrings.setLanguage(lang);
  }

  void _changeTheme(String themeStr) {
    setState(() {
      _selectedTheme = themeStr;
    });
    final settingsBox = Hive.box(HiveConstants.settingsBoxName);
    settingsBox.put(HiveConstants.keyThemeMode, themeStr);

    ThemeMode mode;
    switch (themeStr) {
      case 'light': mode = ThemeMode.light; break;
      case 'dark': mode = ThemeMode.dark; break;
      default: mode = ThemeMode.system; break;
    }
    themeModeNotifier.value = mode;
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    final settingsBox = Hive.box(HiveConstants.settingsBoxName);
    final savedTitle = settingsBox.get(HiveConstants.keyAppTitle, defaultValue: '') as String;
    if (savedTitle.trim().isEmpty) {
      _titleController.text = AppStrings.appTitle;
    } else {
      _titleController.text = savedTitle;
    }
    setState(() {});
  }

  /// データとマイルストーン達成履歴をすべてリセット
  Future<void> _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteConfirmTitle),
        content: Text(AppStrings.deleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.deleteButtonText, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 記録データを削除
      final moneyBox = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
      await moneyBox.clear();
      // マイルストーン達成履歴もリセット（最初から始まる）
      final statsBox = Hive.box(HiveConstants.statsBoxName);
      await statsBox.clear();

      // タイトルとテーマもリセット
      final settingsBox = Hive.box(HiveConstants.settingsBoxName);
      settingsBox.delete(HiveConstants.keyAppTitle);
      settingsBox.put(HiveConstants.keyThemeMode, 'system');

      appTitleNotifier.value = AppStrings.appTitle;
      themeModeNotifier.value = ThemeMode.system;

      _titleController.text = AppStrings.appTitle;
      _selectedTheme = 'system';
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.resetSuccess)),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
    final entries = box.values.toList();

    StringBuffer csv = StringBuffer();
    csv.writeln('Date,Memo,Type,Amount');
    for (var entry in entries) {
      final date = entry.date.toIso8601String();
      final memo = entry.memo.replaceAll(',', ' ');
      csv.writeln('$date,$memo,${entry.type},${entry.amount}');
    }
    await Share.share(csv.toString(), subject: 'Money Memo Data Export');
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.importData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('CSVデータを貼り付けてください (Date,Memo,Type,Amount):'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancelButtonText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppStrings.recordButtonText),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
        final lines = result.split('\n');
        int count = 0;
        for (var line in lines) {
          if (line.trim().isEmpty || line.startsWith('Date')) continue;
          final parts = line.split(',');
          if (parts.length >= 4) {
            final entry = MoneyEntry(
              date: DateTime.parse(parts[0]),
              memo: parts[1],
              type: parts[2],
              amount: int.parse(parts[3].trim()),
            );
            box.add(entry);
            count++;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.importSuccess} ($count)')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.importError)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        children: [
          // タイトル設定
          _SectionHeader(title: AppStrings.titleSetting),
          ListTile(
            title: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: AppStrings.appTitle,
                // 「保存」ボタン無しで即時反映
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _updateTitle(value),
              onSubmitted: (_) => _saveTitle(),
            ),
          ),

          const Divider(),
          // 言語設定
          _SectionHeader(title: AppStrings.languageLabel),
          RadioListTile<String>(
            title: const Text('日本語'),
            value: 'ja',
            groupValue: _selectedLang,
            onChanged: (v) => _changeLanguage(v!),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: _selectedLang,
            onChanged: (v) => _changeLanguage(v!),
          ),

          const Divider(),
          // テーマ設定（横並び）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  AppStrings.themeLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTheme,
                    items: [
                      DropdownMenuItem(value: 'system', child: Text(AppStrings.themeSystem)),
                      DropdownMenuItem(value: 'light', child: Text(AppStrings.themeLight)),
                      DropdownMenuItem(value: 'dark', child: Text(AppStrings.themeDark)),
                    ],
                    onChanged: (v) => _changeTheme(v!),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          // データ管理
          _SectionHeader(title: AppStrings.dataManagementTitle),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: Text(AppStrings.resetAllData),
            subtitle: Text(AppStrings.resetAllDataSubtitle),
            onTap: _resetAllData,
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: Text(AppStrings.exportData),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(AppStrings.importData),
            onTap: _importData,
          ),

          const Divider(),
          // アプリについて
          _SectionHeader(title: AppStrings.appInfoTitle),
          ListTile(
            title: Text(AppStrings.version),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Licenses'),
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
