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

  /// 遞ｮ鬘槭＃縺ｨ縺ｮ繝｡繧､繝ｳ繧ｫ繝ｩ繝ｼ・亥ｷｦ繧｢繧ｯ繧ｻ繝ｳ繝医き繝ｩ繝ｼ・・
  Color _typeColor(BuildContext context) {
    switch (entry.type) {
      case 'decrease':
        return context.appColors.decrease;
      case 'increase':
        return context.appColors.increase;
      case 'memo':
        return context.appColors.memo;
      default:
        return Colors.grey;
    }
  }

  /// 遞ｮ鬘槭＃縺ｨ縺ｮ閭梧勹濶ｲ
  Color _bgColor(BuildContext context) {
    switch (entry.type) {
      case 'decrease':
        return context.appColors.decreaseBg;
      case 'increase':
        return context.appColors.increaseBg;

      case 'memo':
        return context.appColors.memoBg;
      default:
        return context.appColors.sectionBg;
    }
  }

  /// 遞ｮ鬘槭＃縺ｨ縺ｮ驥鷹｡崎牡
  Color _amountColor(BuildContext context) {
    switch (entry.type) {
      case 'decrease':
        return context.appColors.decreaseAmount;
      case 'increase':
        return context.appColors.increaseAmount;

      default:
        return Colors.grey;
    }
  }



  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context);
    final bgColor = _bgColor(context);
    final amountColor = _amountColor(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Stack(
          children: [
            /// 譟斐ｉ縺九＞繧ｷ繝｣繝峨え & 蟾ｦ縺ｮ繧｢繧ｯ繧ｻ繝ｳ繝亥ｽｱ
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  // 騾壼ｸｸ縺ｮ縺ｵ繧上▲縺ｨ縺励◆蠖ｱ
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),

                  // 笘・蟾ｦ蛛ｴ縺縺代↓繧｢繧ｯ繧ｻ繝ｳ繝亥ｽｱ
                  BoxShadow(
                    color: color,
                    spreadRadius: -1,
                    offset: const Offset(-7, 0),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(left: 18),
              child: Container(
                constraints: const BoxConstraints(minHeight: 82),
                child: Row(
                  children: [
                    /// 繝｡繧､繝ｳ蜀・ｮｹ
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.memo,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.appColors.mainText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              dateLabel(entry.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appColors.mainText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// 驥鷹｡・+ 驫陦後い繧､繧ｳ繝ｳ
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [


                          /// 驥鷹｡・
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
