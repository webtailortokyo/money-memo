import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/money_entry.dart';
import '../constants.dart';
import '../widgets/milestone_dialog.dart';
import '../widgets/piggy_character.dart';

class MilestoneManager {
  static const String _keyLastCount = 'lastShownCountMilestone';
  static const String _keyLastDays = 'lastShownDaysMilestone';

  /// 記録保存直後に呼び出し、必要ならお祝いを表示する
  static Future<void> checkAndShow(BuildContext context) async {
    final moneyBox = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
    final statsBox = Hive.box(HiveConstants.statsBoxName);

    // 1. 回数・日数の計算
    final totalCount = moneyBox.length;
    final uniqueDays = moneyBox.values
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .length;

    // 2. 最後に表示したマイルストーンを取得
    final lastCount = statsBox.get(_keyLastCount, defaultValue: 0) as int;
    final lastDays = statsBox.get(_keyLastDays, defaultValue: 0) as int;

    // 3. マイルストーン判定（日数を優先し、表示した場合は回数の方を次回に回す）
    final dayShown = await _checkDaysMilestone(context, uniqueDays, lastDays, statsBox);
    if (dayShown || !context.mounted) return;

    await _checkCountMilestone(context, totalCount, lastCount, statsBox);
  }

  static Future<bool> _checkCountMilestone(
    BuildContext context,
    int currentCount,
    int lastMilestone,
    Box statsBox,
  ) async {
    int? nextMilestone;

    // 定義済みのマイルストーンリスト
    const milestones = [1, 10, 30, 50];
    for (var m in milestones) {
      if (currentCount >= m && lastMilestone < m) {
        nextMilestone = m;
      }
    }

    // 50回以降、50回ごとに判定
    if (currentCount >= 100) {
      final milestoneStep = (currentCount ~/ 50) * 50;
      if (lastMilestone < milestoneStep) {
        nextMilestone = milestoneStep;
      }
    }

    if (nextMilestone != null) {
      String message;
      String lottieAsset = 'assets/lottie/confetti.json';
      PiggyEyes eyes = PiggyEyes.smile;
      PiggyPose pose = PiggyPose.joy;

      // メッセージの決定
      if (nextMilestone == 1) {
        message = AppStrings.milestoneCount1;
        eyes = PiggyEyes.dot;
        pose = PiggyPose.basic; // 1回目は基本ポーズ
      } else if (nextMilestone == 10) {
        message = AppStrings.milestoneCount10;
      } else if (nextMilestone == 30) {
        message = AppStrings.milestoneCount30;
      } else if (nextMilestone == 50) {
        message = AppStrings.milestoneCount50;
        lottieAsset = 'assets/lottie/fireworks.json'; // 50回は特別
      } else {
        // 50回ごとのランダムメッセージ
        final random = Random();
        final template = AppStrings.milestoneCountEvery50[random.nextInt(AppStrings.milestoneCountEvery50.length)];
        message = template.replaceFirst('{count}', nextMilestone.toString());
      }

      await MilestoneDialog.show(
        context,
        message: message,
        eyes: eyes,
        pose: pose,
        lottieAsset: lottieAsset,
      );

      // 達成記録
      await statsBox.put(_keyLastCount, nextMilestone);
      return true;
    }
    return false;
  }

  static Future<bool> _checkDaysMilestone(
    BuildContext context,
    int currentDays,
    int lastMilestone,
    Box statsBox,
  ) async {
    int? nextMilestone;

    const milestones = [3, 7, 30, 100];
    for (var m in milestones) {
      if (currentDays >= m && lastMilestone < m) {
        nextMilestone = m;
      }
    }

    // 100日以降、100日ごとに判定
    if (currentDays >= 200) {
      final milestoneStep = (currentDays ~/ 100) * 100;
      if (lastMilestone < milestoneStep) {
        nextMilestone = milestoneStep;
      }
    }

    if (nextMilestone != null) {
      String message;
      String lottieAsset = 'assets/lottie/confetti.json';
      PiggyPose pose = PiggyPose.joy;

      if (nextMilestone == 3) {
        message = AppStrings.milestoneDay3;
        pose = PiggyPose.think; // 3日坊主卒業は応援ポーズ
      } else if (nextMilestone == 7) {
        message = AppStrings.milestoneDay7;
      } else if (nextMilestone == 30) {
        message = AppStrings.milestoneDay30;
        lottieAsset = 'assets/lottie/fireworks.json'; // 30日/100日は特別
      } else if (nextMilestone == 100) {
        message = AppStrings.milestoneDay100;
        lottieAsset = 'assets/lottie/fireworks.json';
      } else {
        // 100日ごとのランダムメッセージ
        final random = Random();
        final template = AppStrings.milestoneDayEvery100[random.nextInt(AppStrings.milestoneDayEvery100.length)];
        message = template.replaceFirst('{days}', nextMilestone.toString());
      }

      await MilestoneDialog.show(
        context,
        message: message,
        pose: pose,
        lottieAsset: lottieAsset,
      );

      // 達成記録
      await statsBox.put(_keyLastDays, nextMilestone);
      return true;
    }
    return false;
  }
}
