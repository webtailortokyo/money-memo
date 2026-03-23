import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// 3日後と7日後の通知をスケジュールする
  /// 記録が行われるたびに既存のスケジュールをリセットして呼び出されることを想定
  static Future<void> scheduleInactivityNotifications() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS && !Platform.isLinux)) {
      return;
    }
    // 既存の未発行通知をすべてキャンセル
    await _notificationsPlugin.cancelAll();

    // 3日後の20:00
    final day3 = _scheduledTime(3, 20, 0);
    // 7日後の20:00
    final day7 = _scheduledTime(7, 20, 0);

    // 3日後のメッセージをランダムに選択（パターンA, B, C）
    final patterns = [
      AppStrings.notification3DayPatternA,
      AppStrings.notification3DayPatternB,
      AppStrings.notification3DayPatternC,
    ];
    final randomMessage = patterns[Random().nextInt(patterns.length)];

    // 3日後の通知登録
    await _scheduleNotification(
      id: 100,
      title: AppStrings.notificationTitle,
      body: randomMessage,
      scheduledDate: day3,
    );

    // 7日後の通知登録
    await _scheduleNotification(
      id: 101,
      title: AppStrings.notificationTitle,
      body: AppStrings.notification7DayMessage,
      scheduledDate: day7,
    );
  }

  /// 指定した日数後の指定時刻を取得
  static tz.TZDateTime _scheduledTime(int daysLater, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: daysLater));
    
    return scheduledDate;
  }

  /// 個別の通知をスケジュール登録
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
