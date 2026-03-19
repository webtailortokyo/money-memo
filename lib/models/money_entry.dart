import 'package:hive/hive.dart';
import 'package:intl/intl.dart'; // IntLパッケージをインポート

part 'money_entry.g.dart';

@HiveType(typeId: 0)
class MoneyEntry extends HiveObject {
  @HiveField(0)
  final int amount;

  @HiveField(1)
  final String memo;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final DateTime date;

  /// 🔽 追加：実際に保存した瞬間の時刻（並び順用）
  @HiveField(4)
  final DateTime createdAt;

  MoneyEntry({
    required this.amount,
    required this.memo,
    required this.type,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 🔽 表示専用：＋ / − を付けた金額文字列
  String get displayAmount {
    final formatter = NumberFormat('#,###'); // 桁区切りフォーマッタ
    final formattedAmount = formatter.format(amount);

    switch (type) {
      case 'decrease':
        return '-¥$formattedAmount';
      case 'increase':
        return '+¥$formattedAmount';
      case 'memo':
        return 'メモ';
      default:
        return '¥$formattedAmount';
    }
  }
}