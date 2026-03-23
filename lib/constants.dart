import 'app_state.dart';

// アプリ全体で使う共通の文字列
class AppStrings {
  static String _get(String key) {
    final lang = languageNotifier.value;
    return _translations[lang]?[key] ?? _translations['ja']![key]!;
  }

  static List<String> _getList(String key) {
    final lang = languageNotifier.value;
    return _listTranslations[lang]?[key] ?? _listTranslations['ja']![key]!;
  }

  static const Map<String, Map<String, String>> _translations = {
    'ja': {
      'appTitle': 'おかねメモ',
      'noRecordMessage': 'まだ記録がありません',
      'deleteDialogTitle': '削除しますか？',
      'deleteDialogContent': 'この記録を削除します。',
      'cancelButtonText': 'キャンセル',
      'deleteButtonText': '削除',
      'deleteSuccessMessage': '削除しました',
      'inputErrorSnackbarMessage': '項目と金額を入力してください',
      'memoLabelDecrease': '何に？',
      'memoLabelIncrease': '何で？',
      'memoHintDecrease': '例：アイス、ゲーム',
      'memoHintIncrease': '例：お小遣い、プレゼント',
      'memoLabelMemo': '内容は？',
      'memoHintMemo': '例：なんでもメモ',
      'typeSelectionTitle': '減った？ 増えた？ メモ？',
      'amountLabel': 'いくら？',
      'amountHint': '0',
      'updateButtonText': '更新する',
      'recordButtonText': '記録する',
      'deleteButtonTextInput': '削除する',
      'editRecordTitle': '編集する',
      'newRecordTitle': '新しく記録する',
      'periodPageTitle': '期間で見る',
      'dateSectionTitle': '■ 日付',
      'fromLabel': 'から',
      'toLabel': 'まで',
      'copyButtonText': 'この期間の記録を共有',
      'totalSectionTitle': '合計',
      'detailSectionTitle': '内訳',
      'increaseTypeLabel': '増えた',
      'decreaseTypeLabel': '減った',
      'shareIncreaseLabel': '増えた：',
      'shareDecreaseLabel': '減った：',
      'memoTypeLabel': 'メモのみ',
      'clipboardHeader': '日付\t内容\t種別\t金額',
      'clipboardNote': '※タブ区切りテキスト形式のため、Excel等の表計算ソフトへの貼り付けが可能です\n',
      'milestoneCount1': 'はじめのいっぽ！\nおかねの記録をはじめたね',
      'milestoneCount10': 'すごーい！\n10回も記録できたね。慣れてきたかな？',
      'milestoneCount30': '記録の達人！\n30回達成おめでとう！',
      'milestoneCount50': 'キラキラの50回！\nお金と仲良くなってきたね',
      'milestoneDay3': '通算3日の記録達成！\n3日坊主を卒業して、さらなる一歩だね！',
      'milestoneDay7': '通算7日の記録達成！\n1週間、よくがんばりました！',
      'milestoneDay30': '通算30日の継続中！\n1ヶ月の記念だね、その調子！',
      'milestoneDay100': '通算100日の記録達成！\nもうプロの域だね、すばらしい！',
      'settingsTitle': '設定',
      'titleSetting': 'タイトル',
      'dataManagementTitle': 'データ管理',
      'resetAllData': '初期化',
      'resetAllDataSubtitle': 'すべての記録と達成記録を消去します',
      'resetConfirmTitle': 'すべてリセットしますか？',
      'resetConfirmContent': 'すべての記録を削除し、1日目からやり直します。この操作は取り消せません。',
      'resetSuccess': 'すべてリセットしました',
      'appInfoTitle': 'アプリについて',
      'versionLabel': 'バージョン',
      'currencySettingTitle': '通貨の設定',
      'languageSettingTitle': '言語の設定',
      'languageJa': '日本語',
      'languageEn': 'English',
      'yearLabel': '年',
      'monthLabel': '月',
      'yearlySummaryTitle': '年別集計',
      'monthHeader': '月',
      'monthlySummaryTitle': '月別集計',
      'noRecordInPeriod': '記録はありません',
      'shareMessage': 'の記録',
      'shareNoRecordError': '記録がない期間は共有できません',
      'closeButtonText': 'とじる',
      'today': '今日',
      'yesterday': '昨日',
      'setupWelcome': 'ようこそ！',
      'setupLanguage': 'ことばをえらんでね',
      'setupCurrency': 'つかうおかねをえらんでね',
      'setupTitle': 'なまえをきめてね',
      'setupTitleHint': '例：じぶんのおかねメモ',
      'setupStart': 'はじめる',
      'setupNext': 'つぎへ',
      'setupFinalTitle': '準備完了！',
      'setupFinalMessage': '準備ができたよ！\nさっそく使ってみよう',
      'setupTitleExample': '例：たろうのお小遣い帳、ランチ代の記録、光熱費のメモ、など',
      'exportLabel': 'エクスポート (CSV)',
      'exportSubtitle': '記録データを保存・共有します',
      'importLabel': 'インポート (CSV)',
      'importSubtitle': '保存したデータを読み込みます',
      'themeSettingTitle': 'テーマ',
      'lightMode': 'ライトモード',
      'darkMode': 'ダークモード',
    },
    'en': {
      'appTitle': 'Money Memo',
      'noRecordMessage': 'No records yet',
      'deleteDialogTitle': 'Delete?',
      'deleteDialogContent': 'This record will be deleted.',
      'cancelButtonText': 'Cancel',
      'deleteButtonText': 'Delete',
      'deleteSuccessMessage': 'Deleted',
      'inputErrorSnackbarMessage': 'Please enter both item and amount',
      'memoLabelDecrease': 'What for?',
      'memoLabelIncrease': 'From where?',
      'memoHintDecrease': 'e.g., Ice cream, Lunch',
      'memoHintIncrease': 'e.g., Pocket money, Gift',
      'memoLabelMemo': 'What content?',
      'memoHintMemo': 'e.g., Any notes',
      'typeSelectionTitle': 'Income? Expense? Memo?',
      'amountLabel': 'How much?',
      'amountHint': '0',
      'updateButtonText': 'Update',
      'recordButtonText': 'Record',
      'deleteButtonTextInput': 'Delete',
      'editRecordTitle': 'Edit',
      'newRecordTitle': 'New Record',
      'periodPageTitle': 'History',
      'dateSectionTitle': '■ Date',
      'fromLabel': 'From',
      'toLabel': 'To',
      'copyButtonText': 'Share records',
      'totalSectionTitle': 'Total',
      'detailSectionTitle': 'Details',
      'increaseTypeLabel': 'Income',
      'decreaseTypeLabel': 'Expense',
      'shareIncreaseLabel': 'Income: ',
      'shareDecreaseLabel': 'Expense: ',
      'memoTypeLabel': 'Memo',
      'clipboardHeader': 'Date\tContent\tType\tAmount',
      'clipboardNote': '*Tab-separated text format, suitable for spreadsheets like Excel.\n',
      'milestoneCount1': 'First step!\nYou started recording your money',
      'milestoneCount10': 'Amazing!\nYou recorded 10 times. Getting used to it?',
      'milestoneCount30': 'Record Master!\nCongrats on 30 records!',
      'milestoneCount50': 'Sparkling 50!\nYou\'re becoming friends with money',
      'milestoneDay3': 'Total 3 days!\nYou\'re no longer a three-day wonder!',
      'milestoneDay7': 'Total 7 days!\nYou did great for a week!',
      'milestoneDay30': '30 days persistence!\nA one-month anniversary, keep it up!',
      'milestoneDay100': 'Total 100 days!\nYou\'re a pro now, wonderful!',
      'settingsTitle': 'Settings',
      'titleSetting': 'Title',
      'dataManagementTitle': 'Data Management',
      'resetAllData': 'Reset',
      'resetAllDataSubtitle': 'Erase all records and milestones',
      'resetConfirmTitle': 'Reset everything?',
      'resetConfirmContent': 'All records will be deleted. This cannot be undone.',
      'resetSuccess': 'Successfully reset everything',
      'appInfoTitle': 'About App',
      'versionLabel': 'Version',
      'currencySettingTitle': 'Currency',
      'languageSettingTitle': 'Language',
      'languageJa': 'Japanese',
      'languageEn': 'English',
      'yearLabel': '/',
      'monthLabel': '',
      'yearlySummaryTitle': 'Yearly Summary',
      'monthHeader': 'Month',
      'monthlySummaryTitle': 'Monthly Summary',
      'noRecordInPeriod': 'No records',
      'shareMessage': 'Records for ',
      'shareNoRecordError': 'Cannot share period with no records',
      'closeButtonText': 'Close',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'setupWelcome': 'Welcome!',
      'setupLanguage': 'Choose your language',
      'setupCurrency': 'Choose your currency',
      'setupTitle': 'Choose app title',
      'setupTitleHint': 'Money Memo',
      'setupStart': 'Get Started',
      'setupNext': 'Next',
      'setupFinalTitle': 'Ready!',
      'setupFinalMessage': "You're all set!\nLet's get started",
      'setupTitleExample': 'e.g., John\'s Money Memo, My Expenses, Utility Bills, etc.',
      'exportLabel': 'Export (CSV)',
      'exportSubtitle': 'Save and share recorded data',
      'importLabel': 'Import (CSV)',
      'importSubtitle': 'Load saved data',
      'themeSettingTitle': 'Theme',
      'lightMode': 'Light Mode',
      'darkMode': 'Dark Mode',
    }
  };

  static const Map<String, Map<String, List<String>>> _listTranslations = {
    'ja': {
      'milestoneCountEvery50': [
        'さらに50回！\n累計{count}回達成、すごい継続力だね！',
        '記録の達人！\nついに{count}回。自分を褒めてあげよう！',
        'チャリン！\n{count}回達成。おかねの管理が身についてるね！',
      ],
      'milestoneDayEvery100': [
        '通算{days}日達成！\n伝説はまだまだ続くね。すごい！',
        '祝・{days}日！\nコツコツ続ける天才だね。これからも一緒に！',
        'もう{days}日だね！\n記録が当たり前になってて素晴らしいよ！',
      ],
    },
    'en': {
      'milestoneCountEvery50': [
        'Another 50!\nTotal {count} records, what persistence!',
        'Record Master!\n{count} records. Give yourself a hand!',
        'Ka-ching!\n{count} records. You\'ve got money management down!',
      ],
      'milestoneDayEvery100': [
        'Total {days} days!\nThe legend continues. Amazing!',
        'Congrats on {days} days!\nYou\'re a steady genius. Let\'s keep it up!',
        'Already {days} days!\nRecording has become second nature for you!',
      ],
    }
  };

  static String get appTitle => _get('appTitle');
  static String get noRecordMessage => _get('noRecordMessage');
  static String get deleteDialogTitle => _get('deleteDialogTitle');
  static String get deleteDialogContent => _get('deleteDialogContent');
  static String get cancelButtonText => _get('cancelButtonText');
  static String get deleteButtonText => _get('deleteButtonText');
  static String get deleteSuccessMessage => _get('deleteSuccessMessage');
  static String get inputErrorSnackbarMessage => _get('inputErrorSnackbarMessage');
  static String get memoLabelDecrease => _get('memoLabelDecrease');
  static String get memoLabelIncrease => _get('memoLabelIncrease');
  static String get memoHintDecrease => _get('memoHintDecrease');
  static String get memoHintIncrease => _get('memoHintIncrease');
  static String get memoLabelMemo => _get('memoLabelMemo');
  static String get memoHintMemo => _get('memoHintMemo');
  static String get typeSelectionTitle => _get('typeSelectionTitle');
  static String get amountLabel => _get('amountLabel');
  static String get amountHint => _get('amountHint');
  static String get updateButtonText => _get('updateButtonText');
  static String get recordButtonText => _get('recordButtonText');
  static String get deleteButtonTextInput => _get('deleteButtonTextInput');
  static String get editRecordTitle => _get('editRecordTitle');
  static String get newRecordTitle => _get('newRecordTitle');
  static String get periodPageTitle => _get('periodPageTitle');
  static String get dateSectionTitle => _get('dateSectionTitle');
  static String get fromLabel => _get('fromLabel');
  static String get toLabel => _get('toLabel');
  static String get copyButtonText => _get('copyButtonText');
  static String get totalSectionTitle => _get('totalSectionTitle');
  static String get detailSectionTitle => _get('detailSectionTitle');
  static String get increaseTypeLabel => _get('increaseTypeLabel');
  static String get decreaseTypeLabel => _get('decreaseTypeLabel');
  static String get shareIncreaseLabel => _get('shareIncreaseLabel');
  static String get shareDecreaseLabel => _get('shareDecreaseLabel');
  static String get memoTypeLabel => _get('memoTypeLabel');
  static String get clipboardHeader => _get('clipboardHeader');
  static String get clipboardNote => _get('clipboardNote');
  static String get milestoneCount1 => _get('milestoneCount1');
  static String get milestoneCount10 => _get('milestoneCount10');
  static String get milestoneCount30 => _get('milestoneCount30');
  static String get milestoneCount50 => _get('milestoneCount50');
  static String get milestoneDay3 => _get('milestoneDay3');
  static String get milestoneDay7 => _get('milestoneDay7');
  static String get milestoneDay30 => _get('milestoneDay30');
  static String get milestoneDay100 => _get('milestoneDay100');
  static String get settingsTitle => _get('settingsTitle');
  static String get titleSetting => _get('titleSetting');
  static String get dataManagementTitle => _get('dataManagementTitle');
  static String get resetAllData => _get('resetAllData');
  static String get resetAllDataSubtitle => _get('resetAllDataSubtitle');
  static String get resetConfirmTitle => _get('resetConfirmTitle');
  static String get resetConfirmContent => _get('resetConfirmContent');
  static String get resetSuccess => _get('resetSuccess');
  static String get appInfoTitle => _get('appInfoTitle');
  static String get versionLabel => _get('versionLabel');
  static String get currencySettingTitle => _get('currencySettingTitle');
  static String get languageSettingTitle => _get('languageSettingTitle');
  static String get languageJa => _get('languageJa');
  static String get languageEn => _get('languageEn');
  static String get yearLabel => _get('yearLabel');
  static String get monthLabel => _get('monthLabel');
  static String get yearlySummaryTitle => _get('yearlySummaryTitle');
  static String get monthHeader => _get('monthHeader');
  static String get monthlySummaryTitle => _get('monthlySummaryTitle');
  static String get noRecordInPeriod => _get('noRecordInPeriod');
  static String get shareMessage => _get('shareMessage');
  static String get shareNoRecordError => _get('shareNoRecordError');
  static String get closeButtonText => _get('closeButtonText');
  static String get today => _get('today');
  static String get yesterday => _get('yesterday');
  static String get setupWelcome => _get('setupWelcome');
  static String get setupLanguage => _get('setupLanguage');
  static String get setupCurrency => _get('setupCurrency');
  static String get setupTitle => _get('setupTitle');
  static String get setupTitleHint => _get('setupTitleHint');
  static String get setupStart => _get('setupStart');
  static String get setupNext => _get('setupNext');
  static String get setupFinalTitle => _get('setupFinalTitle');
  static String get setupFinalMessage => _get('setupFinalMessage');
  static String get setupTitleExample => _get('setupTitleExample');
  static String get exportLabel => _get('exportLabel');
  static String get exportSubtitle => _get('exportSubtitle');
  static String get importLabel => _get('importLabel');
  static String get importSubtitle => _get('importSubtitle');
  static String get themeSettingTitle => _get('themeSettingTitle');
  static String get lightMode => _get('lightMode');
  static String get darkMode => _get('darkMode');

  static const String appVersion = '1.0.0';

  static List<String> get milestoneCountEvery50 => _getList('milestoneCountEvery50');
  static List<String> get milestoneDayEvery100 => _getList('milestoneDayEvery100');
}

// アプリ全体で使う共通の数値
class AppNumbers {
  static const double titleFontSize = 24.0;
  static const double subPageTitleFontSize = 24.0;
  static const double sectionTitleFontSize = 18.0;
  static const double amountTextFontSize = 24.0;
  static const double appBarElevation = 0.0;
  static const double defaultPadding = 16.0;
  static const double mediumSpacing = 12.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;
  static const double cardBorderRadius = 12.0;
  
  // main_page.dart
  static const double listViewHorizontalPadding = 12.0;
  static const double listViewVerticalPadding = 8.0;

  // input_page.dart
  static const int minInputDatePickerYear = 2020; // input_pageの日付選択の最小年
  static const double typeButtonBorderRadius = 12.0;
  static const double calendarIconSize = 20.0;
  static const double calendarFontSize = 18.0;
  
  // period_page.dart
  static const int initialPeriodDays = 30;
  static const int minDatePickerYear = 2000;
  static const int maxDatePickerYear = 2100;

  // 合計ラベル・金額のサイズ
  static const double totalAmountSize = 32.0;
}

// HiveのBox名
class HiveConstants {
  static const String moneyBoxName = 'moneyBox';
  static const String settingsBoxName = 'settingsBox';
  static const String statsBoxName = 'statsBox';

  // Settings keys
  static const String keyAppTitle = 'appTitle';
  static const String keyCurrency = 'currency';
  static const String keyDecimalDigits = 'decimalDigits';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'themeMode';
  static const String keyOnboardingCompleted = 'onboardingCompleted';
}

// MoneyEntryのtypeを表す文字列 (これはmodels/money_entry.dartのextensionで使うことを想定)
class MoneyEntryTypes {
  static const String increase = 'increase';
  static const String decrease = 'decrease';
  static const String memo = 'memo';
}