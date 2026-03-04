import 'package:flutter/material.dart';

import '../models/money_entry.dart';
import '../theme.dart';
import '../utils/date_label.dart';
import '../widgets/money_amount_text.dart';

class MoneyEntryCard extends StatelessWidget {
  final MoneyEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MoneyEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
  });

  /// 種類ごとのメインカラー（左アクセントカラー）
  Color _typeColor() {
    switch (entry.type) {
      case 'decrease':
        return AppColors.decrease;
      case 'increase':
        return AppColors.increase;

      default:
        return Colors.grey;
    }
  }

  /// 種類ごとの背景色
  Color _bgColor() {
    switch (entry.type) {
      case 'decrease':
        return AppColors.decreaseBg;
      case 'increase':
        return AppColors.increaseBg;

      default:
        return AppColors.sectionBg;
    }
  }

  /// 種類ごとの金額色
  Color _amountColor() {
    switch (entry.type) {
      case 'decrease':
        return AppColors.decreaseAmount;
      case 'increase':
        return AppColors.increaseAmount;

      default:
        return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    final color = _typeColor();
    final bgColor = _bgColor();
    final amountColor = _amountColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Stack(
          children: [
            /// 柔らかいシャドウ & 左のアクセント影
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // 通常のふわっとした影
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),

                  // ★ 左側だけにアクセント影
                  BoxShadow(
                    color: color,
                    spreadRadius: -1,
                    offset: const Offset(-7, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(left: 18),
              child: SizedBox(
                height: 82,
                child: Row(
                  children: [
                    /// メイン内容
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.memo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel(entry.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mainText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// 金額 + 銀行アイコン
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [


                          /// 金額
                          MoneyAmountText(
                            text: entry.displayAmount,
                            color: amountColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
