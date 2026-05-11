import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/feedback_animation.dart';

import 'period_page.dart';
import 'input_page.dart';
import 'settings_page.dart';
import '../app_state.dart';
import '../theme.dart';
import '../models/money_entry.dart';
import '../models/money_type.dart';
import '../widgets/money_entry_card.dart';
import '../widgets/proverb_bubble.dart';
import '../utils/sort_entries.dart';
import '../utils/input_formatter.dart';
import '../constants.dart';
import '../utils/milestone_manager.dart';
import '../utils/format_utils.dart';
import '../utils/notification_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Box<MoneyEntry> box;

  // 入力エリアの状態管理
  MoneyType selectedType = MoneyType.decrease;
  DateTime selectedDate = DateTime.now();
  final amountController = TextEditingController();
  final memoController = TextEditingController();
  final amountFocusNode = FocusNode();
  final memoFocusNode = FocusNode();

  // 無限スクロール用の管理
  final ScrollController _scrollController = ScrollController();
  int _displayCount = 20;
  static const int _increment = 20;

  @override
  void initState() {
    super.initState();
    box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
    amountFocusNode.addListener(() => setState(() {}));
    memoFocusNode.addListener(() => setState(() {}));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // 下端から200px以内に到達したら読み込み
      if (_displayCount < box.length) {
        setState(() {
          _displayCount += _increment;
        });
      }
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(AppNumbers.minInputDatePickerYear),
      lastDate: DateTime(AppNumbers.maxDatePickerYear),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _onTypeChanged(MoneyType type) {
    setState(() {
      selectedType = type;
      // 繝ｦ繝ｼ繧ｶ繝ｼ縺ｮ隕∵悍縺ｫ繧医ｊ縲∝・蜉帶ｸ医∩縺ｮ繝｡繝｢縺ｯ豸医＆縺ｪ縺・ｈ縺・↓縺吶ｋ
      // memoController.clear(); 
    });
  }

  Future<void> _save() async {
    // キーボードを完全に閉じる
    FocusManager.instance.primaryFocus?.unfocus();

    final memo = memoController.text.trim();
    final amountText = amountController.text.trim();
    final cleanedAmount = amountText.replaceAll(',', '');

    if (memo.isEmpty || (selectedType != MoneyType.memo && amountText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.inputErrorSnackbarMessage)),
      );
      return;
    }

    final amount = selectedType == MoneyType.memo ? 0.0 : double.tryParse(cleanedAmount);
    if (amount == null) return;

    final newEntry = MoneyEntry(
      amount: amount,
      memo: memo,
      type: selectedType.name,
      date: selectedDate,
      currency: currencyNotifier.value,
      decimalDigits: decimalDigitsNotifier.value,
    );

    box.add(newEntry);

    final feedbackType = selectedType == MoneyType.memo ? MoneyType.memo : (newEntry.type == MoneyType.increase.name ? MoneyType.increase : MoneyType.decrease);
    
    // 蜈･蜉帙お繝ｪ繧｢繧偵Μ繧ｻ繝・ヨ
    memoController.clear();
    amountController.clear();
    setState(() {
      selectedType = MoneyType.decrease;
      selectedDate = DateTime.now();
    });

    try {
      // 蜈医↓繝槭う繝ｫ繧ｹ繝医・繝ｳ蛻､螳壹ｒ陦後≧
      bool milestoneShown = false;
      if (context.mounted) {
        milestoneShown = await MilestoneManager.checkAndShow(context);
      }

      // 繝槭う繝ｫ繧ｹ繝医・繝ｳ縺瑚｡ｨ遉ｺ縺輔ｌ縺ｪ縺九▲縺溷ｴ蜷医・縺ｿ縲・壼ｸｸ縺ｮ繝輔ぅ繝ｼ繝峨ヰ繝・け繧貞・逕・
      if (!milestoneShown) {
        await _playFeedback(feedbackType);
      }
    } catch (e) {
      log('Feedback error: $e');
    }
  }

  Future<void> _playFeedback(MoneyType type) async {
    String soundFile;
    int vibrationDuration;

    switch (type) {
      case MoneyType.increase:
        soundFile = 'sounds/increase.mp3';
        vibrationDuration = 1000;
        break;
      case MoneyType.decrease:
        soundFile = 'sounds/decrease.mp3';
        vibrationDuration = 500;
        break;
      case MoneyType.memo:
        soundFile = 'sounds/pen_writing.mp3';
        vibrationDuration = 200;
        break;
    }

    Vibration.vibrate(duration: vibrationDuration);
    final soundFuture = AudioPlayer().play(AssetSource(soundFile));
    await Future.wait([soundFuture.catchError((_) {})]);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final size = (screenWidth * 0.8 < 300) ? screenWidth * 0.8 : 300.0;

        return FeedbackAnimation(
          type: type,
          size: size,
          onComplete: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }

  String get memoLabel {
    switch (selectedType) {
      case MoneyType.decrease:
        return AppStrings.memoLabelDecrease;
      case MoneyType.increase:
        return AppStrings.memoLabelIncrease;
      case MoneyType.memo:
        return AppStrings.memoLabelMemo;
    }
  }

  String get memoHint {
    switch (selectedType) {
      case MoneyType.decrease:
        return AppStrings.memoHintDecrease;
      case MoneyType.increase:
        return AppStrings.memoHintIncrease;
      case MoneyType.memo:
        return AppStrings.memoHintMemo;
    }
  }

  Color get _activeBorderColor {
    switch (selectedType) {
      case MoneyType.increase:
        return context.appColors.increaseAmount;
      case MoneyType.decrease:
        return context.appColors.decreaseAmount;
      case MoneyType.memo:
        return context.appColors.memo;
    }
  }

  Widget _typeButtonInner(String label, MoneyType type, Color color) {
    final selected = selectedType == type;

    IconData iconData;
    Color iconColor;
    switch (type) {
      case MoneyType.increase:
        iconData = Icons.arrow_upward;
        iconColor = context.appColors.increaseAmount;
        break;
      case MoneyType.decrease:
        iconData = Icons.arrow_downward;
        iconColor = context.appColors.decreaseAmount;
        break;
      case MoneyType.memo:
        iconData = Icons.edit_note;
        iconColor = context.appColors.memo;
        break;
    }

    return InkWell(
      onTap: () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(AppNumbers.typeButtonBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppNumbers.mediumSpacing, horizontal: AppNumbers.smallSpacing),
        decoration: BoxDecoration(
          color: type == MoneyType.decrease
              ? context.appColors.decreaseBg
              : type == MoneyType.increase
                  ? context.appColors.increaseBg
                  : type == MoneyType.memo
                      ? context.appColors.memoBg
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(AppNumbers.typeButtonBorderRadius),
          border: selected
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              maxLines: 1, // 繝懊ち繝ｳ縺ｮ荳ｭ縺ｧ謾ｹ陦後＆繧後↑縺・ｈ縺・↓縺吶ｋ
              overflow: TextOverflow.visible, // 縺ｯ縺ｿ蜃ｺ縺励※繧ゅ・繧ｿ繝ｳ閾ｪ菴薙ｒ蠎・￡繧・
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.appColors.mainText,
                fontSize: 12, // 繧｢繧､繧ｳ繝ｳ縺悟・繧九◆繧∝ｰ代＠蟆上＆繧√↓隱ｿ謨ｴ
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _amountTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selectedType == MoneyType.memo 
            ? context.appColors.memoBg 
            : context.appColors.inputBg,
        borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
        border: Border.all(
          color: amountFocusNode.hasFocus ? _activeBorderColor : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: amountFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: _activeBorderColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 0,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppNumbers.defaultPadding,
              right: 4,
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: currencyNotifier,
              builder: (context, symbol, child) => Text(
                symbol,
                style: TextStyle(
                  color: selectedType == MoneyType.memo ? Colors.grey : context.appColors.mainText,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              focusNode: amountFocusNode,
              controller: amountController,
              enabled: selectedType != MoneyType.memo,
              keyboardType: TextInputType.number,
              cursorColor: _activeBorderColor,
              inputFormatters: [
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: AppNumbers.defaultPadding,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordButton() {
    return ElevatedButton.icon(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.appColors.accent,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.only(left: 28, right: 44, top: 22, bottom: 22),
      ),

      icon: Icon(Icons.check_circle),
      label: Text(
        AppStrings.recordButtonText,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
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
            title: ValueListenableBuilder2<String, String>(
              valueListenable1: appTitleNotifier,
              valueListenable2: currencyNotifier,
              builder: (context, title, symbol, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/app_icon.svg',
                      width: 28,
                      height: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: context.appColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: AppNumbers.titleFontSize,
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.bar_chart, color: context.appColors.accent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeriodPage()),
                  );
                },
                tooltip: AppStrings.periodPageTitle,
              ),
              IconButton(
                icon: Icon(Icons.settings, color: context.appColors.accent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                tooltip: AppStrings.settingsTitle,
              ),
              SizedBox(width: 8),
            ],
          ),

    
          body: SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 蜈･蜉帙お繝ｪ繧Area
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppNumbers.defaultPadding + AppNumbers.smallSpacing,
                        vertical: AppNumbers.smallSpacing,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ProverbBubble(),
                          const SizedBox(height: AppNumbers.smallSpacing),
                          InkWell(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppNumbers.smallSpacing,
                                horizontal: AppNumbers.defaultPadding,
                              ),
                              decoration: BoxDecoration(
                                color: context.appColors.inputBg,
                                borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: AppNumbers.calendarIconSize,
                                  ),
                                  SizedBox(width: AppNumbers.smallSpacing),
                                  Text(
                                    formatDate(selectedDate),
                                    style: TextStyle(
                                      fontSize: AppNumbers.calendarFontSize,
                                      color: context.appColors.mainText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
      
                          SizedBox(height: AppNumbers.smallSpacing),
      
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 300;
      
                              if (isWide) {
                                return Row(
                                  children: [
                                    Expanded(child: _typeButtonInner(AppStrings.increaseTypeLabel, MoneyType.increase, context.appColors.increase)),
                                    SizedBox(width: AppNumbers.smallSpacing),
                                    Expanded(child: _typeButtonInner(AppStrings.decreaseTypeLabel, MoneyType.decrease, context.appColors.decrease)),
                                    SizedBox(width: AppNumbers.smallSpacing),
                                    Expanded(child: _typeButtonInner(AppStrings.memoTypeLabel, MoneyType.memo, context.appColors.memo)),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _typeButtonInner(AppStrings.increaseTypeLabel, MoneyType.increase, context.appColors.increase)),
                                        SizedBox(width: AppNumbers.smallSpacing),
                                        Expanded(child: _typeButtonInner(AppStrings.decreaseTypeLabel, MoneyType.decrease, context.appColors.decrease)),
                                      ],
                                    ),
                                    SizedBox(height: AppNumbers.smallSpacing),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _typeButtonInner(AppStrings.memoTypeLabel, MoneyType.memo, context.appColors.memo),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
      
                          SizedBox(height: AppNumbers.smallSpacing),
      
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: context.appColors.inputBg,
                              borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                              border: Border.all(
                                color: memoFocusNode.hasFocus ? _activeBorderColor : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              boxShadow: memoFocusNode.hasFocus
                                  ? [
                                      BoxShadow(
                                        color: _activeBorderColor.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        spreadRadius: 0,
                                      )
                                    ]
                                  : [],
                            ),
                            child: TextField(
                              focusNode: memoFocusNode,
                              controller: memoController,
                              maxLines: null,
                              cursorColor: _activeBorderColor,
                              decoration: InputDecoration(
                                hintText: memoHint,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
      
                          SizedBox(height: AppNumbers.smallSpacing),
      
                          Column(
                            children: [
                              _amountTextField(),
                              SizedBox(height: AppNumbers.smallSpacing),
                              Align(
                                alignment: Alignment.center,
                                child: _recordButton(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
      
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
      
                  // 險倬鹸繝ｪ繧ｹ繝・
                  ValueListenableBuilder(
                    valueListenable: box.listenable(),
                    builder: (context, Box<MoneyEntry> box, _) {
                      if (box.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(AppStrings.noRecordMessage),
                          ),
                        );
                      }
      
                      final allEntries = sortedEntries(box);
                      final entries = allEntries.take(_displayCount).toList();
      
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: AppNumbers.listViewHorizontalPadding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = entries[index];
                              return MoneyEntryCard(
                                entry: entry,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InputPage(entry: entry),
                                    ),
                                  );
                                },
                                onLongPress: () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => SelectionArea(
                                      child: AlertDialog(
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
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
      
                                  if (result == true) {
                                    box.delete(entry.key);
                                  }
                                },
                              );
                            },
                            childCount: entries.length,
                          ),
                        ),
                      );
                    },
                  ),
                  // 下部の余白と読み込みインジケータ
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder(
                      valueListenable: box.listenable(),
                      builder: (context, Box<MoneyEntry> box, _) {
                        if (_displayCount < box.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.appColors.accent.withValues(alpha: 0.5)
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 80.0); // FABと重ならないように余白を多めに確保
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
