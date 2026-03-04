
// アプリ全体で使う共通の文字列
class AppStrings {
  // main_page.dart
  static const String appTitle = 'おかねメモ';
  static const String noRecordMessage = 'まだ記録がありません';
  static const String deleteDialogTitle = '削除しますか？';
  static const String deleteDialogContent = 'この記録を削除します。';
  static const String cancelButtonText = 'キャンセル';
  static const String deleteButtonText = '削除';

  // input_page.dart
  static const String deleteSuccessMessage = '削除しました';
  static const String inputErrorSnackbarMessage = '項目と金額を入力してください';
  static const String memoLabelDecrease = '何に？';
  static const String memoLabelIncrease = '何で？';
  static const String memoHintDecrease = '例：アイス、ゲーム';
  static const String memoHintIncrease = '例：お小遣い、プレゼント';
  static const String typeSelectionTitle = '減った？ 増えた？';
  static const String amountLabel = 'いくら？';
  static const String amountHint = '0';
  static const String updateButtonText = '更新する';
  static const String recordButtonText = '記録する';
  static const String deleteButtonTextInput = '削除する'; // 削除ボタンのテキストがmain_pageと重複するが、input_page用として分けておく
  static const String editRecordTitle = '記録を編集する';
  static const String newRecordTitle = '新しく記録する';



  // period_page.dart
  static const String periodPageTitle = '期間で見る';
  static const String dateSectionTitle = '■ 日付';
  static const String fromLabel = 'から';
  static const String toLabel = 'まで';
  static const String copyButtonText = 'この期間の記録をコピー';
  static const String copySuccessMessage = 'コピーしました！';
  static const String totalSectionTitle = '■ 合計';
  static const String detailSectionTitle = '■ 内訳';
  static const String increaseTypeLabel = '増えた';
  static const String decreaseTypeLabel = '減った';
  static const String clipboardHeader = '日付\t内容\t種別\t金額';
  static const String clipboardNote = '※タブ区切りテキスト形式のため、Excel等の表計算ソフトへの貼り付けが可能です\n';

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
  static const double typeButtonBorderRadius = 24.0;
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
}

// MoneyEntryのtypeを表す文字列 (これはmodels/money_entry.dartのextensionで使うことを想定)
class MoneyEntryTypes {
  static const String increase = 'increase';
  static const String decrease = 'decrease';
}