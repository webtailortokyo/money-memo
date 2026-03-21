import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/money_entry.dart';
import 'pages/main_page.dart';
import 'app_state.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(MoneyEntryAdapter());
  await Hive.openBox<MoneyEntry>(HiveConstants.moneyBoxName);
  await Hive.openBox(HiveConstants.statsBoxName);
  
  // 設定保存用のBoxを開く
  final settingsBox = await Hive.openBox(HiveConstants.settingsBoxName);
  
  // 保存されている設定を反映
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

  // 言語が変わったとき、タイトルがデフォルト（空）なら AppStrings.appTitle に更新する
  languageNotifier.addListener(() {
    final box = Hive.box(HiveConstants.settingsBoxName);
    final customTitle = box.get(HiveConstants.keyAppTitle, defaultValue: '') as String;
    if (customTitle.isEmpty) {
      appTitleNotifier.value = AppStrings.appTitle;
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder2<String, String>(
      valueListenable1: appTitleNotifier,
      valueListenable2: languageNotifier,
      builder: (context, title, lang, child) {
        return MaterialApp(
          title: title,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Rounded Mplus 1c',
          ),
          home: MainPage(),
        );
      },
    );
  }
}
