import 'package:intl/intl.dart';
import '../app_state.dart';

String formatDate(DateTime d) {
  if (languageNotifier.value == 'en') {
    // e.g. Mar 21, 2026
    return DateFormat.yMMMd('en_US').format(d);
  }
  return '${d.year}/${d.month}/${d.day}';
}

String formatAmount(num value, {int? decimalDigits}) {
  final digits = decimalDigits ?? decimalDigitsNotifier.value;
  final formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: digits,
  );
  return formatter.format(value.abs()).trim();
}

bool isSuffixUnit(String symbol) {
  if (symbol.isEmpty) return false;
  final s = symbol.trim();
  // 通貨記号（プレフィックス）として扱うものを定義
  final prefixes = ['¥', '\$', '€', '£', '₽', '₩'];
  if (prefixes.contains(s)) {
    return false;
  }
  // それ以外（kg, 回, 自作単位など）はすべてサフィックスとする
  return true;
}