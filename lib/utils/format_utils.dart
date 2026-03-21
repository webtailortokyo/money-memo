import 'package:intl/intl.dart';
import '../app_state.dart';

String formatDate(DateTime d) {
  if (languageNotifier.value == 'en') {
    // e.g. Mar 21, 2026
    return DateFormat.yMMMd('en_US').format(d);
  }
  return '${d.year}/${d.month}/${d.day}';
}

String formatAmount(num value) {
  final decimalDigits = decimalDigitsNotifier.value;
  final formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: decimalDigits,
  );
  return formatter.format(value.abs()).trim();
}