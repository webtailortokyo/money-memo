// lib/pages/input_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Timer繧剃ｽｿ縺・◆繧√・import

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
  final MoneyEntry? entry; // null縺ｪ繧画眠隕上√≠繧後・邱ｨ髮・

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

      // 繝ｦ繝ｼ繧ｶ繝ｼ縺ｮ隕∵悍縺ｫ繧医ｊ縲∝・蜉帶ｸ医∩縺ｮ繝｡繝｢縺ｯ豸医＆縺ｪ縺・ｈ縺・↓縺吶ｋ
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

    // 繧ｫ繝ｳ繝槭ｒ縺吶∋縺ｦ蜑企勁
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
      // 邱ｨ髮・凾縺ｯ蜈・・騾夊ｲｨ諠・ｱ繧堤ｶｭ謖√∵眠隕上・迴ｾ蝨ｨ縺ｮ繧ｰ繝ｭ繝ｼ繝舌Ν繧剃ｽｿ逕ｨ
      currency: isEdit ? (widget.entry!.currency ?? currencyNotifier.value) : currencyNotifier.value,
      decimalDigits: isEdit ? (widget.entry!.decimalDigits ?? decimalDigitsNotifier.value) : decimalDigitsNotifier.value,
    );

    if (isEdit) {
      box.put(widget.entry!.key, newEntry);
    } else {
      box.add(newEntry);
    }

    // 繝輔ぅ繝ｼ繝峨ヰ繝・け蜀咲函・医お繝ｩ繝ｼ縺後≠縺｣縺ｦ繧ら判髱｢縺ｯ髢峨§繧九ｈ縺・↓try-finally縺ｾ縺溘・catch縺ｧ菫晁ｭｷ・・
    try {
      await _playFeedback(selectedType);
      
      // 譁ｰ隕剰ｨ倬鹸縺ｮ蝣ｴ蜷医・縺ｿ繝槭う繝ｫ繧ｹ繝医・繝ｳ蛻､螳壹ｒ陦後≧
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
    // 繧ｿ繧､繝励＃縺ｨ縺ｮ險ｭ螳・
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
        // 繝｡繝｢逕ｨ・壻ｸ譌ｦ蠅励∴縺滓凾縺ｨ蜷後§髻ｳ縺ｪ縺ｩ繧剃ｽｿ縺・°縲∵而縺医ａ縺ｪ繧ゅ・縺ｫ縺吶ｋ
        // 縺薙％縺ｧ縺ｯ蠅励∴縺滓凾縺ｨ蜷後§逕ｻ蜒擾ｼ郁ｲｯ驥醍ｮｱ縺ｧ縺ｯ縺ｪ縺・婿・峨↑縺ｩ繧呈ｵ∫畑
        soundFile = 'sounds/increase.mp3';
        lottieFile = 'assets/lottie/increase.json';
        vibrationDuration = 200;
        break;
    }

    // 1. 謖ｯ蜍輔→髻ｳ繧剃ｸｦ蛻怜・逕滂ｼ亥ｾ・◆縺ｪ縺上※繧医＞縺後・浹縺ｯ蜀咲函髢句ｧ九ｒ遒ｺ隱阪＠縺溘＞縺ｮ縺ｧawait縺励※繧り憶縺・ｼ・
    Vibration.vibrate(duration: vibrationDuration);

    final soundFuture = AudioPlayer().play(AssetSource(soundFile));

    // 繧ｨ繝ｩ繝ｼ繝上Φ繝峨Μ繝ｳ繧ｰ縺ｮ縺溘ａFuture.wait縺ｧ蝗ｲ繧縺後∝､ｱ謨励＠縺ｦ繧よｬ｡縺ｸ騾ｲ繧
    await Future.wait([
      soundFuture.catchError((_) {})
    ]);

    // 2. 繧｢繝九Γ繝ｼ繧ｷ繝ｧ繝ｳ繝繧､繧｢繝ｭ繧ｰ陦ｨ遉ｺ
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // 逕ｻ髱｢蟷・・80%縺ｨ300px縺ｮ蟆上＆縺・婿繧呈治逕ｨ・医・縺ｿ蜃ｺ縺鈴亟豁｢・・
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final size = (screenWidth * 0.8 < 300) ? screenWidth * 0.8 : 300.0;

        final lottieWidget = Lottie.asset(
          lottieFile,
          width: type == MoneyType.increase ? size * 1.5 : size,
          height: type == MoneyType.increase ? size * 1.5 : size,
          repeat: false,
          onLoaded: (composition) {
            // 繧｢繝九Γ繝ｼ繧ｷ繝ｧ繝ｳ譎る俣縺ｮ1.5蛟榊ｾ・▲縺ｦ縺九ｉ繝繧､繧｢繝ｭ繧ｰ繧帝哩縺倥ｋ・磯聞縺剰ｦ九○繧九◆繧・ｼ・
            Future.delayed(composition.duration * 1.2, () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          },
          // 隱ｭ縺ｿ霎ｼ縺ｿ繧ｨ繝ｩ繝ｼ譎ゅ・繝輔か繝ｼ繝ｫ繝舌ャ繧ｯ・育判髱｢縺後Ο繝・け縺輔ｌ縺ｪ縺・ｈ縺・↓・・
          errorBuilder: (context, error, stackTrace) {
            Future.delayed(Duration.zero, () {
               if (context.mounted) Navigator.of(context).pop();
            });
            return SizedBox();
          },
        );

        final imageWidget = TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: screenHeight, end: 0),
          // 逋ｻ蝣ｴ縺ｮ繧｢繝九Γ繝ｼ繧ｷ繝ｧ繝ｳ閾ｪ菴薙ｂ 600ms -> 720ms 縺ｫ1.2蛟阪ｆ縺｣縺上ｊ縺ｫ縺吶ｋ
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
                      color: memoFocusNode.hasFocus ? context.appColors.accent : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: memoFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: context.appColors.accent.withOpacity(0.3),
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
                      color: amountFocusNode.hasFocus ? context.appColors.accent : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: amountFocusNode.hasFocus
                        ? [
                            BoxShadow(
                              color: context.appColors.accent.withOpacity(0.3),
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
                          // OutlinedButton縺ｮ譁・ｭ苓牡繧偵Γ繧､繝ｳ縺ｮ鮟偵↓
                          foregroundColor: context.appColors.mainText, 
                          side: const BorderSide(color: Colors.grey), // 譫邱壹・濶ｲ繧ょ､峨∴縺溘＞蝣ｴ蜷医・縺薙％
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
  }
}


