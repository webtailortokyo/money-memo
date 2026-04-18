# 通知仕様

アプリに長期間記録がない場合のユーザーへのリマインド（通知）仕様です。
Android 14以降の制限を回避するため、厳密な時刻（Exact Alarm）ではなく、おおよその時刻（Inexact Alarm）で予約しています。

## スケジュール設定
アプリを開いた時点、もしくは記録を保存・削除した時点から起算して、以下のタイミングで通知が予約されます。

| スケジュール | 指定時刻 | メッセージの内容 |
| :--- | :--- | :--- |
| **3日後** | 20:00頃 | ランダム（パターンA, B, C）<br>（例）「最近お変わりありませんか？…」など |
| **7日後** | 20:00頃 | 「1週間が経ちました。また気が向いたときに、いつでもお待ちしています。」 |
| **14日後** | 20:00頃 | 「おかねメモを開いてから2週間ですね。今月のお金の見直しなど、いつでもお待ちしています！」 |
| **21日後** | 20:00頃 | 「お久しぶりです！家計簿はマイペースが一番。また記録したくなったらいつでもどうぞ！」 |
| **30日後** | 20:00頃 | 「1ヶ月が経ちました。お金のメモが必要になったら、またいつでも遊びに来てくださいね。」 |

※ 30日後を最後の通知とし、それ以降は永続的に通知しません（ユーザーの通知疲れとOSによるタスクキラー等での自然消滅に配慮）。

## ロジック（Dart）

```dart
// lib/utils/notification_manager.dart

  /// 指定日数の通知をスケジュールする
  static Future<void> scheduleInactivityNotifications() async {
    // 既存の未発行通知をすべてキャンセル
    await _notificationsPlugin.cancelAll();

    final day3 = _scheduledTime(3, 20, 0);
    final day7 = _scheduledTime(7, 20, 0);
    final day14 = _scheduledTime(14, 20, 0);
    final day21 = _scheduledTime(21, 20, 0);
    final day30 = _scheduledTime(30, 20, 0);

    // 3日後のメッセージをランダムに選択
    final patterns = [
      AppStrings.notification3DayPatternA,
      AppStrings.notification3DayPatternB,
      AppStrings.notification3DayPatternC,
    ];
    final randomMessage = patterns[Random().nextInt(patterns.length)];

    await _scheduleNotification(id: 100, title: AppStrings.notificationTitle, body: randomMessage, scheduledDate: day3);
    await _scheduleNotification(id: 101, title: AppStrings.notificationTitle, body: AppStrings.notification7DayMessage, scheduledDate: day7);
    await _scheduleNotification(id: 102, title: AppStrings.notificationTitle, body: AppStrings.notification14DayMessage, scheduledDate: day14);
    await _scheduleNotification(id: 103, title: AppStrings.notificationTitle, body: AppStrings.notification21DayMessage, scheduledDate: day21);
    await _scheduleNotification(id: 104, title: AppStrings.notificationTitle, body: AppStrings.notification30DayMessage, scheduledDate: day30);
  }
```

## メッセージ定義 (lib/constants.dart)
定数として定義し、多言語対応させています。
