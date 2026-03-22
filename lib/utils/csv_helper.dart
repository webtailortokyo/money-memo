import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/money_entry.dart';
import '../constants.dart';

class CsvHelper {
  static const List<String> _csvHeaders = [
    'amount',
    'memo',
    'type',
    'date',
    'createdAt',
    'currency',
    'decimalDigits',
  ];

  /// 全データをCSV形式でエクスポートする
  static Future<void> exportCsv(BuildContext context) async {
    try {
      final box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
      final entries = box.values.toList();

      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('エクスポートする記録がありません')),
          );
        }
        return;
      }

      final List<List<dynamic>> csvData = [
        _csvHeaders,
      ];

      for (var entry in entries) {
        csvData.add([
          entry.amount,
          entry.memo,
          entry.type,
          entry.date.toIso8601String(),
          entry.createdAt.toIso8601String(),
          entry.currency ?? '',
          entry.decimalDigits ?? '',
        ]);
      }

      final String csvString = '\uFEFF${const ListToCsvConverter().convert(csvData)}';

      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'money_memo_backup_$dateStr.csv';

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        // デスクトップの場合、ファイル保存ダイアログを表示
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'CSVファイルを保存',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(csvString);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSVを保存しました')),
            );
          }
        }
      } else {
        // モバイル（iOS/Android）の場合、アプリ内一時領域に保存してShareダイアログを起動
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsString(csvString);

        if (context.mounted) {
          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(path)],
            text: 'お金メモのバックアップデータです',
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    }
  }

  /// CSVファイルを選択してインポートする
  static Future<void> importCsv(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // キャンセルされたかファイルが選択されなかった
      }

      String csvString = '';
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;
        csvString = String.fromCharCodes(bytes);
      } else {
        final filePath = result.files.first.path;
        if (filePath == null) return;
        final file = File(filePath);
        csvString = await file.readAsString();
      }

      if (csvString.startsWith('\uFEFF')) {
        csvString = csvString.substring(1);
      }

      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty || csvData.length < 2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVデータが空かヘッダーのみです')),
          );
        }
        return;
      }

      final header = csvData.first.map((e) => e.toString()).toList();
      
      // headerが期待通りか簡単なチェック (最低限amount, memo, type, dateが含まれているか)
      if (!header.contains('amount') || !header.contains('type') || !header.contains('date')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVのフォーマットが正しくありません')),
          );
        }
        return;
      }

      final box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);

      int importedCount = 0;
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length < header.length) continue;

        try {
          final amountIndex = header.indexOf('amount');
          final memoIndex = header.indexOf('memo');
          final typeIndex = header.indexOf('type');
          final dateIndex = header.indexOf('date');
          final createdAtIndex = header.indexOf('createdAt');
          final currencyIndex = header.indexOf('currency');
          final decimalDigitsIndex = header.indexOf('decimalDigits');

          num amount = double.tryParse(row[amountIndex].toString()) ?? 0;
          String memo = memoIndex != -1 ? row[memoIndex].toString() : '';
          String type = typeIndex != -1 ? row[typeIndex].toString() : MoneyEntryTypes.decrease;
          DateTime date = DateTime.tryParse(row[dateIndex].toString()) ?? DateTime.now();
          
          DateTime? createdAt;
          if (createdAtIndex != -1 && row[createdAtIndex].toString().isNotEmpty) {
            createdAt = DateTime.tryParse(row[createdAtIndex].toString());
          }

          String? currency;
          if (currencyIndex != -1 && row[currencyIndex].toString().isNotEmpty) {
            currency = row[currencyIndex].toString();
          }

          int? decimalDigits;
          if (decimalDigitsIndex != -1 && row[decimalDigitsIndex].toString().isNotEmpty) {
            decimalDigits = int.tryParse(row[decimalDigitsIndex].toString());
          }

          final entry = MoneyEntry(
            amount: amount,
            memo: memo,
            type: type,
            date: date,
            createdAt: createdAt,
            currency: currency,
            decimalDigits: decimalDigits,
          );

          await box.add(entry);
          importedCount++;
        } catch (e) {
          // パースエラーなどの行はスキップ
          debugPrint('CSV row import error: $e');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$importedCount 件のデータをインポートしました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('インポートに失敗しました: $e')),
        );
      }
    }
  }
}
