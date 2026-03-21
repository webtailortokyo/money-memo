import 'package:intl/intl.dart';
import '../app_state.dart';

String formatDate(DateTime d) {
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