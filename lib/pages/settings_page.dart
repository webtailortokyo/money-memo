import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';
import '../app_state.dart';
import '../models/money_entry.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = appTitleNotifier.value;
  }

  @override
  void dispose() {
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

  /// データとマイルストーン達成履歴をすべてリセット
  Future<void> _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.resetConfirmTitle),
        content: Text(AppStrings.resetConfirmContent),
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
      
      // 統計情報（マイルストーン）もリセット
      final statsBox = Hive.box(HiveConstants.statsBoxName);
      await statsBox.clear();

      // タイトルもデフォルトに戻す
      final settingsBox = Hive.box(HiveConstants.settingsBoxName);
      await settingsBox.delete(HiveConstants.keyAppTitle);
      appTitleNotifier.value = AppStrings.appTitle;
      _titleController.text = AppStrings.appTitle;

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.resetSuccess)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 40, // 以前の調整に合わせる
        title: Text(
          AppStrings.settingsTitle,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // タイトル設定
          _SectionHeader(title: AppStrings.titleSetting),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _titleController,
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: AppStrings.appTitle,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accent.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
              onChanged: _updateTitle,
            ),
          ),

          const Divider(height: 32),
          
          // 通貨設定
          _SectionHeader(title: AppStrings.currencySettingTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ValueListenableBuilder2<String, int>(
              valueListenable1: currencyNotifier,
              valueListenable2: decimalDigitsNotifier,
              builder: (context, symbol, digits, child) {
                return SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '¥', label: Text('JPY(¥)')),
                    ButtonSegment(value: '\$', label: Text('USD(\$)')),
                    ButtonSegment(value: '€', label: Text('EUR(€)')),
                  ],
                  selected: {symbol},
                  onSelectionChanged: (Set<String> newSelection) {
                    final newSymbol = newSelection.first;
                    final newDigits = newSymbol == '¥' ? 0 : 2;
                    
                    currencyNotifier.value = newSymbol;
                    decimalDigitsNotifier.value = newDigits;
                    
                    final box = Hive.box(HiveConstants.settingsBoxName);
                    box.put(HiveConstants.keyCurrency, newSymbol);
                    box.put(HiveConstants.keyDecimalDigits, newDigits);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.accent,
                    selectedForegroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                );
              },
            ),
          ),

          // 言語設定
          _SectionHeader(title: AppStrings.languageSettingTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (context, lang, child) {
                return SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'ja', label: Text(AppStrings.languageJa)),
                    ButtonSegment(value: 'en', label: Text(AppStrings.languageEn)),
                  ],
                  selected: {lang},
                  onSelectionChanged: (Set<String> newSelection) {
                    final newLang = newSelection.first;
                    languageNotifier.value = newLang;
                    
                    final box = Hive.box(HiveConstants.settingsBoxName);
                    box.put(HiveConstants.keyLanguage, newLang);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.accent,
                    selectedForegroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                );
              },
            ),
          ),

          // データ管理
          _SectionHeader(title: AppStrings.dataManagementTitle),
          ListTile(
            leading: const Icon(Icons.refresh, color: AppColors.accent),
            title: Text(
              AppStrings.resetAllData,
              style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(AppStrings.resetAllDataSubtitle),
            onTap: _resetAllData,
          ),

          const Divider(height: 32),
          
          // アプリについて
          _SectionHeader(title: AppStrings.appInfoTitle),
          ListTile(
            title: Text(AppStrings.versionLabel),
            trailing: const Text(AppStrings.appVersion),
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
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
