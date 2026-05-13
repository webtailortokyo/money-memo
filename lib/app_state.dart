import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

// タイトル変更を即時反映するための notifier
final appTitleNotifier = ValueNotifier<String>(AppStrings.appTitle);

// 通貨記号（¥, $, € など）
final currencyNotifier = ValueNotifier<String>('¥');

// 小数点以下の桁数（Jpyは0, Usd/Eurは2など）
final decimalDigitsNotifier = ValueNotifier<int>(0);

// 言語設定 ('ja' または 'en')
final languageNotifier = ValueNotifier<String>('ja');

// テーマ設定 (ThemeMode.light または ThemeMode.dark)
final appThemeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

// カスタム単位のリスト
final customUnitsNotifier = ValueNotifier<List<String>>([]);

/// 二つの ValueListenable を同時に監視するためのヘルパークラス
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> valueListenable1;
  final ValueListenable<B> valueListenable2;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.valueListenable1,
    required this.valueListenable2,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: valueListenable1,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: valueListenable2,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
    );
  }
}
