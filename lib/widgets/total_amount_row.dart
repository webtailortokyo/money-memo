import 'package:flutter/material.dart';

import 'package:money_memo/widgets/money_amount_text.dart';
import '../utils/format_utils.dart';
import '../constants.dart';
import '../app_state.dart';

class TotalAmountRow extends StatelessWidget {
    const TotalAmountRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,

    required this.formatAmount,
    this.symbol,
    });

    final String label;
    final num value;
    final Color color;
    final String? symbol;

    final String Function(num) formatAmount;

    @override
    Widget build(BuildContext context) {
    final sym = symbol ?? currencyNotifier.value;
    final isSuffix = isSuffixUnit(sym);

    final amountTextWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
            if (!isSuffix) ...[
                Text(
                    sym,
                    style: TextStyle(
                    color: color,
                    fontSize: AppNumbers.totalAmountSize,
                    fontWeight: FontWeight.bold,
                    ),
                ),
                const SizedBox(width: 2),
            ],
            MoneyAmountText(
                text: formatAmount(value),
                color: color,
                showSign: false,
                numberSize: AppNumbers.totalAmountSize,
            ),
            if (isSuffix) ...[
                const SizedBox(width: 4),
                Text(
                    sym,
                    style: TextStyle(
                    color: color,
                    fontSize: AppNumbers.sectionTitleFontSize, // サフィックスは少し小さめに
                    fontWeight: FontWeight.bold,
                    ),
                ),
            ],
        ],
    );

    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: AppNumbers.sectionTitleFontSize)),
        amountTextWidget,
        ],
    );
    }
}