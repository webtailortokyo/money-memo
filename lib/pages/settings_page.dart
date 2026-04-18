import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';
import '../app_state.dart';
import '../models/money_entry.dart';
import 'setup_page.dart';
import '../theme.dart';
import '../utils/csv_helper.dart';
import '../utils/notification_manager.dart';

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

  /// 繝・・繧ｿ縺ｨ繝槭う繝ｫ繧ｹ繝医・繝ｳ驕疲・螻･豁ｴ繧偵☆縺ｹ縺ｦ繝ｪ繧ｻ繝・ヨ
  Future<void> _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SelectionArea(
        child: AlertDialog(
          title: Text(AppStrings.resetConfirmTitle),
          content: Text(AppStrings.resetConfirmContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.cancelButtonText),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.deleteButtonText, style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      // 險倬鹸繝・・繧ｿ繧貞炎髯､
      final moneyBox = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
      await moneyBox.clear();
      
      // 邨ｱ險域ュ蝣ｱ・医・繧､繝ｫ繧ｹ繝医・繝ｳ・峨ｂ繝ｪ繧ｻ繝・ヨ
      final statsBox = Hive.box(HiveConstants.statsBoxName);
      await statsBox.clear();

      // タイトルもデフォルトに戻す
      final settingsBox = Hive.box(HiveConstants.settingsBoxName);
      await settingsBox.delete(HiveConstants.keyAppTitle);
      
      // 他の設定もリセット（必要に応じて）
      await settingsBox.delete(HiveConstants.keyCurrency);
      await settingsBox.delete(HiveConstants.keyDecimalDigits);
      await settingsBox.delete(HiveConstants.keyLanguage);
      
      // オンボーディング未完了フラグをセット
      await settingsBox.put(HiveConstants.keyOnboardingCompleted, false);

      appTitleNotifier.value = AppStrings.appTitle;
      currencyNotifier.value = '¥';
      decimalDigitsNotifier.value = 0;
      languageNotifier.value = 'ja';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.resetSuccess)),
        );
        
        // 通知のスケジュールをリセットして再設定
        await NotificationManager.scheduleInactivityNotifications();

        if (mounted) {
          // SetupPageへ遷移
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SetupPage()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        elevation: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.arrow_back_ios, color: context.appColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          AppStrings.settingsTitle,
          style: TextStyle(
            color: context.appColors.accent,
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
                cursorColor: context.appColors.accent,
                decoration: InputDecoration(
                  hintText: AppStrings.appTitle,
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF333333) 
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.appColors.accent.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.appColors.accent, width: 2),
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
                    segments: [
                      ButtonSegment(
                        value: '¥', 
                        label: Text(languageNotifier.value == 'ja' ? '円(¥)' : 'JPY(¥)'),
                      ),
                      const ButtonSegment(value: '\$', label: Text('USD(\$)')),
                      const ButtonSegment(value: '€', label: Text('EUR(€)')),
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
                      selectedBackgroundColor: context.appColors.accent,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: context.appColors.accent,
                      side: BorderSide(color: context.appColors.accent),
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
                      
                      // 言語変更に合わせて通知メッセージも更新（再スケジュール）
                      NotificationManager.scheduleInactivityNotifications();

                      setState(() {});
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: context.appColors.accent,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: context.appColors.accent,
                      side: BorderSide(color: context.appColors.accent),
                    ),
                  );
                },
              ),
            ),
  
            // テーマ設定
            _SectionHeader(title: AppStrings.themeSettingTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeNotifier,
                builder: (context, themeMode, _) {
                  return SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(AppStrings.lightMode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(AppStrings.darkMode),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      final newTheme = newSelection.first;
                      appThemeNotifier.value = newTheme;
                      Hive.box(HiveConstants.settingsBoxName).put(
                          HiveConstants.keyThemeMode,
                          newTheme == ThemeMode.dark ? 'dark' : 'light');
                    },
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: context.appColors.accent,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: context.appColors.accent,
                      side: BorderSide(color: context.appColors.accent),
                    ),
                  );
                },
              ),
            ),
            
            const Divider(height: 32),
  
            // データ管理
            _SectionHeader(title: AppStrings.dataManagementTitle),
            ListTile(
              leading: Icon(Icons.refresh, color: context.appColors.accent),
              title: Text(
                AppStrings.resetAllData,
                style: TextStyle(color: context.appColors.mainText, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(AppStrings.resetAllDataSubtitle),
              onTap: _resetAllData,
            ),
            ListTile(
              leading: Icon(Icons.file_download, color: context.appColors.accent),
              title: Text(
                AppStrings.exportLabel,
                style: TextStyle(color: context.appColors.mainText, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(AppStrings.exportSubtitle),
              onTap: () => CsvHelper.exportCsv(context),
            ),
            ListTile(
              leading: Icon(Icons.file_upload, color: context.appColors.accent),
              title: Text(
                AppStrings.importLabel,
                style: TextStyle(color: context.appColors.mainText, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(AppStrings.importSubtitle),
              onTap: () async {
                await CsvHelper.importCsv(context);
                // インポート後に通知を再スケジュール
                await NotificationManager.scheduleInactivityNotifications();
                _titleController.text = appTitleNotifier.value;
                setState(() {});
              },
            ),
            
            // 繧｢繝励Μ縺ｫ縺､縺・※
            _SectionHeader(title: AppStrings.appInfoTitle),
            ListTile(
              title: Text(AppStrings.versionLabel),
              trailing: Text(AppStrings.appVersion),
            ),
            SizedBox(height: 32),
          ],
        ),
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
          color: context.appColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
