// lib/pages/input_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/feedback_animation.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Timer繧剃ｽｿ縺・◆繧√・import

import '../models/money_type.dart';
import '../models/money_entry.dart';
import '../theme.dart';
import '../constants.dart';
import '../utils/input_formatter.dart';
import '../utils/format_utils.dart';
import '../utils/milestone_manager.dart';
import '../utils/notification_manager.dart';
import '../app_state.dart';

class InputPage extends StatefulWidget {
  final MoneyEntry? entry; // null縺ｪ繧画眠隕上€√≠繧後・邱ｨ髮・

  const InputPage({
    super.key,
    this.entry,
  });

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  MoneyType selectedType = MoneyType.decrease;
  DateTime selectedDate = DateTime.now();

  final amountController = TextEditingController();
  final memoController = TextEditingController();
  final amountFocusNode = FocusNode();
  final memoFocusNode = FocusNode();

  bool get isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();

    amountFocusNode.addListener(() => setState(() {}));
    memoFocusNode.addListener(() => setState(() {}));

    if (isEdit) {
      final entry = widget.entry!;
      memoController.text = entry.memo;
      
      // 菫晏ｭ俶凾縺ｮ騾夊ｲｨ險ｭ螳壹ｒ菴ｿ縺｣縺ｦ蛻晄悄蛟､繧偵ヵ繧ｩ繝ｼ繝槭ャ繝・
      final digits = entry.decimalDigits ?? decimalDigitsNotifier.value;
      final formatter = NumberFormat.currency(symbol: '', decimalDigits: digits);
      amountController.text = formatter.format(entry.amount);

      selectedType = MoneyType.values.firstWhere(
        (e) => e.name == entry.type,
      );
      selectedDate = entry.date;
    }
  }

  @override
  void dispose() {
    amountFocusNode.dispose();
    memoFocusNode.dispose();
    amountController.dispose();
    memoController.dispose();
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

      // 繝ｦ繝ｼ繧ｶ繝ｼ縺ｮ隕∵悍縺ｫ繧医により縲∝・蜉帶ｸ済みの繝｡繝｢縺ｯ豸医＆縺ｪ縺・ｈ縺・↓縺吶ｋ
      if (isEdit) return;

      // memoController.clear();
    });
  }


  void _delete() {
    widget.entry!.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.deleteSuccessMessage)),
    );

    // 通知のスケジュールを更新
    NotificationManager.scheduleInactivityNotifications();

    Navigator.pop(context);
  }

  Future<void> _save() async {
    // キーボードを完全に閉じる
    FocusManager.instance.primaryFocus?.unfocus();

    final memo = memoController.text.trim();
    final amountText = amountController.text.trim();

    // カンマをすべて削除
    final cleanedAmount = amountText.replaceAll(',', '');

    // 繝｡繝｢縺ｮ縺ｿ縺ｮ蝣ｴ蜷医・驥鷹｡堺ｸ崎ｦ・
    if (memo.isEmpty || (selectedType != MoneyType.memo && amountText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.inputErrorSnackbarMessage)),
      );
      return;
    }

    final amount = selectedType == MoneyType.memo ? 0.0 : double.tryParse(cleanedAmount);
    if (amount == null) return;

    final box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);

    final newEntry = MoneyEntry(
      amount: amount,
      memo: memo,
      type: selectedType.name,
      date: selectedDate,
      // 邱ｨ髮・凾縺ｯ蜈・・騾夊ｲｨ諠・ｱ繧堤ｶｭ謖√€∵眠隕上・迴ｾ蝨ｨ縺ｮ繧ｰ繝ｭ繝ｼ繝舌Ν繧剃ｽｿ逕ｨ
      currency: isEdit ? (widget.entry!.currency ?? currencyNotifier.value) : currencyNotifier.value,
      decimalDigits: isEdit ? (widget.entry!.decimalDigits ?? decimalDigitsNotifier.value) : decimalDigitsNotifier.value,
    );

    if (isEdit) {
      box.put(widget.entry!.key, newEntry);
    } else {
      box.add(newEntry);
    }

    // 繝輔ぅ繝ｼ繝峨ヰ繝・け蜀咲函・医お繝ｩ繝ｼ縺後≠縺｣縺ｦ繧ら判髱｢縺ｯ髢峨§繧九ｈ縺・↓try-finally縺ｾ縺溘・catch縺ｧ菫晁ｭ貴・・
    try {
      await _playFeedback(selectedType);
      
      // 譁ｰ隕剰ｨ倬鹸縺ｮ蝣ｴ蜷医・縺ｿ繝槭う繝ｫ繧ｹ繝医・繝ｳ蛻､螳壹ｒ陦後≧
      if (mounted && !isEdit) {
        await MilestoneManager.checkAndShow(context);
      }
    } catch (e) {
      log('Feedback error: $e');
    }

    // 通知のスケジュールを更新
    await NotificationManager.scheduleInactivityNotifications();

    if (mounted) {
      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, child) {
        final dateText = formatDate(selectedDate);
    
        return SelectionArea(
          child: Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            elevation: AppNumbers.appBarElevation,
            centerTitle: false,
            titleSpacing: 0,
            leadingWidth: 40,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: context.appColors.accent, size: 28),
    
                SizedBox(width: 8),
                Text(
                  isEdit ? AppStrings.editRecordTitle : AppStrings.newRecordTitle,
                  style: TextStyle(
                    fontSize: AppNumbers.subPageTitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.accent,
                  ),
                ),
              ],
            ),
            leading: IconButton(
    
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.arrow_back_ios, color: context.appColors.accent),
              onPressed: () => Navigator.pop(context),
            ),
    
          ),
          body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding + AppNumbers.smallSpacing, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              dateText,
                              style: TextStyle(
                                fontSize: AppNumbers.calendarFontSize,
                                // fontWeight: FontWeight.bold,
                                color: context.appColors.mainText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
      
                    SizedBox(height: AppNumbers.smallSpacing),
                    Text(AppStrings.typeSelectionTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),
      
                    SizedBox(height: AppNumbers.defaultPadding),
      
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
                        decoration: InputDecoration(
                          hintText: memoHint,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
      
                    SizedBox(height: AppNumbers.defaultPadding),
      
                    AnimatedContainer(
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
                      child: TextField(
                        focusNode: amountFocusNode,
                        controller: amountController,
                        enabled: selectedType != MoneyType.memo,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          ThousandsSeparatorInputFormatter(
                            initialDecimalDigits: isEdit ? widget.entry!.decimalDigits : null,
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppNumbers.defaultPadding,
                            vertical: AppNumbers.defaultPadding,
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ValueListenableBuilder<String>(
                              valueListenable: currencyNotifier,
                              builder: (context, symbol, child) {
                                final displaySymbol = isEdit ? (widget.entry!.currency ?? symbol) : symbol;
                                return Text(
                                  displaySymbol,
                                  style: TextStyle(
                                    color: selectedType == MoneyType.memo ? Colors.grey : context.appColors.mainText,
                                  ),
                                );
                              },
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
      
                    SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),
      
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              // OutlinedButtonの文字色をメインの黒に
                              foregroundColor: context.appColors.mainText, 
                              side: const BorderSide(color: Colors.grey), // 枠線の色も変えたい場合はここ
                              minimumSize: const Size(0, 50),
                            ),
                            child: Text(AppStrings.cancelButtonText),
                          ),
                        ),
                        SizedBox(width: AppNumbers.mediumSpacing),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: context.appColors.accent,
                              minimumSize: const Size(0, 50),
                            ),
                            icon: Icon(Icons.check_circle),
                            label: Text(isEdit ? AppStrings.updateButtonText : AppStrings.recordButtonText),
                          ),
                        ),
      
                      ],
                    ),
      
                    if (isEdit) ...[
                      SizedBox(height: AppNumbers.mediumSpacing),
                      Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            AppStrings.deleteButtonTextInput,
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: _delete,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
