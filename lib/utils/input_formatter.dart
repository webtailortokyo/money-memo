import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

// 数字を入力すると自動でカンマを付けるクラス（小数点対応版）
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final int? initialDecimalDigits;

  ThousandsSeparatorInputFormatter({this.initialDecimalDigits});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    // 通貨設定を取得（指定があればそれを使用、なければグローバル設定を参照）
    final decimalDigits = initialDecimalDigits ?? decimalDigitsNotifier.value;

    // 数字以外（カンマや小数点）をすべて除去
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // 空の場合は空で返す
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // 整数としてパース
    double value = double.tryParse(digitsOnly) ?? 0;
    
    // 小数点以下の桁数に合わせて値を調整 (例: 2桁なら 123 -> 1.23)
    if (decimalDigits > 0) {
      for (int i = 0; i < decimalDigits; i++) {
        value /= 10;
      }
    }

    // フォーマット (カンマ区切り + 指定の小数点桁数)
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
    );
    String newString = formatter.format(value).trim();

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}