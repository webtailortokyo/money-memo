import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/money_entry.dart';
import 'pages/main_page.dart';
import 'pages/setup_page.dart';
import 'app_state.dart';
import 'constants.dart';
import 'theme.dart';
import 'utils/notification_manager.dart';

// WorkManager logic completely removed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    Hive.registerAdapter(MoneyEntryAdapter());
    await Hive.openBox<MoneyEntry>(HiveConstants.moneyBoxName);
    await Hive.openBox(HiveConstants.statsBoxName);
    
    // 設定保存用のBoxを開く
    await Hive.openBox(HiveConstants.settingsBoxName);

    // 通知機能の初期化（内部で定期通知の再スケジュールも行われる）
    await NotificationManager.init();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  
  // 保存されている設定を反映
  final settingsBox = Hive.box(HiveConstants.settingsBoxName);
  final savedTitle = settingsBox.get(HiveConstants.keyAppTitle, defaultValue: '') as String;
  if (savedTitle.isNotEmpty) {
    appTitleNotifier.value = savedTitle;
  }

  final savedCurrency = settingsBox.get(HiveConstants.keyCurrency) as String?;
  if (savedCurrency != null) {
    currencyNotifier.value = savedCurrency;
  }

  final savedDecimalDigits = settingsBox.get(HiveConstants.keyDecimalDigits) as int?;
  if (savedDecimalDigits != null) {
    decimalDigitsNotifier.value = savedDecimalDigits;
  }

  final savedLanguage = settingsBox.get(HiveConstants.keyLanguage) as String?;
  if (savedLanguage != null) {
    languageNotifier.value = savedLanguage;
  }

  final savedThemeMode = settingsBox.get(HiveConstants.keyThemeMode) as String?;
  if (savedThemeMode != null) {
    appThemeNotifier.value = savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  final onboardingCompleted = settingsBox.get(HiveConstants.keyOnboardingCompleted, defaultValue: false) as bool;
  final savedCustomUnits = settingsBox.get(HiveConstants.keyCustomUnits) as List?;
  if (savedCustomUnits != null) {
    customUnitsNotifier.value = List<String>.from(savedCustomUnits);
  }

  // 言語が変わったとき、タイトルがデフォルト（空）なら AppStrings.appTitle に更新する
  languageNotifier.addListener(() {
    final box = Hive.box(HiveConstants.settingsBoxName);
    final customTitle = box.get(HiveConstants.keyAppTitle, defaultValue: '') as String;
    if (customTitle.isEmpty) {
      appTitleNotifier.value = AppStrings.appTitle;
    }
  });

  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder2<String, String>(
          valueListenable1: appTitleNotifier,
          valueListenable2: languageNotifier,
          builder: (context, title, lang, child) {
            return MaterialApp(
              title: title,
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Rounded Mplus 1c',
                extensions: const [lightAppColors],
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                fontFamily: 'Rounded Mplus 1c',
                extensions: const [darkAppColors],
              ),
              home: onboardingCompleted ? const MainPage() : const SetupPage(),
            );
          },
        );
      },
    );
  }
}
