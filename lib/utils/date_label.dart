import '../constants.dart';
import 'format_utils.dart';

String dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);

  final diff = today.difference(target).inDays;

  if (diff == 0) return AppStrings.today;
  if (diff == 1) return AppStrings.yesterday;

  return formatDate(date);
}
