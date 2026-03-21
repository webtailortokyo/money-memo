// lib/pages/period_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/money_entry.dart';
import '../theme.dart';
import '../widgets/money_entry_card.dart';
import '../widgets/total_amount_row.dart';
import '../utils/format_utils.dart';
import '../utils/sort_entries.dart';
import '../constants.dart';
import '../app_state.dart';
import 'input_page.dart';

enum PeriodViewMode { monthly, yearly }

class PeriodPage extends StatefulWidget {
  const PeriodPage({super.key});

  @override
  State<PeriodPage> createState() => _PeriodPageState();
}

class CurrencySummary {
  final String symbol;
  final int decimalDigits;
  double increase = 0;
  double decrease = 0;

  CurrencySummary(this.symbol, this.decimalDigits);
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
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 40,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, color: AppColors.accent, size: 28),

            const SizedBox(width: 8),
            Text(
              AppStrings.periodPageTitle,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: AppNumbers.subPageTitleFontSize,
              ),
            ),
          ],
        ),

        iconTheme: const IconThemeData(color: AppColors.accent),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<MoneyEntry> box, _) {
          if (box.isEmpty) {
            return Center(child: Text(AppStrings.noRecordMessage));
          }

          final entries = sortedEntries(box);
          final List<MoneyEntry> filtered;
          final String periodLabel;

          if (viewMode == PeriodViewMode.monthly) {
            filtered = entries.where((e) {
              return e.date.year == targetDate.year && e.date.month == targetDate.month;
            }).toList();
            if (languageNotifier.value == 'en') {
              periodLabel = DateFormat.yMMM('en_US').format(targetDate);
            } else {
              periodLabel = '${targetDate.year}${AppStrings.yearLabel}${targetDate.month}${AppStrings.monthLabel}';
            }
          } else {
            filtered = entries.where((e) {
              return e.date.year == targetDate.year;
            }).toList();
            if (languageNotifier.value == 'en') {
              periodLabel = targetDate.year.toString();
            } else {
              periodLabel = '${targetDate.year}${AppStrings.yearLabel}';
            }
          }

          final Map<String, CurrencySummary> totals = {};
          for (final e in filtered) {
            final sym = e.currency ?? '¥';
            final digits = e.decimalDigits ?? 0;
            final key = '$sym-$digits';
            
            totals.putIfAbsent(key, () => CurrencySummary(sym, digits));
            if (e.type == MoneyEntryTypes.increase) {
              totals[key]!.increase += e.amount;
            } else if (e.type == MoneyEntryTypes.decrease) {
              totals[key]!.decrease += e.amount;
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
                    _buildModeButton(PeriodViewMode.monthly, AppStrings.monthlySummaryTitle),
                    const SizedBox(width: 8),
                    _buildModeButton(PeriodViewMode.yearly, AppStrings.yearlySummaryTitle),
                  ],
                ),
                const SizedBox(height: 12),

                /// 🔹 期間選択
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppColors.accent, size: 32),
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
                        icon: const Icon(Icons.chevron_right, color: AppColors.accent, size: 32),
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
                    onPressed: () => _shareRecord(periodLabel, filtered, totals),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppNumbers.mediumSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 20),
                    label: Text(AppStrings.copyButtonText),
                  ),
                ),

                const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),

                /// 🔹 合計
                Row(
                  children: [
                    const Icon(Icons.analytics_rounded, color: AppColors.accent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.totalSectionTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize),
                    ),
                  ],
                ),
                const SizedBox(height: AppNumbers.smallSpacing),
                Container(
                  padding: const EdgeInsets.all(AppNumbers.defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (totals.isEmpty)
                        const Center(child: Text('-'))
                      else
                        ..._sortSummaries(totals.values).map((summary) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            key: ValueKey('${summary.symbol}-${summary.decimalDigits}'),
                            children: [
                              TotalAmountRow(
                                label: AppStrings.increaseTypeLabel,
                                value: summary.increase,
                                color: AppColors.increaseAmount,
                                symbol: summary.symbol,
                                formatAmount: (val) => formatAmount(val, decimalDigits: summary.decimalDigits),
                              ),
                              const SizedBox(height: 4),
                              TotalAmountRow(
                                label: AppStrings.decreaseTypeLabel,
                                value: summary.decrease,
                                color: AppColors.decreaseAmount,
                                symbol: summary.symbol,
                                formatAmount: (val) => formatAmount(val, decimalDigits: summary.decimalDigits),
                              ),
                              if (summary != _sortSummaries(totals.values).last)
                                const Divider(height: 16),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),

                const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),

                /// 🔹 内訳 / 月別リスト
                Row(
                  children: [
                    Icon(
                      viewMode == PeriodViewMode.monthly ? Icons.list_alt_rounded : Icons.calendar_month_rounded,
                      color: AppColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      viewMode == PeriodViewMode.monthly ? AppStrings.detailSectionTitle : AppStrings.monthlySummaryTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize),
                    ),
                  ],
                ),
                const SizedBox(height: AppNumbers.smallSpacing),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text(AppStrings.noRecordInPeriod)),
                  )
                else if (viewMode == PeriodViewMode.monthly)
                  ...filtered.map((e) => MoneyEntryCard(
                        entry: e,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InputPage(entry: e),
                            ),
                          );
                        },
                        onLongPress: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(AppStrings.deleteDialogTitle),
                              content: Text(AppStrings.deleteDialogContent),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(AppStrings.cancelButtonText),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    AppStrings.deleteButtonText,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (result == true) {
                            box.delete(e.key);
                          }
                        },
                      ))
                else
                  ..._buildYearlyMonthlyList(filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔽 追加：通貨の表示順序を定義（円 -> ドル -> ユーロ）
  List<CurrencySummary> _sortSummaries(Iterable<CurrencySummary> summaries) {
    return summaries.toList()
      ..sort((a, b) {
        final order = {'¥': 0, '\$': 1, '€': 2};
        final aOrder = order[a.symbol] ?? 99;
        final bOrder = order[b.symbol] ?? 99;
        return aOrder.compareTo(bOrder);
      });
  }

  Widget _buildModeButton(PeriodViewMode mode, String label) {
    final isSelected = viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
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

  String _formatMonth(int month) {
    if (languageNotifier.value == 'en') {
      return DateFormat.MMM('en_US').format(DateTime(2024, month));
    }
    return '${month}${AppStrings.monthLabel}';
  }

  List<Widget> _buildYearlyMonthlyList(List<MoneyEntry> yearlyEntries) {
    final Map<int, Map<String, CurrencySummary>> monthlyCurrencySums = {};
    for (int i = 1; i <= 12; i++) {
      monthlyCurrencySums[i] = {};
    }

    for (final e in yearlyEntries) {
      final sym = e.currency ?? '¥';
      final digits = e.decimalDigits ?? 0;
      final key = '$sym-$digits';
      
      final monthMap = monthlyCurrencySums[e.date.month]!;
      monthMap.putIfAbsent(key, () => CurrencySummary(sym, digits));
      
      if (e.type == MoneyEntryTypes.increase) {
        monthMap[key]!.increase += e.amount;
      } else if (e.type == MoneyEntryTypes.decrease) {
        monthMap[key]!.decrease += e.amount;
      }
    }

    return monthlyCurrencySums.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) {
      final month = entry.key;
      final summaries = _sortSummaries(entry.value.values);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          children: [
            Text(_formatMonth(month), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summaries.map((s) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (s.increase > 0)
                    Text('+${s.symbol}${formatAmount(s.increase, decimalDigits: s.decimalDigits)}', 
                        style: const TextStyle(color: AppColors.increaseAmount, fontSize: 13)),
                  if (s.decrease > 0)
                    Text('-${s.symbol}${formatAmount(s.decrease, decimalDigits: s.decimalDigits)}', 
                        style: const TextStyle(color: AppColors.decreaseAmount, fontSize: 13)),
                ],
              )).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getCurrencyCode(String symbol) {
    switch (symbol) {
      case '¥': return 'JPY';
      case '\$': return 'USD';
      case '€': return 'EUR';
      default: return symbol;
    }
  }

  Future<void> _shareRecord(String periodLabel, List<MoneyEntry> filtered, Map<String, CurrencySummary> totals) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.shareNoRecordError)));
      return;
    }

    final isEn = languageNotifier.value == 'en';
    final text = StringBuffer();

    // タイトル
    if (viewMode == PeriodViewMode.monthly) {
      if (isEn) {
        text.writeln(DateFormat.yMMMM('en_US').format(targetDate));
      } else {
        text.writeln('${targetDate.year}${AppStrings.yearLabel}${targetDate.month}${AppStrings.monthLabel}${AppStrings.shareMessage}');
      }
    } else {
      if (isEn) {
        text.writeln(targetDate.year.toString());
      } else {
        text.writeln('${targetDate.year}${AppStrings.yearLabel}${AppStrings.shareMessage}');
      }
    }
    text.writeln('');

    // 合計セクション
    text.writeln(AppStrings.totalSectionTitle);
    
    final sortedSummaries = _sortSummaries(totals.values);
    for (final summary in sortedSummaries) {
      text.writeln(_getCurrencyCode(summary.symbol));
      final inc = formatAmount(summary.increase, decimalDigits: summary.decimalDigits);
      final dec = formatAmount(summary.decrease, decimalDigits: summary.decimalDigits);
      text.writeln('${AppStrings.shareIncreaseLabel}${summary.symbol}$inc');
      text.writeln('${AppStrings.shareDecreaseLabel}${summary.symbol}$dec');
      text.writeln('');
    }

    // 内訳 / 月別セクション
    if (viewMode == PeriodViewMode.monthly) {
      text.writeln(AppStrings.detailSectionTitle);
      for (final e in filtered) {
        if (e.type == MoneyEntryTypes.memo) {
          text.writeln('${formatDate(e.date)} ${e.memo}');
          continue;
        }
        final sym = e.currency ?? '¥';
        final digits = e.decimalDigits ?? 0;
        final amountText = formatAmount(e.amount, decimalDigits: digits);
        final signedAmount = e.type == MoneyEntryTypes.increase ? '+$sym$amountText' : '-$sym$amountText';
        text.writeln('${formatDate(e.date)} ${e.memo}  $signedAmount');
      }
    } else {
      text.writeln(AppStrings.monthlySummaryTitle);
      
      final Map<int, Map<String, CurrencySummary>> monthlyCurrencySums = {};
      for (final e in filtered) {
        final sym = e.currency ?? '¥';
        final digits = e.decimalDigits ?? 0;
        final key = '$sym-$digits';
        monthlyCurrencySums.putIfAbsent(e.date.month, () => {});
        monthlyCurrencySums[e.date.month]!.putIfAbsent(key, () => CurrencySummary(sym, digits));
        
        if (e.type == MoneyEntryTypes.increase) {
          monthlyCurrencySums[e.date.month]![key]!.increase += e.amount;
        } else if (e.type == MoneyEntryTypes.decrease) {
          monthlyCurrencySums[e.date.month]![key]!.decrease += e.amount;
        }
      }
      
      final sortedMonths = monthlyCurrencySums.keys.toList()..sort();
      for (final m in sortedMonths) {
        final summaries = _sortSummaries(monthlyCurrencySums[m]!.values);
        final monthName = _formatMonth(m);
        for (final s in summaries) {
          final inc = formatAmount(s.increase, decimalDigits: s.decimalDigits);
          final dec = formatAmount(s.decrease, decimalDigits: s.decimalDigits);
          
          if (s.increase > 0 && s.decrease > 0) {
            text.writeln('$monthName +${s.symbol}$inc / -${s.symbol}$dec');
          } else if (s.increase > 0) {
            text.writeln('$monthName +${s.symbol}$inc');
          } else if (s.decrease > 0) {
            text.writeln('$monthName -${s.symbol}$dec');
          }
        }
      }
    }
    
    // OS標準の共有ダイアログを表示
    await Share.share(text.toString().trim());
  }
}
