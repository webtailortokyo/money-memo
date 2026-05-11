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

  // 通知設定用のステート
  bool? _wantsNotification = true;
  String _notificationFrequency = 'daily';
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  int _notificationDayOfWeek = 1; // 月曜
  int _notificationDayOfMonth = 1;

  @override
  void initState() {
    super.initState();
    // 権限リクエストは完了直前に呼び出すよう変更
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  List<Widget> get _buildPages {
    final pages = [
      _buildLanguageStep(),
      _buildCurrencyStep(),
      _buildTitleStep(),
      _buildNotificationToggleStep(),
    ];
    if (_wantsNotification == true) {
      pages.add(_buildNotificationDetailStep());
    }
    pages.add(_buildFinalStep());
    return pages;
  }

  void _nextPage() {
    final pagesCount = _buildPages.length;
    final currentWidget = _buildPages[_currentPage];

    // 通知トグル画面で未選択の場合は進めない
    if (currentWidget.key == const ValueKey('notificationToggleStep')) {
      if (_wantsNotification == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択してください')),
        );
        return;
      }
      if (_wantsNotification == true) {
        // 「はい」を選んで次へ進むときに権限を要求する
        NotificationManager.requestPermissions();
      }
    }

    if (_currentPage < pagesCount - 1) {
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

    // 通知設定の保存
    if (_wantsNotification == true) {
      await settingsBox.put(HiveConstants.keyPeriodicNotificationEnabled, true);
      await settingsBox.put(HiveConstants.keyPeriodicNotificationFrequency, _notificationFrequency);
      await settingsBox.put(HiveConstants.keyPeriodicNotificationTimeHour, _notificationTime.hour);
      await settingsBox.put(HiveConstants.keyPeriodicNotificationTimeMinute, _notificationTime.minute);
      await settingsBox.put(HiveConstants.keyPeriodicNotificationDayOfWeek, _notificationDayOfWeek);
      await settingsBox.put(HiveConstants.keyPeriodicNotificationDayOfMonth, _notificationDayOfMonth);
    } else {
      await settingsBox.put(HiveConstants.keyPeriodicNotificationEnabled, false);
    }

    // オンボーディング完了フラグをセット
    await settingsBox.put(HiveConstants.keyOnboardingCompleted, true);

    // 通知のスケジュールを設定
    await NotificationManager.schedulePeriodicNotification();

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
        final pages = _buildPages;
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
                      children: pages,
                    ),
                  ),
                  _buildBottomBar(pages.length),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContainer({
    Key? key,
    required Widget titleWidget,
    required String svgPath,
    required Widget content,
    double? svgHeight,
  }) {
    return Padding(
      key: key,
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
                  color: context.appColors.accent.withValues(alpha: 0.2),
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
                color: context.appColors.mainText.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggleStep() {
    return _buildStepContainer(
      key: const ValueKey('notificationToggleStep'),
      titleWidget: Text(
        AppStrings.setupNotificationTitle,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: context.appColors.accent,
        ),
        textAlign: TextAlign.center,
      ),
      svgPath: 'assets/img/a_pig_holding_a_piggy_bank.svg',
      svgHeight: 140,
      content: Column(
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(AppStrings.setupNotificationYes),
              ),
              ButtonSegment(
                value: false,
                label: Text(AppStrings.setupNotificationNo),
              ),
            ],
            selected: _wantsNotification != null ? {_wantsNotification!} : <bool>{},
            emptySelectionAllowed: true,
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _wantsNotification = newSelection.isNotEmpty ? newSelection.first : null;
              });
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: context.appColors.accent,
              selectedForegroundColor: Colors.white,
              foregroundColor: context.appColors.accent,
              side: BorderSide(color: context.appColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDetailStep() {
    return _buildStepContainer(
      key: const ValueKey('notificationDetailStep'),
      titleWidget: Text(
        AppStrings.settingsNotificationEdit,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: context.appColors.accent,
        ),
        textAlign: TextAlign.center,
      ),
      svgPath: 'assets/img/think_pose.svg',
      svgHeight: 120,
      content: Column(
        children: [
          Text(
            AppStrings.setupNotificationFrequency,
            style: TextStyle(color: context.appColors.mainText, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'daily', label: Text(AppStrings.setupNotificationDaily)),
              ButtonSegment(value: 'weekly', label: Text(AppStrings.setupNotificationWeekly)),
              ButtonSegment(value: 'monthly', label: Text(AppStrings.setupNotificationMonthly)),
            ],
            selected: {_notificationFrequency},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _notificationFrequency = newSelection.first;
              });
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: context.appColors.accent,
              selectedForegroundColor: Colors.white,
              foregroundColor: context.appColors.accent,
              side: BorderSide(color: context.appColors.accent),
            ),
          ),
          const SizedBox(height: 24),

          if (_notificationFrequency == 'weekly') ...[
            Text(AppStrings.setupNotificationDayOfWeek, style: TextStyle(color: context.appColors.mainText)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _notificationDayOfWeek,
              items: [
                DropdownMenuItem(value: 1, child: Text('月曜日')),
                DropdownMenuItem(value: 2, child: Text('火曜日')),
                DropdownMenuItem(value: 3, child: Text('水曜日')),
                DropdownMenuItem(value: 4, child: Text('木曜日')),
                DropdownMenuItem(value: 5, child: Text('金曜日')),
                DropdownMenuItem(value: 6, child: Text('土曜日')),
                DropdownMenuItem(value: 7, child: Text('日曜日')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _notificationDayOfWeek = val);
              },
            ),
            const SizedBox(height: 24),
          ],

          if (_notificationFrequency == 'monthly') ...[
            Text(AppStrings.setupNotificationDayOfMonth, style: TextStyle(color: context.appColors.mainText)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _notificationDayOfMonth,
              items: List.generate(28, (index) {
                return DropdownMenuItem(value: index + 1, child: Text('${index + 1}日'));
              }),
              onChanged: (val) {
                if (val != null) setState(() => _notificationDayOfMonth = val);
              },
            ),
            const SizedBox(height: 24),
          ],

          Text(AppStrings.setupNotificationTime, style: TextStyle(color: context.appColors.mainText)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _notificationTime,
              );
              if (time != null) {
                setState(() => _notificationTime = time);
              }
            },
            child: Text('${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}'),
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

  Widget _buildBottomBar(int pagesCount) {
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
                  children: List.generate(pagesCount, (index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? context.appColors.accent
                            : context.appColors.accent.withValues(alpha: 0.2),
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
              _currentPage == pagesCount - 1 ? AppStrings.setupStart : AppStrings.setupNext,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
