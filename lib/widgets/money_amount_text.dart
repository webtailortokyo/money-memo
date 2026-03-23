import 'package:flutter/material.dart';
import '../constants.dart';

class MoneyAmountText extends StatelessWidget {
  final String text;
  final Color color;
  final bool showSign;
  final double numberSize;
  final double signSize;

  const MoneyAmountText({
    super.key,
    required this.text,
    required this.color,
    this.showSign = true,
    this.numberSize = AppNumbers.amountTextFontSize,
    this.signSize = AppNumbers.amountTextFontSize + 2,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // + -
      if ((char == '+' || char == '-') && showSign) {
        spans.add(
          TextSpan(
            text: char,
            style: TextStyle(
              fontSize: signSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );
      }
      // 数字・カンマ（符号を非表示にしても表示）
      else if (char != '+' && char != '-') {
        spans.add(
          TextSpan(
            text: char,
            style: TextStyle(
              fontSize: numberSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );
      }
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }
}
