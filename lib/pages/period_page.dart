// lib/pages/period_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vibration/vibration.dart';

import '../models/money_entry.dart';
import '../theme.dart';
import '../widgets/money_entry_card.dart';
import '../widgets/period_date_selector.dart';
import '../widgets/total_amount_row.dart';
import '../utils/format_utils.dart';
import '../utils/sort_entries.dart';
import '../constants.dart';

class PeriodPage extends StatefulWidget {
  const PeriodPage({super.key});

  @override
  State<PeriodPage> createState() => _PeriodPageState();
}

class _PeriodPageState extends State<PeriodPage> {
  late Box<MoneyEntry> box;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: AppNumbers.initialPeriodDays));
  DateTime toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
  }


  Future<void> _pickDate({
    required DateTime initial,
    required void Function(DateTime) onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
     
      firstDate: DateTime(AppNumbers.minDatePickerYear),
      lastDate: DateTime(AppNumbers.maxDatePickerYear),
    );

    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: AppNumbers.appBarElevation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          AppStrings.periodPageTitle,
          style: TextStyle(
            color: AppColors.pink,
            fontWeight: FontWeight.bold,
            fontSize: AppNumbers.subPageTitleFontSize,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.pink),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<MoneyEntry> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text(AppStrings.noRecordMessage));
          }

          final entries = sortedEntries(box);

          final filtered = entries.where((e) {
            final d = DateTime(e.date.year, e.date.month, e.date.day);
            return !d.isBefore(fromDate) && !d.isAfter(toDate);
          }).toList();

          int increase = 0;
          int decrease = 0;


          for (final e in filtered) {
            switch (e.type) {
              case MoneyEntryTypes.increase:
                increase += e.amount;
                break;
              case MoneyEntryTypes.decrease:
                decrease += e.amount;
                break;

            }
          }

          final periodLabel =
              '${formatDate(fromDate)} 〜 ${formatDate(toDate)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 期間
                Container(
                  padding: const EdgeInsets.all(AppNumbers.defaultPadding),
                  decoration: BoxDecoration(
                    color: AppColors.sectionBg,
                    borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.dateSectionTitle,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),
                      const SizedBox(height: AppNumbers.mediumSpacing),

                      /// 🔹 期間入力
                      PeriodDateSelector(
                        date: fromDate,
                        label: AppStrings.fromLabel,
                        onTap: () => _pickDate(
                          initial: fromDate,
                          onSelected: (d) => fromDate = d,
                        ),
                        formatDate: formatDate,
                      ),
                      const SizedBox(height: AppNumbers.defaultPadding),
                      PeriodDateSelector(
                        date: toDate,
                        label: AppStrings.toLabel,
                        onTap: () => _pickDate(
                          initial: toDate,
                          onSelected: (d) => toDate = d,
                        ),
                        formatDate: formatDate,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppNumbers.largeSpacing),
                /// 🔹 コピーするボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final text = StringBuffer()
                        ..writeln('$periodLabel の記録\n');

                      // 🔹 合計
                      text.writeln(AppStrings.totalSectionTitle);
                      text.writeln('${AppStrings.increaseTypeLabel}\t$increase');
                      text.writeln('${AppStrings.decreaseTypeLabel}\t$decrease');
                      text.writeln(''); // 空行


                      // 🔹 内訳
                      text.writeln(AppStrings.detailSectionTitle);

                      // タブ区切りのヘッダ
                      text.writeln(AppStrings.clipboardHeader);

                      for (final e in filtered) {
                        // 日本語のtype名
                        String typeLabel;
                        int signedAmount;

                        switch (e.type) {
                          case MoneyEntryTypes.increase:
                            typeLabel = AppStrings.increaseTypeLabel;
                            signedAmount = e.amount; // ＋
                            break;
                          case MoneyEntryTypes.decrease:
                            typeLabel = AppStrings.decreaseTypeLabel;
                            signedAmount = -e.amount; // －
                            break;

                          default:
                            typeLabel = '';
                            signedAmount = e.amount;
                        }

                        // 金額は ±数字、カンマ無し、¥無し
                        final amountStr = signedAmount.toString();

                        text.writeln(
                          '${formatDate(e.date)}\t'
                          '${e.memo}\t'
                          '$typeLabel\t'
                          '$amountStr'
                        );
                      }
                      text.writeln('\n${AppStrings.clipboardNote}');

                      Clipboard.setData(ClipboardData(text: text.toString()));

                      if (context.mounted && (await Vibration.hasVibrator() ?? false)) {
                        Vibration.vibrate(duration: 200, amplitude: 128);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.copySuccessMessage)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppNumbers.mediumSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
                      ),
                    ),
                    child: const Text(AppStrings.copyButtonText),
                  ),
                ),

                const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),
                
                /// 🔹 合計
                Container(
                  padding: const EdgeInsets.all(AppNumbers.defaultPadding),
                  decoration: BoxDecoration(
                    color: AppColors.sectionBg,
                    borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(AppStrings.totalSectionTitle,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),
                      const SizedBox(height: AppNumbers.defaultPadding),
                      TotalAmountRow(
                        label: AppStrings.increaseTypeLabel,
                        value: increase,
                        color: AppColors.increaseAmount,
                        formatAmount: formatAmount,
                      ),
                      const SizedBox(height: AppNumbers.smallSpacing),
                      TotalAmountRow(
                        label: AppStrings.decreaseTypeLabel,
                        value: decrease,
                        color: AppColors.decreaseAmount,
                        formatAmount: formatAmount,
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),

                /// 🔹 内訳
                const Text(AppStrings.detailSectionTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),
                const SizedBox(height: AppNumbers.smallSpacing),
                ...filtered.map((e) => MoneyEntryCard(entry: e)),
              ],
            ),
          );
        },
      ),
    );
  }

}