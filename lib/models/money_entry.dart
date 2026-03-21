import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';

part 'money_entry.g.dart';

@HiveType(typeId: 0)
class MoneyEntry extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String memo;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final DateTime date;

  /// 🔽 追加：実際に保存した瞬間の時刻（並び順用）
  @HiveField(4)
  final DateTime createdAt;

  /// 🔽 追加：保存時の通貨記号
  @HiveField(5)
  final String? currency;

  /// 🔽 追加：保存時の小数点桁数
  @HiveField(6)
  final int? decimalDigits;

  MoneyEntry({
    required num amount, // int/double 両方受け取れるように num に
    required this.memo,
    required this.type,
    required this.date,
    DateTime? createdAt,
    this.currency,
    this.decimalDigits,
  }) : amount = amount.toDouble(),
       createdAt = createdAt ?? DateTime.now();

  /// 🔽 表示専用：＋ / − を付けた金額文字列
  String get displayAmount {
    // レコード固有の情報を優先し、無ければグローバル（旧データ用）を参照
    final digits = decimalDigits ?? decimalDigitsNotifier.value;
    final symbol = currency ?? currencyNotifier.value;
    
    final formatter = NumberFormat.currency(
      symbol: '', // 記号は手動で付けるため空に
      decimalDigits: digits,
    );
    final formattedAmount = formatter.format(amount).trim();

    switch (type) {
      case 'decrease':
        return '-$symbol$formattedAmount';
      case 'increase':
        return '+$symbol$formattedAmount';
      case 'memo':
        return 'メモ';
      default:
        return '$symbol$formattedAmount';
    }
  }
}