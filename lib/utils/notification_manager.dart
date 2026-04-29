import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../constants.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 通知機能の初期化
  static Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS && !Platform.isLinux)) {
      return;
    }
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName.identifier));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);

    // 初期化時は権限リクエストを分離（UI構築後に呼ぶため）
  }

  /// UI構築後（Activityアタッチ後）に呼び出すべき権限リクエスト
  static Future<void> requestPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS && !Platform.isLinux)) {
      return;
    }
    
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Android 13以降の通知権限
      await androidImplementation?.requestNotificationsPermission();
      // ※「設定画面に飛ぶ」原因となっていた正確なアラーム権限の要求は削除しました
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// 記録が行われるたびに呼ばれ、WorkManagerが参照する「最終アクティブ日時」を更新する
  static Future<void> scheduleInactivityNotifications() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS && !Platform.isLinux)) {
      return;
    }
    try {
      final box = Hive.box(HiveConstants.settingsBoxName);
      // 最終アクティビティ時刻を現在時刻に更新
      await box.put(HiveConstants.keyLastActiveTime, DateTime.now().millisecondsSinceEpoch);
      
      // ここを基点に通知をやり直すため、すべての通知済みフラグをリセット

      await box.put(HiveConstants.keyNotifiedDay3, false);
      await box.put(HiveConstants.keyNotifiedDay7, false);
      await box.put(HiveConstants.keyNotifiedDay14, false);
      await box.put(HiveConstants.keyNotifiedDay21, false);
      await box.put(HiveConstants.keyNotifiedDay30, false);

      // 旧システム(AlarmManager)等で残ってしまった未発行の通知をすべてキャンセル
      await _notificationsPlugin.cancelAll();

      if (Platform.isIOS || Platform.isAndroid) {
        // 全プラットフォームで確実なOSネイティブの予約システム(zonedSchedule)を採用
        final now = tz.TZDateTime.now(tz.local);
        final day3 = now.add(const Duration(days: 3)); // 本来の3日後に戻しました
        final day7 = now.add(const Duration(days: 7));
        final day14 = now.add(const Duration(days: 14));
        final day21 = now.add(const Duration(days: 21));
        final day30 = now.add(const Duration(days: 30));

        final patterns = [
          AppStrings.notification3DayPatternA,
          AppStrings.notification3DayPatternB,
          AppStrings.notification3DayPatternC,
        ];
        final randomMessage = patterns[Random().nextInt(patterns.length)];

        await _scheduleNotification(id: 103, title: AppStrings.notificationTitle, body: randomMessage, scheduledDate: day3);
        await _scheduleNotification(id: 107, title: AppStrings.notificationTitle, body: AppStrings.notification7DayMessage, scheduledDate: day7);
        await _scheduleNotification(id: 114, title: AppStrings.notificationTitle, body: AppStrings.notification14DayMessage, scheduledDate: day14);
        await _scheduleNotification(id: 121, title: AppStrings.notificationTitle, body: AppStrings.notification21DayMessage, scheduledDate: day21);
        await _scheduleNotification(id: 130, title: AppStrings.notificationTitle, body: AppStrings.notification30DayMessage, scheduledDate: day30);
      }
    } catch (e) {
      debugPrint('Failed to update inactivity timer (Hive): $e');
    }
  }

  /// WorkManager側（バックグラウンド）から呼び出される即時通知用のメソッド
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel',
          '記録のリマインド',
          channelDescription: '数日間記録がない場合に通知を送ります',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// 全プラットフォーム向けの個別通知スケジュール登録
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_channel',
          '記録のリマインド',
          channelDescription: '数日間記録がない場合に通知を送ります',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 現在システムに予約されている通知の数を取得する（デバッグ・確認用）
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
