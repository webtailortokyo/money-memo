import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'models/money_entry.dart';
import 'pages/main_page.dart';
import 'pages/setup_page.dart';
import 'app_state.dart';
import 'constants.dart';
import 'theme.dart';
import 'utils/notification_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // 必須：バックグラウンドIsolateでプラットフォームチャンネルを使うための初期化
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Hive.initFlutter();
      final box = await Hive.openBox(HiveConstants.settingsBoxName);
      
      final lastActiveTimeMillis = box.get(HiveConstants.keyLastActiveTime) as int?;
      if (lastActiveTimeMillis == null) {
        return Future.value(true);
      }

      final lastActiveTime = DateTime.fromMillisecondsSinceEpoch(lastActiveTimeMillis);
      final now = DateTime.now();
      final diffDays = now.difference(lastActiveTime).inDays;

      // ====== 判定ロジック ======
      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      await notificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      // 共通のNotificationDetails
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel', 
          '記録のリマインド', 
          channelDescription: '数日間記録がない場合に通知を送ります', 
          importance: Importance.high, 
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      // [3日経過]
      final notifiedDay3 = box.get(HiveConstants.keyNotifiedDay3, defaultValue: false) as bool;
      if (diffDays >= 3 && !notifiedDay3) {
        final patterns = [
          AppStrings.notification3DayPatternA,
          AppStrings.notification3DayPatternB,
          AppStrings.notification3DayPatternC,
        ];
        final randomMessage = patterns[Random().nextInt(patterns.length)];
        
        await notificationsPlugin.show(103, AppStrings.notificationTitle, randomMessage, notificationDetails);
        await box.put(HiveConstants.keyNotifiedDay3, true);
        return Future.value(true);
      }

      // [7日経過]
      final notifiedDay7 = box.get(HiveConstants.keyNotifiedDay7, defaultValue: false) as bool;
      if (diffDays >= 7 && !notifiedDay7) {
        await notificationsPlugin.show(107, AppStrings.notificationTitle, AppStrings.notification7DayMessage, notificationDetails);
        await box.put(HiveConstants.keyNotifiedDay7, true);
        return Future.value(true);
      }

      // [14日経過]
      final notifiedDay14 = box.get(HiveConstants.keyNotifiedDay14, defaultValue: false) as bool;
      if (diffDays >= 14 && !notifiedDay14) {
        await notificationsPlugin.show(114, AppStrings.notificationTitle, AppStrings.notification14DayMessage, notificationDetails);
        await box.put(HiveConstants.keyNotifiedDay14, true);
        return Future.value(true);
      }

      // [21日経過]
      final notifiedDay21 = box.get(HiveConstants.keyNotifiedDay21, defaultValue: false) as bool;
      if (diffDays >= 21 && !notifiedDay21) {
        await notificationsPlugin.show(121, AppStrings.notificationTitle, AppStrings.notification21DayMessage, notificationDetails);
        await box.put(HiveConstants.keyNotifiedDay21, true);
        return Future.value(true);
      }

      // [30日経過]
      final notifiedDay30 = box.get(HiveConstants.keyNotifiedDay30, defaultValue: false) as bool;
      if (diffDays >= 30 && !notifiedDay30) {
        await notificationsPlugin.show(130, AppStrings.notificationTitle, AppStrings.notification30DayMessage, notificationDetails);
        await box.put(HiveConstants.keyNotifiedDay30, true);
        return Future.value(true);
      }

      debugPrint('WorkManager checking in... diffDays: $diffDays');

    } catch (e) {
      debugPrint('WorkManager Error: $e');
      // 何らかのクラッシュが起きた場合に原因を通知で知らせる（デバッグ用）
      try {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
        );
        await flutterLocalNotificationsPlugin.show(
          888,
          'WorkManager クラッシュ発生！',
          '$e',
          const NotificationDetails(
            android: AndroidNotificationDetails('inactivity_channel', 'エラー通知', importance: Importance.high),
          ),
        );
      } catch (innerE) {
        debugPrint('Failed to show error: $innerE');
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 通知機能の初期化
    await NotificationManager.init();
    
    // WorkManager初期化 (Android専用)
    if (Platform.isAndroid) {
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // 本番はfalse
      );

      // バックグラウンドの定期巡回タスクを登録（約15分間隔がAndroidの最短仕様）
      Workmanager().registerPeriodicTask(
        "inactivity_timer_task",
        "checkInactivity",
        frequency: const Duration(minutes: 15),
      );
    }

    // アプリ起動時にLastActiveTimeを更新し、通知フラグをリセット
    await NotificationManager.scheduleInactivityNotifications();
  } catch (e) {
    debugPrint('Notification/WorkManager initialization error: $e');
  }

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

  final savedThemeMode = settingsBox.get(HiveConstants.keyThemeMode) as String?;
  if (savedThemeMode != null) {
    appThemeNotifier.value = savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  final onboardingCompleted = settingsBox.get(HiveConstants.keyOnboardingCompleted, defaultValue: false) as bool;

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
