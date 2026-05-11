// lib/pages/period_page.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
  String? selectedCurrency;

  @override
  void initState() {
    super.initState();
    box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
    selectedCurrency = currencyNotifier.value;
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
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, child) {
        return SelectionArea(
          child: Scaffold(
            backgroundColor: context.appColors.background,
            appBar: AppBar(
              backgroundColor: context.appColors.background,
              elevation: AppNumbers.appBarElevation,
              centerTitle: false,
              titleSpacing: 0,
              leadingWidth: 40,
              leading: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: context.appColors.accent,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    color: context.appColors.accent,
                    size: 28,
                  ),

                  SizedBox(width: 8),
                  Text(
                    AppStrings.periodPageTitle,
                    style: TextStyle(
                      color: context.appColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: AppNumbers.subPageTitleFontSize,
                    ),
                  ),
                ],
              ),

              iconTheme: IconThemeData(color: context.appColors.accent),
            ),
            body: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<MoneyEntry> box, _) {
                if (box.isEmpty) {
                  return Center(child: Text(AppStrings.noRecordMessage));
                }

                final entries = sortedEntries(box);
                final List<MoneyEntry> periodFiltered;
                final String periodLabel;

                if (viewMode == PeriodViewMode.monthly) {
                  periodFiltered = entries.where((e) {
                    return e.date.year == targetDate.year &&
                        e.date.month == targetDate.month;
                  }).toList();
                  if (languageNotifier.value == 'en') {
                    periodLabel = DateFormat.yMMM('en_US').format(targetDate);
                  } else {
                    periodLabel =
                        '${targetDate.year}${AppStrings.yearLabel}${targetDate.month}${AppStrings.monthLabel}';
                  }
                } else {
                  periodFiltered = entries.where((e) {
                    return e.date.year == targetDate.year;
                  }).toList();
                  if (languageNotifier.value == 'en') {
                    periodLabel = targetDate.year.toString();
                  } else {
                    periodLabel = '${targetDate.year}${AppStrings.yearLabel}';
                  }
                }

                final Set<String> availableCurrencies = {currencyNotifier.value};
                for (final e in box.values) {
                  if (e.type != MoneyEntryTypes.memo) {
                    availableCurrencies.add(e.currency ?? currencyNotifier.value);
                  }
                }
                final sortedCurrencies = availableCurrencies.toList()..sort();
                if (!sortedCurrencies.contains(selectedCurrency)) {
                  selectedCurrency = sortedCurrencies.first;
                }

                final List<MoneyEntry> filtered = periodFiltered.where((e) {
                  if (e.type == MoneyEntryTypes.memo) return true;
                  final sym = e.currency ?? currencyNotifier.value;
                  return sym == selectedCurrency;
                }).toList();

                int currentDecimalDigits = decimalDigitsNotifier.value;
                for (final e in filtered) {
                  if (e.type != MoneyEntryTypes.memo && e.decimalDigits != null) {
                    currentDecimalDigits = e.decimalDigits!;
                    break;
                  }
                }

                final Map<String, CurrencySummary> totals = {};
                for (final e in filtered) {
                  if (e.type == MoneyEntryTypes.memo) continue;

                  final sym = e.currency ?? currencyNotifier.value;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppNumbers.defaultPadding,
                    vertical: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 隼 繝｢繝ｼ繝牙・譖ｿ
                      Row(
                        children: [
                          _buildModeButton(
                            PeriodViewMode.monthly,
                            AppStrings.monthlySummaryTitle,
                          ),
                          SizedBox(width: 8),
                          _buildModeButton(
                            PeriodViewMode.yearly,
                            AppStrings.yearlySummaryTitle,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      /// 🔽 追加：通貨フィルター
                      if (sortedCurrencies.length > 1) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              languageNotifier.value == 'en' ? 'Currency: ' : '表示通貨: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.appColors.mainText.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              decoration: BoxDecoration(
                                color: context.appColors.inputBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300, width: 1.0),
                              ),
                              height: 32,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCurrency,
                                  icon: Icon(Icons.arrow_drop_down, color: context.appColors.accent, size: 20),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.appColors.mainText,
                                  ),
                                  items: sortedCurrencies.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedCurrency = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                      ],

                      /// 隼 譛滄俣驕ｸ謚・
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: context.appColors.inputBg,
                          borderRadius: BorderRadius.circular(
                            AppNumbers.defaultPadding,
                          ),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.chevron_left,
                                color: context.appColors.accent,
                                size: 32,
                              ),
                              onPressed: () => _changePeriod(-1),
                            ),
                            GestureDetector(
                              onTap: _pickPeriod,
                              child: Text(
                                periodLabel,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.mainText,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.chevron_right,
                                color: context.appColors.accent,
                                size: 32,
                              ),
                              onPressed: () => _changePeriod(1),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppNumbers.largeSpacing),

                      /// 隼 繧ｳ繝斐・繝懊ち繝ｳ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _shareRecord(periodLabel, filtered, totals),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppNumbers.mediumSpacing,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppNumbers.cardBorderRadius,
                              ),
                            ),
                          ),
                          icon: Icon(Icons.share, size: 20),
                          label: Text(AppStrings.copyButtonText),
                        ),
                      ),

                      SizedBox(
                        height:
                            AppNumbers.defaultPadding + AppNumbers.smallSpacing,
                      ),

                      /// 隼 蜷郁ｨ・
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            color: context.appColors.accent,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.totalSectionTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppNumbers.sectionTitleFontSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppNumbers.smallSpacing),
                      Container(
                        padding: const EdgeInsets.all(
                          AppNumbers.defaultPadding,
                        ),
                        decoration: BoxDecoration(
                          color: context.appColors.inputBg,
                          borderRadius: BorderRadius.circular(
                            AppNumbers.cardBorderRadius,
                          ),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (totals.isEmpty)
                              Center(child: Text('-'))
                            else
                              ..._sortSummaries(totals.values).map(
                                (summary) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    key: ValueKey(
                                      '${summary.symbol}-${summary.decimalDigits}',
                                    ),
                                    children: [
                                      TotalAmountRow(
                                        label: AppStrings.increaseTypeLabel,
                                        value: summary.increase,
                                        color: context.appColors.increaseAmount,
                                        symbol: summary.symbol,
                                        formatAmount: (val) => formatAmount(
                                          val,
                                          decimalDigits: summary.decimalDigits,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      TotalAmountRow(
                                        label: AppStrings.decreaseTypeLabel,
                                        value: summary.decrease,
                                        color: context.appColors.decreaseAmount,
                                        symbol: summary.symbol,
                                        formatAmount: (val) => formatAmount(
                                          val,
                                          decimalDigits: summary.decimalDigits,
                                        ),
                                      ),
                                      if (summary !=
                                          _sortSummaries(totals.values).last)
                                        const Divider(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height:
                            AppNumbers.defaultPadding + AppNumbers.smallSpacing,
                      ),

                      /// 隼 蜀・ｨｳ / 譛亥挨繝ｪ繧ｹ繝・
                      Row(
                        children: [
                          Icon(
                            viewMode == PeriodViewMode.monthly
                                ? Icons.list_alt_rounded
                                : Icons.calendar_month_rounded,
                            color: context.appColors.accent,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            viewMode == PeriodViewMode.monthly
                                ? AppStrings.detailSectionTitle
                                : AppStrings.monthlySummaryTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppNumbers.sectionTitleFontSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppNumbers.smallSpacing),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(AppStrings.noRecordInPeriod),
                          ),
                        )
                      else if (viewMode == PeriodViewMode.monthly)
                        ...filtered.map(
                          (e) => MoneyEntryCard(
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
                                builder: (_) => SelectionArea(
                                  child: AlertDialog(
                                    title: Text(AppStrings.deleteDialogTitle),
                                    content: Text(
                                      AppStrings.deleteDialogContent,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          AppStrings.cancelButtonText,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          AppStrings.deleteButtonText,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (result == true) {
                                box.delete(e.key);
                              }
                            },
                          ),
                        )
                      else ...[
                        _buildYearlyGraph(filtered, currentDecimalDigits),
                        ..._buildYearlyMonthlyList(filtered),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 反 霑ｽ蜉・夐夊ｲｨ縺ｮ陦ｨ遉ｺ鬆・ｺ上ｒ螳夂ｾｩ・亥・ -> 繝峨Ν -> 繝ｦ繝ｼ繝ｭ・・
  List<CurrencySummary> _sortSummaries(Iterable<CurrencySummary> summaries) {
    return summaries.toList()..sort((a, b) {
      final order = {'ﾂ･': 0, '\$': 1, '竄ｬ': 2};
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
            color: isSelected
                ? context.appColors.accent
                : context.appColors.inputBg,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.appColors.mainText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearlyGraph(List<MoneyEntry> yearlyEntries, int decimalDigits) {
    if (yearlyEntries.isEmpty) return const SizedBox.shrink();

    final Map<int, double> monthlyIncome = {};
    final Map<int, double> monthlyExpense = {};
    for (int i = 1; i <= 12; i++) {
      monthlyIncome[i] = 0;
      monthlyExpense[i] = 0;
    }

    double maxAmount = 0;

    for (final e in yearlyEntries) {
      if (e.type == MoneyEntryTypes.increase) {
        monthlyIncome[e.date.month] = (monthlyIncome[e.date.month] ?? 0) + e.amount;
      } else if (e.type == MoneyEntryTypes.decrease) {
        monthlyExpense[e.date.month] = (monthlyExpense[e.date.month] ?? 0) + e.amount;
      }
    }

    for (int i = 1; i <= 12; i++) {
      if (monthlyIncome[i]! > maxAmount) maxAmount = monthlyIncome[i]!;
      if (monthlyExpense[i]! > maxAmount) maxAmount = monthlyExpense[i]!;
    }

    if (maxAmount == 0) return const SizedBox.shrink();

    final interval = maxAmount / 4 > 0 ? maxAmount / 4 : 1.0;

    return Container(
      height: 250,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 0, right: 16),
      decoration: BoxDecoration(
        color: context.appColors.inputBg,
        borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegend(context.appColors.increaseAmount, AppStrings.incomeLabel),
              const SizedBox(width: 16),
              _buildLegend(context.appColors.decreaseAmount, AppStrings.expenseLabel),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      final label = isIncome ? AppStrings.incomeLabel : AppStrings.expenseLabel;
                      return BarTooltipItem(
                        '$label\n$selectedCurrency${formatAmount(rod.toY, decimalDigits: decimalDigits)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt()}',
                            style: TextStyle(
                              color: context.appColors.mainText,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxAmount * 1.1) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            formatAmount(value, decimalDigits: decimalDigits),
                            style: TextStyle(
                              color: context.appColors.mainText,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (index) {
                  final month = index + 1;
                  return BarChartGroupData(
                    x: month,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyIncome[month] ?? 0,
                        color: context.appColors.increaseAmount,
                        width: 6,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: monthlyExpense[month] ?? 0,
                        color: context.appColors.decreaseAmount,
                        width: 6,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: context.appColors.mainText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatMonth(int month) {
    if (languageNotifier.value == 'en') {
      return DateFormat.MMM('en_US').format(DateTime(2024, month));
    }
    return '$month${AppStrings.monthLabel}';
  }

  List<Widget> _buildYearlyMonthlyList(List<MoneyEntry> yearlyEntries) {
    final Map<int, Map<String, CurrencySummary>> monthlyCurrencySums = {};
    final Map<int, List<MoneyEntry>> monthlyMemos = {};
    for (int i = 1; i <= 12; i++) {
      monthlyCurrencySums[i] = {};
      monthlyMemos[i] = [];
    }

    for (final e in yearlyEntries) {
      if (e.type == MoneyEntryTypes.memo) {
        monthlyMemos[e.date.month]!.add(e);
        continue;
      }

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

    final Set<int> activeMonths = {
      ...monthlyCurrencySums.keys.where((m) => monthlyCurrencySums[m]!.isNotEmpty),
      ...monthlyMemos.keys.where((m) => monthlyMemos[m]!.isNotEmpty),
    };

    final sortedActiveMonths = activeMonths.toList()..sort();

    return sortedActiveMonths.map((month) {
      final sums = monthlyCurrencySums[month]!;
      final memos = monthlyMemos[month]!;
      memos.sort((a, b) => a.date.compareTo(b.date)); // 古い日付順にソート
      final summaries = _sortSummaries(sums.values);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.inputBg,
          borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  _formatMonth(month),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: summaries
                      .map(
                        (s) => Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (s.increase > 0)
                              Text(
                                '+${s.symbol}${formatAmount(s.increase, decimalDigits: s.decimalDigits)}',
                                style: TextStyle(
                                  color: context.appColors.increaseAmount,
                                  fontSize: 13,
                                ),
                              ),
                            if (s.decrease > 0)
                              Text(
                                '-${s.symbol}${formatAmount(s.decrease, decimalDigits: s.decimalDigits)}',
                                style: TextStyle(
                                  color: context.appColors.decreaseAmount,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            if (memos.isNotEmpty) ...[
              const Divider(height: 16, thickness: 1),
              ...memos.map((memo) {
                final dateStr = languageNotifier.value == 'en' 
                    ? DateFormat.Md('en_US').format(memo.date)
                    : '${memo.date.month}/${memo.date.day}';
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('・', style: TextStyle(color: context.appColors.mainText)),
                      Expanded(
                        child: Text(
                          '$dateStr: ${memo.memo}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.mainText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }).toList();
  }

  String _getCurrencyCode(String symbol) {
    switch (symbol) {
      case 'ﾂ･':
        return 'JPY';
      case '\$':
        return 'USD';
      case '竄ｬ':
        return 'EUR';
      default:
        return symbol;
    }
  }

  Future<void> _shareRecord(
    String periodLabel,
    List<MoneyEntry> filtered,
    Map<String, CurrencySummary> totals,
  ) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.shareNoRecordError)));
      return;
    }

    final isEn = languageNotifier.value == 'en';
    final text = StringBuffer();

    // 繧ｿ繧､繝医Ν
    if (viewMode == PeriodViewMode.monthly) {
      if (isEn) {
        text.writeln(DateFormat.yMMMM('en_US').format(targetDate));
      } else {
        text.writeln(
          '${targetDate.year}${AppStrings.yearLabel}${targetDate.month}${AppStrings.monthLabel}${AppStrings.shareMessage}',
        );
      }
    } else {
      if (isEn) {
        text.writeln(targetDate.year.toString());
      } else {
        text.writeln(
          '${targetDate.year}${AppStrings.yearLabel}${AppStrings.shareMessage}',
        );
      }
    }
    text.writeln('');

    // 蜷郁ｨ医そ繧ｯ繧ｷ繝ｧ繝ｳ
    text.writeln(AppStrings.totalSectionTitle);

    final sortedSummaries = _sortSummaries(totals.values);
    for (final summary in sortedSummaries) {
      text.writeln(_getCurrencyCode(summary.symbol));
      final inc = formatAmount(
        summary.increase,
        decimalDigits: summary.decimalDigits,
      );
      final dec = formatAmount(
        summary.decrease,
        decimalDigits: summary.decimalDigits,
      );
      text.writeln('${AppStrings.shareIncreaseLabel}${summary.symbol}$inc');
      text.writeln('${AppStrings.shareDecreaseLabel}${summary.symbol}$dec');
      text.writeln('');
    }

    // 蜀・ｨｳ / 譛亥挨繧ｻ繧ｯ繧ｷ繝ｧ繝ｳ
    if (viewMode == PeriodViewMode.monthly) {
      text.writeln(AppStrings.detailSectionTitle);
      for (final e in filtered) {
        if (e.type == MoneyEntryTypes.memo) {
          text.writeln('${formatDate(e.date)} ${e.memo}');
          continue;
        }
        final sym = e.currency ?? 'ﾂ･';
        final digits = e.decimalDigits ?? 0;
        final amountText = formatAmount(e.amount, decimalDigits: digits);
        final signedAmount = e.type == MoneyEntryTypes.increase
            ? '+$sym$amountText'
            : '-$sym$amountText';
        text.writeln('${formatDate(e.date)} ${e.memo}  $signedAmount');
      }
    } else {
      text.writeln(AppStrings.monthlySummaryTitle);

      final Map<int, Map<String, CurrencySummary>> monthlyCurrencySums = {};
      final Map<int, List<MoneyEntry>> monthlyMemos = {};
      
      for (final e in filtered) {
        if (e.type == MoneyEntryTypes.memo) {
          monthlyMemos.putIfAbsent(e.date.month, () => []).add(e);
          continue;
        }

        final sym = e.currency ?? 'ﾂ･';
        final digits = e.decimalDigits ?? 0;
        final key = '$sym-$digits';
        monthlyCurrencySums.putIfAbsent(e.date.month, () => {});
        monthlyCurrencySums[e.date.month]!.putIfAbsent(
          key,
          () => CurrencySummary(sym, digits),
        );

        if (e.type == MoneyEntryTypes.increase) {
          monthlyCurrencySums[e.date.month]![key]!.increase += e.amount;
        } else if (e.type == MoneyEntryTypes.decrease) {
          monthlyCurrencySums[e.date.month]![key]!.decrease += e.amount;
        }
      }

      final Set<int> allMonths = {
        ...monthlyCurrencySums.keys,
        ...monthlyMemos.keys,
      };
      final sortedMonths = allMonths.toList()..sort();

      for (final m in sortedMonths) {
        final monthName = _formatMonth(m);
        bool hasValues = false;

        if (monthlyCurrencySums.containsKey(m)) {
          final summaries = _sortSummaries(monthlyCurrencySums[m]!.values);
          for (final s in summaries) {
            final inc = formatAmount(s.increase, decimalDigits: s.decimalDigits);
            final dec = formatAmount(s.decrease, decimalDigits: s.decimalDigits);

            if (s.increase > 0 && s.decrease > 0) {
              text.writeln('$monthName +${s.symbol}$inc / -${s.symbol}$dec');
              hasValues = true;
            } else if (s.increase > 0) {
              text.writeln('$monthName +${s.symbol}$inc');
              hasValues = true;
            } else if (s.decrease > 0) {
              text.writeln('$monthName -${s.symbol}$dec');
              hasValues = true;
            }
          }
        }

        if (monthlyMemos.containsKey(m)) {
          if (!hasValues) {
            text.writeln(monthName);
          }
          final sortedMemos = List<MoneyEntry>.from(monthlyMemos[m]!)
            ..sort((a, b) => a.date.compareTo(b.date)); // 古い日付順にソート
          for (final memo in sortedMemos) {
            final dateStr = isEn 
                ? DateFormat.Md('en_US').format(memo.date)
                : '${memo.date.month}/${memo.date.day}';
            text.writeln('  ・$dateStr: ${memo.memo}');
          }
        }
      }
    }

    // OS讓呎ｺ悶・蜈ｱ譛峨ム繧訂繧ｰ繧定｡ｨ遉ｺ
    // ignore: deprecated_member_use
    await Share.share(text.toString().trim());
  }
}
