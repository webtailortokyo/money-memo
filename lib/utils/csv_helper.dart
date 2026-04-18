import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/money_entry.dart';
import '../constants.dart';
import '../app_state.dart';

class CsvHelper {
  static const List<String> _csvHeaders = [
    'amount',
    'memo',
    'type',
    'date',
    'createdAt',
    'currency',
    'decimalDigits',
    'appTitle',
    'appCurrency',
    'appDecimalDigits',
    'appLanguage',
    'appTheme',
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
          appTitleNotifier.value,
          currencyNotifier.value,
          decimalDigitsNotifier.value,
          languageNotifier.value,
          appThemeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
        ]);
      }

      final String csvString = '\uFEFF${const ListToCsvConverter().convert(csvData)}';

      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'money_memo_backup_$dateStr.csv';

      if (!kIsWeb) {
        final bytes = Uint8List.fromList(utf8.encode(csvString));
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'CSVファイルを保存',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['csv'],
          bytes: bytes,
        );

        if (outputFile != null) {
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            final file = File(outputFile);
            await file.writeAsString(csvString);
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVの保存処理が完了しました')),
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
      final settingsBox = Hive.box(HiveConstants.settingsBoxName);
      bool settingsImported = false;

      int importedCount = 0;
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        if (row.length < header.length) continue;

        try {
          if (!settingsImported) {
             final appTitleIndex = header.indexOf('appTitle');
             final appCurrencyIndex = header.indexOf('appCurrency');
             final appDecimalDigitsIndex = header.indexOf('appDecimalDigits');
             final appLanguageIndex = header.indexOf('appLanguage');
             final appThemeIndex = header.indexOf('appTheme');

             if (appTitleIndex != -1 && row[appTitleIndex].toString().isNotEmpty) {
               final title = row[appTitleIndex].toString();
               settingsBox.put(HiveConstants.keyAppTitle, title);
               appTitleNotifier.value = title;
             }
             if (appCurrencyIndex != -1 && row[appCurrencyIndex].toString().isNotEmpty) {
               final currency = row[appCurrencyIndex].toString();
               settingsBox.put(HiveConstants.keyCurrency, currency);
               currencyNotifier.value = currency;
             }
             if (appDecimalDigitsIndex != -1 && row[appDecimalDigitsIndex].toString().isNotEmpty) {
               final digits = int.tryParse(row[appDecimalDigitsIndex].toString()) ?? 0;
               settingsBox.put(HiveConstants.keyDecimalDigits, digits);
               decimalDigitsNotifier.value = digits;
             }
             if (appLanguageIndex != -1 && row[appLanguageIndex].toString().isNotEmpty) {
               final lang = row[appLanguageIndex].toString();
               settingsBox.put(HiveConstants.keyLanguage, lang);
               languageNotifier.value = lang;
             }
             if (appThemeIndex != -1 && row[appThemeIndex].toString().isNotEmpty) {
               final themeStr = row[appThemeIndex].toString();
               final theme = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
               settingsBox.put(HiveConstants.keyThemeMode, themeStr);
               appThemeNotifier.value = theme;
             }
             settingsImported = true;
          }

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
