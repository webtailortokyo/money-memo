import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';
import '../app_state.dart';
import 'main_page.dart';
import '../theme.dart';
import '../utils/notification_manager.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final PageController _pageController = PageController();
  final TextEditingController _titleController = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    final settingsBox = Hive.box(HiveConstants.settingsBoxName);

    // タイトルの保存
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      settingsBox.put(HiveConstants.keyAppTitle, title);
      appTitleNotifier.value = title;
    } else {
      appTitleNotifier.value = AppStrings.appTitle;
    }

    // オンボーディング完了フラグをセット
    await settingsBox.put(HiveConstants.keyOnboardingCompleted, true);

    // 通知のスケジュールを設定
    await NotificationManager.scheduleInactivityNotifications();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
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
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildLanguageStep(),
                        _buildCurrencyStep(),
                        _buildTitleStep(),
                        _buildFinalStep(),
                      ],
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContainer({
    required Widget titleWidget,
    required String svgPath,
    required Widget content,
    double? svgHeight,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          titleWidget,
          const SizedBox(height: 40),
          SizedBox(height: svgHeight ?? 200, child: SvgPicture.asset(svgPath)),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    return _buildStepContainer(
      titleWidget: Column(
        children: [
          Text(
            'ようこそ！ / Welcome!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.appColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      svgPath: 'assets/img/a_pig_holding_a_piggy_bank.svg',
      content: Column(
        children: [
          Text(
            'ことばをえらんでね / Choose your language',
            style: TextStyle(color: context.appColors.mainText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String>(
            valueListenable: languageNotifier,
            builder: (context, lang, child) {
              return SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'ja',
                    label: Text(AppStrings.languageJa),
                  ),
                  ButtonSegment(
                    value: 'en',
                    label: Text(AppStrings.languageEn),
                  ),
                ],
                selected: {lang},
                onSelectionChanged: (Set<String> newSelection) {
                  final newLang = newSelection.first;
                  languageNotifier.value = newLang;
                  Hive.box(
                    HiveConstants.settingsBoxName,
                  ).put(HiveConstants.keyLanguage, newLang);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: context.appColors.accent,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: context.appColors.accent,
                  side: BorderSide(color: context.appColors.accent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyStep() {
    return _buildStepContainer(
      titleWidget: Text(
        AppStrings.currencySettingTitle,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: context.appColors.accent,
        ),
        textAlign: TextAlign.center,
      ),
      svgPath: 'assets/img/piggy_bank.svg',
      svgHeight: 140, // 小さくする
      content: Column(
        children: [
          Text(
            AppStrings.setupCurrency,
            style: TextStyle(color: context.appColors.mainText),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String>(
            valueListenable: currencyNotifier,
            builder: (context, symbol, child) {
              return SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: '¥',
                    label: Text(
                      languageNotifier.value == 'ja' ? '円(¥)' : 'JPY(¥)',
                    ),
                  ),
                  const ButtonSegment(value: '\$', label: Text('USD(\$)')),
                  const ButtonSegment(value: '€', label: Text('EUR(€)')),
                ],
                selected: {symbol},
                onSelectionChanged: (Set<String> newSelection) {
                  final newSymbol = newSelection.first;
                  final newDigits = newSymbol == '¥' ? 0 : 2;

                  currencyNotifier.value = newSymbol;
                  decimalDigitsNotifier.value = newDigits;

                  final box = Hive.box(HiveConstants.settingsBoxName);
                  box.put(HiveConstants.keyCurrency, newSymbol);
                  box.put(HiveConstants.keyDecimalDigits, newDigits);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: context.appColors.accent,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: context.appColors.accent,
                  side: BorderSide(color: context.appColors.accent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitleStep() {
    return _buildStepContainer(
      titleWidget: Text(
        AppStrings.titleSetting,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: context.appColors.accent,
        ),
        textAlign: TextAlign.center,
      ),
      svgPath: 'assets/img/think_pose.svg',
      content: Column(
        children: [
          Text(
            AppStrings.setupTitle,
            style: TextStyle(
              color: context.appColors.mainText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            cursorColor: context.appColors.accent,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: AppStrings.setupTitleHint,
              filled: true,
              fillColor: context.appColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.appColors.accent.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.appColors.accent,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              AppStrings.setupTitleExample,
              style: TextStyle(
                color: context.appColors.mainText.withOpacity(0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStep() {
    return _buildStepContainer(
      titleWidget: Text(
        AppStrings.setupFinalTitle,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: context.appColors.accent,
        ),
        textAlign: TextAlign.center,
      ),
      svgPath: 'assets/img/joy_pose.svg',
      content: Column(
        children: [
          Text(
            AppStrings.setupFinalMessage,
            style: TextStyle(color: context.appColors.mainText, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 戻るボタンまたはインジケーター
          _currentPage > 0
              ? OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appColors.accent,
                    side: BorderSide(color: context.appColors.accent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    AppStrings.backButtonText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : Row(
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? context.appColors.accent
                            : context.appColors.accent.withOpacity(0.2),
                      ),
                    );
                  }),
                ),
          // 次へボタン
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              _currentPage == 3 ? AppStrings.setupStart : AppStrings.setupNext,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
