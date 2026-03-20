// lib/pages/main_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'period_page.dart';
import 'input_page.dart';
import '../theme.dart';
import '../models/money_entry.dart';
import '../models/money_type.dart';
import '../widgets/money_entry_card.dart';
import '../widgets/piggy_character.dart';
import '../utils/sort_entries.dart';
import '../utils/input_formatter.dart';
import '../constants.dart';
import '../utils/milestone_manager.dart';

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

  @override
  void initState() {
    super.initState();
    box = Hive.box<MoneyEntry>(HiveConstants.moneyBoxName);
    amountFocusNode.addListener(() => setState(() {}));
    memoFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    amountController.dispose();
    memoController.dispose();
    amountFocusNode.dispose();
    memoFocusNode.dispose();
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
      // memoController.clear(); 
    });
  }

  Future<void> _save() async {
    final memo = memoController.text.trim();
    final amountText = amountController.text.trim();
    final cleanedAmount = amountText.replaceAll(',', '');

    if (memo.isEmpty || (selectedType != MoneyType.memo && amountText.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.inputErrorSnackbarMessage)),
      );
      return;
    }

    final amount = selectedType == MoneyType.memo ? 0 : int.tryParse(cleanedAmount);
    if (amount == null) return;

    final newEntry = MoneyEntry(
      amount: amount,
      memo: memo,
      type: selectedType.name,
      date: selectedDate,
    );

    box.add(newEntry);

    // 入力エリアをリセット
    memoController.clear();
    amountController.clear();
    setState(() {
      selectedType = MoneyType.decrease;
      selectedDate = DateTime.now();
    });

    try {
      final feedbackType = selectedType == MoneyType.memo ? MoneyType.memo : (newEntry.type == MoneyType.increase.name ? MoneyType.increase : MoneyType.decrease);
      await _playFeedback(feedbackType);
      
      // 保存完了後にマイルストーン判定を行う
      if (context.mounted) {
        await MilestoneManager.checkAndShow(context);
      }
    } catch (e) {
      log('Feedback error: $e');
    }
  }

  Future<void> _playFeedback(MoneyType type) async {
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
        soundFile = 'sounds/increase.mp3';
        lottieFile = 'assets/lottie/increase.json';
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
        final screenHeight = MediaQuery.of(context).size.height;
        final size = (screenWidth * 0.8 < 300) ? screenWidth * 0.8 : 300.0;

        final lottieWidget = Lottie.asset(
          lottieFile,
          width: type == MoneyType.increase ? size * 1.5 : size,
          height: type == MoneyType.increase ? size * 1.5 : size,
          repeat: false,
          onLoaded: (composition) {
            Future.delayed(composition.duration * 1.2, () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          },
          errorBuilder: (context, error, stackTrace) {
            Future.delayed(Duration.zero, () {
               if (context.mounted) Navigator.of(context).pop();
            });
            return const SizedBox();
          },
        );

        final imageWidget = TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: screenHeight, end: 0),
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

  Widget _typeButton(String label, MoneyType type, Color color) {
    return Expanded(
      child: _typeButtonInner(label, type, color),
    );
  }

  Widget _typeButtonWrapper(BuildContext context, String label, MoneyType type, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (AppNumbers.defaultPadding + AppNumbers.smallSpacing) * 2;
    final totalSpacing = AppNumbers.smallSpacing * 2;
    // 基本の幅を3等分にするが、最小幅を下回らないようにする
    final buttonWidth = (screenWidth - horizontalPadding - totalSpacing) / 3.05;

    return Container(
      constraints: BoxConstraints(minWidth: buttonWidth),
      child: _typeButtonInner(label, type, color),
    );
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



  Widget _amountTextField() {
    return AnimatedContainer(
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
          FilteringTextInputFormatter.digitsOnly,
          ThousandsSeparatorInputFormatter(),
        ],
        decoration: InputDecoration(
          hintText: '0',
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppNumbers.defaultPadding),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: AppNumbers.defaultPadding, right: 4),
            child: Text(
              '¥',
              style: TextStyle(
                height: 1.5,
                color: selectedType == MoneyType.memo ? Colors.grey : AppColors.mainText,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _recordButton() {
    return ElevatedButton.icon(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.only(left: 28, right: 44, top: 22, bottom: 22),
      ),

      icon: const Icon(Icons.check),
      label: const Text(
        AppStrings.recordButtonText,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: AppNumbers.appBarElevation,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/img/app_icon.svg',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              AppStrings.appTitle,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: AppNumbers.titleFontSize,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PeriodPage()),
          );
        },
        label: const Text(
          AppStrings.periodPageTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.history, color: Colors.white),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 入力エリア
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppNumbers.defaultPadding + AppNumbers.smallSpacing,
                  vertical: AppNumbers.smallSpacing,
                ),
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
                          color: Colors.white,
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
                              '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                              style: const TextStyle(
                                fontSize: AppNumbers.calendarFontSize,
                                color: AppColors.mainText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppNumbers.smallSpacing),

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

                    const SizedBox(height: AppNumbers.smallSpacing),

                    Column(
                      children: [
                        _amountTextField(),
                        const SizedBox(height: AppNumbers.smallSpacing),
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

            // 記録リスト
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

                final entries = sortedEntries(box);

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
                              builder: (_) => AlertDialog(
                                title: const Text(AppStrings.deleteDialogTitle),
                                content: const Text(AppStrings.deleteDialogContent),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text(AppStrings.cancelButtonText),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      AppStrings.deleteButtonText,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
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
            // 下部の余白
            const SliverToBoxAdapter(
              child: SizedBox(height: 80.0), // FABと重ならないように余白を多めに確保
            ),
          ],
        ),
      ),
    );
  }
}