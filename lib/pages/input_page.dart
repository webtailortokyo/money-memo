// lib/pages/input_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async'; // Timerを使うためのimport

import '../models/money_type.dart';
import '../models/money_entry.dart';
import '../theme.dart';
import '../constants.dart';
import '../utils/input_formatter.dart';
import '../widgets/piggy_character.dart';

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

  bool get isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final entry = widget.entry!;
      memoController.text = entry.memo;
      amountController.text = entry.amount.toString();
      selectedType = MoneyType.values.firstWhere(
        (e) => e.name == entry.type,
      );
      selectedDate = entry.date;
    }
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
      const SnackBar(content: Text(AppStrings.deleteSuccessMessage)),
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
        const SnackBar(content: Text(AppStrings.inputErrorSnackbarMessage)),
      );
      return;
    }

    final amount = selectedType == MoneyType.memo ? 0 : int.tryParse(cleanedAmount);
    if (amount == null) return;

    final box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);

    final newEntry = MoneyEntry(
      amount: amount,
      memo: memo,
      type: selectedType.name,
      date: selectedDate,
    );

    if (isEdit) {
      box.put(widget.entry!.key, newEntry);
    } else {
      box.add(newEntry);
    }

    // フィードバック再生（エラーがあっても画面は閉じるようにtry-finallyまたはcatchで保護）
    try {
      await _playFeedback(selectedType);
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

        // タイプごとに画像を出し分け
        final imageFile = type == MoneyType.increase
            ? 'assets/img/piggy_bank.png'
            : type == MoneyType.decrease
                ? 'assets/img/joy_pose.png'
                : 'assets/img/joy_pose.png'; // memoもとりあえずjoy

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
              : StatefulBuilder(
                  builder: (context, setDialogState) {
                    // 減った時の特別アニメーションロジック
                    return _ShockAnimationWrapper(
                      width: size * 0.7,
                    );
                  },
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

  Widget _typeButton(String label, MoneyType type, Color color) {
    return Expanded(
      child: _typeButtonInner(label, type, color),
    );
  }

  Widget _typeButtonWrapper(BuildContext context, String label, MoneyType type, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (AppNumbers.defaultPadding + AppNumbers.smallSpacing) * 2;
    final totalSpacing = AppNumbers.smallSpacing * 2;
    final buttonWidth = (screenWidth - horizontalPadding - totalSpacing) / 3.05;

    return Container(
      constraints: BoxConstraints(minWidth: buttonWidth),
      child: _typeButtonInner(label, type, color),
    );
  }

  Widget _typeButtonInner(String label, MoneyType type, Color color) {
    final selected = selectedType == type;

    return InkWell(
      onTap: () => _onTypeChanged(type),
      borderRadius: BorderRadius.circular(AppNumbers.typeButtonBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppNumbers.mediumSpacing, horizontal: AppNumbers.defaultPadding),
        decoration: BoxDecoration(
          color: selected
              ? color
              : type == MoneyType.decrease
                  ? AppColors.decreaseBg
                  : type == MoneyType.increase
                      ? AppColors.increaseBg
                      : type == MoneyType.memo
                          ? AppColors.memoBg
                          : Colors.transparent,
          borderRadius: BorderRadius.circular(AppNumbers.typeButtonBorderRadius),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1, // ボタンの中で改行されないようにする
            overflow: TextOverflow.visible, // はみ出してもボタン自体を広げる
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.mainText,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: AppNumbers.appBarElevation,
        title: Text(
          isEdit ? AppStrings.editRecordTitle : AppStrings.newRecordTitle,
          style: const TextStyle(
            fontSize: AppNumbers.subPageTitleFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        leading: IconButton(
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
                    borderRadius: BorderRadius.circular(AppNumbers.cardBorderRadius),
                    // border: Border.all(color: Colors.grey.shade300), // 必要なら薄い枠線
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
              const Text(AppStrings.typeSelectionTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),

              const SizedBox(height: AppNumbers.defaultPadding),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 400;

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



              const SizedBox(height: AppNumbers.defaultPadding + AppNumbers.smallSpacing),

              Text(memoLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),
              const SizedBox(height: AppNumbers.smallSpacing + 0),
              TextField(
                controller: memoController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: memoHint,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: AppNumbers.defaultPadding),

              const Text(AppStrings.amountLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppNumbers.sectionTitleFontSize)),
              const SizedBox(height: AppNumbers.smallSpacing + 0),
              TextField(
                controller: amountController,
                enabled: selectedType != MoneyType.memo,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                style: const TextStyle(
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppNumbers.defaultPadding,
                    horizontal: 0,
                  ),
                  filled: true,
                  fillColor: selectedType == MoneyType.memo ? Colors.grey.shade200 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppNumbers.defaultPadding),
                    borderSide: BorderSide.none,
                  ),
                  // 1. prefix ではなく prefixIcon に変更（これで常に表示される）
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    // 2. 数字（TextFieldの文字）の底辺に合わせるための設定
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const SizedBox(width: AppNumbers.defaultPadding), // 左端の余白調整用
                      Text(
                        '¥ ',
                        style: TextStyle(
                          color: selectedType == MoneyType.memo ? Colors.grey : AppColors.mainText,
                          // 3. ここが重要：Rowの中でもTextFieldの文字と揃うように高さを微調整
                          height: 1.2, 
                        ),
                      ),
                    ],
                  ),
                  // 4. prefixIconの余計な余白を消して、文字に近づける
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  
                  hintText: '0', // AppStrings.amountHint は '0' に戻してOK
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
                      child: const Text(AppStrings.cancelButtonText),
                    ),
                  ),
                  const SizedBox(width: AppNumbers.mediumSpacing),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(0, 50),
                      ),
                      child: Text(isEdit ? AppStrings.updateButtonText : AppStrings.recordButtonText),
                    ),
                  ),
                ],
              ),

              if (isEdit) ...[
                const SizedBox(height: AppNumbers.mediumSpacing),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
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
    );
  }
}

class _ShockAnimationWrapper extends StatefulWidget {
  final double width;
  const _ShockAnimationWrapper({required this.width});

  @override
  State<_ShockAnimationWrapper> createState() => _ShockAnimationWrapperState();
}

class _ShockAnimationWrapperState extends State<_ShockAnimationWrapper> {
  PiggyEyes _eyes = PiggyEyes.smile;
  PiggyMouth _mouth = PiggyMouth.normal;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnim();
  }

  void _startAnim() async {
    // 1回目瞬き
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _eyes = PiggyEyes.dot);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _eyes = PiggyEyes.smile);

    // 2回目瞬き
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _eyes = PiggyEyes.dot);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _eyes = PiggyEyes.smile);

    // ショック顔
    _timer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _eyes = PiggyEyes.shocked;
          _mouth = PiggyMouth.shocked;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PiggyCharacter(
      width: widget.width,
      pose: PiggyPose.joy,
      eyes: _eyes,
      mouth: _mouth,
    );
  }
}

