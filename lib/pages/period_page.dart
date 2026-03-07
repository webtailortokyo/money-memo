// lib/pages/period_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/money_entry.dart';
import '../theme.dart';
import '../widgets/money_entry_card.dart';
import '../widgets/total_amount_row.dart';
import '../utils/format_utils.dart';
import '../utils/sort_entries.dart';
import '../constants.dart';

enum PeriodViewMode { monthly, yearly }

class PeriodPage extends StatefulWidget {
  const PeriodPage({super.key});

  @override
  State<PeriodPage> createState() => _PeriodPageState();
}

class _PeriodPageState extends State<PeriodPage> {
  late Box<MoneyEntry> box;

  DateTime targetDate = DateTime(DateTime.now().year, DateTime.now().month);
  PeriodViewMode viewMode = PeriodViewMode.monthly;

  @override
  void initState() {
    super.initState();
    box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
  }

  void _changePeriod(int offset) {
    setState(() {
      if (viewMode == PeriodViewMode.monthly) {
        targetDate = DateTime(targetDate.year, targetDate.month + offset);
      } else {
        targetDate = DateTime(targetDate.year + offset, targetDate.month);
      }
    });
  }

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: targetDate,
      firstDate: DateTime(AppNumbers.minDatePickerYear),
      lastDate: DateTime(AppNumbers.maxDatePickerYear),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        if (viewMode == PeriodViewMode.monthly) {
          targetDate = DateTime(picked.year, picked.month);
        } else {
          targetDate = DateTime(picked.year, 1);
        }
      });
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
          final List<MoneyEntry> filtered;
          final String periodLabel;

          if (viewMode == PeriodViewMode.monthly) {
            filtered = entries.where((e) {
              return e.date.year == targetDate.year && e.date.month == targetDate.month;
            }).toList();
            periodLabel = '${targetDate.year}年${targetDate.month}月';
          } else {
            filtered = entries.where((e) {
              return e.date.year == targetDate.year;
            }).toList();
            periodLabel = '${targetDate.year}年';
          }

          int totalIncrease = 0;
          int totalDecrease = 0;

          for (final e in filtered) {
            if (e.type == MoneyEntryTypes.increase) {
              totalIncrease += e.amount;
            } else if (e.type == MoneyEntryTypes.decrease) {
              totalDecrease += e.amount;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 モード切替
                Row(
                  children: [
                    _buildModeButton(PeriodViewMode.monthly, '月間'),
                    const SizedBox(width: 8),
                    _buildModeButton(PeriodViewMode.yearly, '年間'),
                  ],
                ),
                const SizedBox(height: 12),

                /// 🔹 期間選択
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sectionBg,
                    borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.pink, size: 32),
                        onPressed: () => _changePeriod(-1),
                      ),
                      GestureDetector(
                        onTap: _pickPeriod,
                        child: Text(
                          periodLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainText,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppColors.pink, size: 32),
                        onPressed: () => _changePeriod(1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppNumbers.largeSpacing),

                /// 🔹 コピーボタン
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareRecord(periodLabel, filtered, totalIncrease, totalDecrease),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppNumbers.mediumSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text(AppStrings.copyButtonText),
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
                        value: totalIncrease,
                        color: AppColors.increaseAmount,
                        formatAmount: formatAmount,
                      ),
                      const SizedBox(height: AppNumbers.smallSpacing),
                      TotalAmountRow(
                        label: AppStrings.decreaseTypeLabel,
                        value: totalDecrease,
                        color: AppColors.decreaseAmount,
                        formatAmount: formatAmount,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),

                /// 🔹 内訳 / 月別リスト
                Text(
                  viewMode == PeriodViewMode.monthly ? AppStrings.detailSectionTitle : '■ 月別集計',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize),
                ),
                const SizedBox(height: AppNumbers.smallSpacing),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('記録はありません')),
                  )
                else if (viewMode == PeriodViewMode.monthly)
                  ...filtered.map((e) => MoneyEntryCard(entry: e))
                else
                  ..._buildYearlyMonthlyList(filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeButton(PeriodViewMode mode, String label) {
    final isSelected = viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pink : AppColors.sectionBg,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.mainText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildYearlyMonthlyList(List<MoneyEntry> yearlyEntries) {
    final Map<int, Map<String, int>> monthlySums = {};
    for (int i = 1; i <= 12; i++) {
      monthlySums[i] = {'increase': 0, 'decrease': 0};
    }

    for (final e in yearlyEntries) {
      if (e.type == MoneyEntryTypes.increase) {
        monthlySums[e.date.month]!['increase'] = monthlySums[e.date.month]!['increase']! + e.amount;
      } else if (e.type == MoneyEntryTypes.decrease) {
        monthlySums[e.date.month]!['decrease'] = monthlySums[e.date.month]!['decrease']! + e.amount;
      }
    }

    return monthlySums.entries.where((entry) => entry.value['increase']! > 0 || entry.value['decrease']! > 0).map((entry) {
      final month = entry.key;
      final sums = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
        ),
        child: Row(
          children: [
            Text('${month}月', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (sums['increase']! > 0)
                  Text('+${formatAmount(sums['increase']!)}', style: const TextStyle(color: AppColors.increaseAmount, fontSize: 13)),
                if (sums['decrease']! > 0)
                  Text('-${formatAmount(sums['decrease']!)}', style: const TextStyle(color: AppColors.decreaseAmount, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _shareRecord(String periodLabel, List<MoneyEntry> filtered, int totalIncrease, int totalDecrease) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('記録がない期間は共有できません')));
      return;
    }

    final text = StringBuffer()..writeln('$periodLabel の記録\n');
    text.writeln(AppStrings.totalSectionTitle);
    text.writeln('${AppStrings.increaseTypeLabel}\t$totalIncrease');
    text.writeln('${AppStrings.decreaseTypeLabel}\t$totalDecrease');
    text.writeln('');

    if (viewMode == PeriodViewMode.monthly) {
      text.writeln(AppStrings.detailSectionTitle);
      text.writeln(AppStrings.clipboardHeader);
      for (final e in filtered) {
        final label = e.type == MoneyEntryTypes.increase ? AppStrings.increaseTypeLabel : AppStrings.decreaseTypeLabel;
        final signedAmount = e.type == MoneyEntryTypes.increase ? e.amount : -e.amount;
        text.writeln('${formatDate(e.date)}\t${e.memo}\t$label\t$signedAmount');
      }
    } else {
      text.writeln('■ 月別集計');
      text.writeln('月\t${AppStrings.increaseTypeLabel}\t${AppStrings.decreaseTypeLabel}');
      final Map<int, Map<String, int>> monthlySums = {};
      for (final e in filtered) {
        monthlySums.putIfAbsent(e.date.month, () => {'in': 0, 'out': 0});
        if (e.type == MoneyEntryTypes.increase) {
          monthlySums[e.date.month]!['in'] = monthlySums[e.date.month]!['in']! + e.amount;
        } else {
          monthlySums[e.date.month]!['out'] = monthlySums[e.date.month]!['out']! + e.amount;
        }
      }
      final sortedMonths = monthlySums.keys.toList()..sort();
      for (final m in sortedMonths) {
        text.writeln('${m}月\t${monthlySums[m]!['in']}\t${monthlySums[m]!['out']}');
      }
    }

    text.writeln('\n${AppStrings.clipboardNote}');
    
    // OS標準の共有ダイアログを表示
    await Share.share(text.toString());
  }
}
