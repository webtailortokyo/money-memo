// lib/pages/input_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Timerを使うためのimport

import '../models/money_type.dart';
import '../models/money_entry.dart';
import '../theme.dart';
import '../constants.dart';
import '../utils/input_formatter.dart';
import '../utils/format_utils.dart';
import '../widgets/piggy_character.dart';
import '../utils/milestone_manager.dart';
import '../app_state.dart';

class InputPage extends StatefulWidget {
  final MoneyEntry? entry; // nullなら新規、あれば編集

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
      
      // 保存時の通貨設定を使って初期値をフォーマット
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

      // ユーザーの要望により、入力済みのメモは消さないようにする
      if (isEdit) return;

      // memoController.clear();
    });
  }


  void _delete() {
    widget.entry!.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.deleteSuccessMessage)),
    );

    Navigator.pop(context);
  }

  Future<void> _save() async {
    final memo = memoController.text.trim();
    final amountText = amountController.text.trim();

    // カンマをすべて削除
    final cleanedAmount = amountText.replaceAll(',', '');

    // メモのみの場合は金額不要
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
      // 編集時は元の通貨情報を維持、新規は現在のグローバルを使用
      currency: isEdit ? (widget.entry!.currency ?? currencyNotifier.value) : currencyNotifier.value,
      decimalDigits: isEdit ? (widget.entry!.decimalDigits ?? decimalDigitsNotifier.value) : decimalDigitsNotifier.value,
    );

    if (isEdit) {
      box.put(widget.entry!.key, newEntry);
    } else {
      box.add(newEntry);
    }

    // フィードバック再生（エラーがあっても画面は閉じるようにtry-finallyまたはcatchで保護）
    try {
      await _playFeedback(selectedType);
      
      // 新規記録の場合のみマイルストーン判定を行う
      if (context.mounted && !isEdit) {
        await MilestoneManager.checkAndShow(context);
      }
    } catch (e) {
      log('Feedback error: $e');
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _playFeedback(MoneyType type) async {
    // タイプごとの設定
    String soundFile;
    String lottieFile;
    int vibrationDuration;

    switch (type) {
      case MoneyType.increase:
        soundFile = 'sounds/increase.mp3';
        lottieFile = 'assets/lottie/increase.json';
        vibrationDuration = 1000;
        break;
      case MoneyType.decrease:
        soundFile = 'sounds/decrease.mp3';
        lottieFile = 'assets/lottie/decrease.json';
        vibrationDuration = 500;
        break;
      case MoneyType.memo:
        // メモ用：一旦増えた時と同じ音などを使うか、控えめなものにする
        // ここでは増えた時と同じ画像（貯金箱ではない方）などを流用
        soundFile = 'sounds/increase.mp3';
        lottieFile = 'assets/lottie/increase.json';
        vibrationDuration = 200;
        break;
    }

    // 1. 振動と音を並列再生（待たなくてよいが、音は再生開始を確認したいのでawaitしても良い）
    Vibration.vibrate(duration: vibrationDuration);

    final soundFuture = AudioPlayer().play(AssetSource(soundFile));

    // エラーハンドリングのためFuture.waitで囲むが、失敗しても次へ進む
    await Future.wait([
      soundFuture.catchError((_) {})
    ]);

    // 2. アニメーションダイアログ表示
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // 画面幅の80%と300pxの小さい方を採用（はみ出し防止）
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final size = (screenWidth * 0.8 < 300) ? screenWidth * 0.8 : 300.0;

        final lottieWidget = Lottie.asset(
          lottieFile,
          width: type == MoneyType.increase ? size * 1.5 : size,
          height: type == MoneyType.increase ? size * 1.5 : size,
          repeat: false,
          onLoaded: (composition) {
            // アニメーション時間の1.5倍待ってからダイアログを閉じる（長く見せるため）
            Future.delayed(composition.duration * 1.2, () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          },
          // 読み込みエラー時のフォールバック（画面がロックされないように）
          errorBuilder: (context, error, stackTrace) {
            Future.delayed(Duration.zero, () {
               if (context.mounted) Navigator.of(context).pop();
            });
            return const SizedBox();
          },
        );

        final imageWidget = TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: screenHeight, end: 0),
          // 登場のアニメーション自体も 600ms -> 720ms に1.2倍ゆっくりにする
          duration: const Duration(milliseconds: 720),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: type == MoneyType.increase
              ? Padding(
                  padding: const EdgeInsets.only(top: 150),
                  child: SvgPicture.asset(
                    'assets/img/piggy_bank.svg',
                    width: size * 0.7,
                  ),
                )
              : PiggyCharacter(
                  width: size * 0.7,
                  pose: PiggyPose.joy,
                  eyes: PiggyEyes.smile,
                  isBlinking: true,
                ),
        );

        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: type == MoneyType.increase
                ? Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      lottieWidget,
                      imageWidget,
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      lottieWidget,
                      imageWidget,
                    ],
                  ),
          ),
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

  Widget _typeButtonInner(String label, MoneyType type, Color color) {
    final selected = selectedType == type;

    IconData iconData;
    Color iconColor;
    switch (type) {
      case MoneyType.increase:
        iconData = Icons.arrow_upward;
        iconColor = AppColors.increaseAmount;
        break;
      case MoneyType.decrease:
        iconData = Icons.arrow_downward;
        iconColor = AppColors.decreaseAmount;
        break;
      case MoneyType.memo:
        iconData = Icons.edit_note;
        iconColor = AppColors.memo;
        break;
    }

    return InkWell(
      onTap: () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(AppNumbers.typeButtonBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppNumbers.mediumSpacing, horizontal: AppNumbers.smallSpacing),
        decoration: BoxDecoration(
          color: type == MoneyType.decrease
              ? AppColors.decreaseBg
              : type == MoneyType.increase
                  ? AppColors.increaseBg
                  : type == MoneyType.memo
                      ? AppColors.memoBg
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
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1, // ボタンの中で改行されないようにする
              overflow: TextOverflow.visible, // はみ出してもボタン自体を広げる
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.mainText,
                fontSize: 12, // アイコンが入るため少し小さめに調整
              ),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final dateText = formatDate(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: AppNumbers.appBarElevation,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 40,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.accent, size: 28),

            const SizedBox(width: 8),
            Text(
              isEdit ? AppStrings.editRecordTitle : AppStrings.newRecordTitle,
              style: const TextStyle(
                fontSize: AppNumbers.subPageTitleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        leading: IconButton(

          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.accent),
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
                    color: Colors.white, // 背景色を白に
                    borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today, 
                        size: AppNumbers.calendarIconSize,
                      ),
                      const SizedBox(width: AppNumbers.smallSpacing),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: AppNumbers.calendarFontSize,
                          // fontWeight: FontWeight.bold,
                          color: AppColors.mainText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppNumbers.smallSpacing),
              Text(AppStrings.typeSelectionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),

              const SizedBox(height: AppNumbers.defaultPadding),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 300;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: _typeButtonInner(AppStrings.increaseTypeLabel, MoneyType.increase, AppColors.increase)),
                        const SizedBox(width: AppNumbers.smallSpacing),
                        Expanded(child: _typeButtonInner(AppStrings.decreaseTypeLabel, MoneyType.decrease, AppColors.decrease)),
                        const SizedBox(width: AppNumbers.smallSpacing),
                        Expanded(child: _typeButtonInner(AppStrings.memoTypeLabel, MoneyType.memo, AppColors.memo)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _typeButtonInner(AppStrings.increaseTypeLabel, MoneyType.increase, AppColors.increase)),
                            const SizedBox(width: AppNumbers.smallSpacing),
                            Expanded(child: _typeButtonInner(AppStrings.decreaseTypeLabel, MoneyType.decrease, AppColors.decrease)),
                          ],
                        ),
                        const SizedBox(height: AppNumbers.smallSpacing),
                        SizedBox(
                          width: double.infinity,
                          child: _typeButtonInner(AppStrings.memoTypeLabel, MoneyType.memo, AppColors.memo),
                        ),
                      ],
                    );
                  }
                },
              ),



              const SizedBox(height: AppNumbers.smallSpacing),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                  border: Border.all(
                    color: memoFocusNode.hasFocus ? AppColors.accent : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: memoFocusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
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

              const SizedBox(height: AppNumbers.defaultPadding),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selectedType == MoneyType.memo ? Colors.grey.shade200 : Colors.white,
                  borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                  border: Border.all(
                    color: amountFocusNode.hasFocus ? AppColors.accent : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: amountFocusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
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
                              color: selectedType == MoneyType.memo ? Colors.grey : AppColors.mainText,
                            ),
                          );
                        },
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        // OutlinedButtonの文字色をメインの黒に
                        foregroundColor: AppColors.mainText, 
                        side: const BorderSide(color: Colors.grey), // 枠線の色も変えたい場合はここ
                        minimumSize: const Size(0, 50),
                      ),
                      child: Text(AppStrings.cancelButtonText),
                    ),
                  ),
                  const SizedBox(width: AppNumbers.mediumSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(0, 50),
                      ),
                      icon: const Icon(Icons.check_circle),
                      label: Text(isEdit ? AppStrings.updateButtonText : AppStrings.recordButtonText),
                    ),
                  ),

                ],
              ),

              if (isEdit) ...[
                const SizedBox(height: AppNumbers.mediumSpacing),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      AppStrings.deleteButtonTextInput,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onPressed: _delete,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


