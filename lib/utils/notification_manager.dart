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
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);

    // 初期化時は古い通知などをクリーンアップするため定期通知スケジュールを呼ぶ
    await schedulePeriodicNotification();
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

  static Future<void> schedulePeriodicNotification() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS && !Platform.isLinux)) {
      return;
    }

    try {
      // 既存のスケジュールをすべてキャンセルしてリセット
      await _notificationsPlugin.cancelAll();

      final box = Hive.box(HiveConstants.settingsBoxName);
      final isEnabled = box.get(HiveConstants.keyPeriodicNotificationEnabled, defaultValue: false) as bool;

      if (!isEnabled) {
        return; // OFFの場合はここで終了（キャンセル済み）
      }

      final frequency = box.get(HiveConstants.keyPeriodicNotificationFrequency, defaultValue: 'daily') as String;
      final hour = box.get(HiveConstants.keyPeriodicNotificationTimeHour, defaultValue: 20) as int;
      final minute = box.get(HiveConstants.keyPeriodicNotificationTimeMinute, defaultValue: 0) as int;
      final dayOfWeek = box.get(HiveConstants.keyPeriodicNotificationDayOfWeek, defaultValue: 1) as int; // 1: 月曜
      final dayOfMonth = box.get(HiveConstants.keyPeriodicNotificationDayOfMonth, defaultValue: 1) as int; // 1日

      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate;
      String message;
      DateTimeComponents? matchComponents;

      if (frequency == 'daily') {
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        message = AppStrings.notificationDailyMessage;
        matchComponents = DateTimeComponents.time;
      } else if (frequency == 'weekly') {
        // 現在の日付から指定の曜日まで進める (1: 月曜 ... 7: 日曜)
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        while (scheduledDate.weekday != dayOfWeek) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }
        message = AppStrings.notificationWeeklyMessage;
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
      } else if (frequency == 'monthly') {
        scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, dayOfMonth, hour, minute);
        if (scheduledDate.isBefore(now)) {
          // 翌月にする
          int nextMonth = now.month + 1;
          int nextYear = now.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
          int targetDay = dayOfMonth > daysInNextMonth ? daysInNextMonth : dayOfMonth;
          scheduledDate = tz.TZDateTime(tz.local, nextYear, nextMonth, targetDay, hour, minute);
        }
        message = AppStrings.notificationMonthlyMessage;
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
      } else {
        return; // 未知の頻度
      }

      await _notificationsPlugin.zonedSchedule(
        100, // 定期通知用固定ID
        AppStrings.notificationTitle,
        message,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'periodic_channel',
            '定期リマインド',
            channelDescription: '設定した日時に通知を送ります',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );

    } catch (e) {
      debugPrint('Failed to schedule periodic notification: $e');
    }
  }

  /// 現在システムに予約されている通知の数を取得する（デバッグ・確認用）
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
