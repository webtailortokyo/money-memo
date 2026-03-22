import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color background;
  final Color accent;
  final Color mainText;
  final Color decrease;
  final Color decreaseBg;
  final Color decreaseAmount;
  final Color increase;
  final Color increaseBg;
  final Color increaseAmount;
  final Color memo;
  final Color memoBg;
  final Color sectionBg;
  final Color inputBg;

  const AppColorsExtension({
    required this.background,
    required this.accent,
    required this.mainText,
    required this.decrease,
    required this.decreaseBg,
    required this.decreaseAmount,
    required this.increase,
    required this.increaseBg,
    required this.increaseAmount,
    required this.memo,
    required this.memoBg,
    required this.sectionBg,
    required this.inputBg,
  });

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? accent,
    Color? mainText,
    Color? decrease,
    Color? decreaseBg,
    Color? decreaseAmount,
    Color? increase,
    Color? increaseBg,
    Color? increaseAmount,
    Color? memo,
    Color? memoBg,
    Color? sectionBg,
    Color? inputBg,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      accent: accent ?? this.accent,
      mainText: mainText ?? this.mainText,
      decrease: decrease ?? this.decrease,
      decreaseBg: decreaseBg ?? this.decreaseBg,
      decreaseAmount: decreaseAmount ?? this.decreaseAmount,
      increase: increase ?? this.increase,
      increaseBg: increaseBg ?? this.increaseBg,
      increaseAmount: increaseAmount ?? this.increaseAmount,
      memo: memo ?? this.memo,
      memoBg: memoBg ?? this.memoBg,
      sectionBg: sectionBg ?? this.sectionBg,
      inputBg: inputBg ?? this.inputBg,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      mainText: Color.lerp(mainText, other.mainText, t)!,
      decrease: Color.lerp(decrease, other.decrease, t)!,
      decreaseBg: Color.lerp(decreaseBg, other.decreaseBg, t)!,
      decreaseAmount: Color.lerp(decreaseAmount, other.decreaseAmount, t)!,
      increase: Color.lerp(increase, other.increase, t)!,
      increaseBg: Color.lerp(increaseBg, other.increaseBg, t)!,
      increaseAmount: Color.lerp(increaseAmount, other.increaseAmount, t)!,
      memo: Color.lerp(memo, other.memo, t)!,
      memoBg: Color.lerp(memoBg, other.memoBg, t)!,
      sectionBg: Color.lerp(sectionBg, other.sectionBg, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
    );
  }
}

const lightAppColors = AppColorsExtension(
  background: Color(0xFFFFFBF0),
  accent: Color(0xFFED4CA5),
  mainText: Color(0xFF4A4A4A),
  decrease: Color(0xFFFF6467),
  decreaseBg: Color(0xFFFFE2E2),
  decreaseAmount: Color(0xFFC10007),
  increase: Color(0xFF05DF72),
  increaseBg: Color(0xFFDBFCE7),
  increaseAmount: Color(0xFF008236),
  memo: Color(0xFF757575),
  memoBg: Color(0xFFE0E0E0),
  sectionBg: Color(0xFFFFF2D9),
  inputBg: Colors.white,
);

const darkAppColors = AppColorsExtension(
  background: Color(0xFF161616),
  accent: Color(0xFFED4CA5),
  mainText: Color(0xFFEBEBEB),
  decrease: Color(0xFFFF6467),
  decreaseBg: Color(0xFF5A2A2A),
  decreaseAmount: Color(0xFFFF6467),
  increase: Color(0xFF05DF72),
  increaseBg: Color(0xFF1B5E3A),
  increaseAmount: Color(0xFF05DF72),
  memo: Color(0xFF9E9E9E),
  memoBg: Color(0xFF424242),
  sectionBg: Color(0xFF222222),
  inputBg: Color(0xFF333333),
);

extension AppColorsExt on BuildContext {
  AppColorsExtension get appColors => Theme.of(this).extension<AppColorsExtension>()!;
}

// Keep a temporary wrapper to avoid complete break if missed.
class AppColors {
  static const background = Color(0xFFFFFBF0);
  static const accent = Color(0xFFED4CA5);
  static const mainText = Color(0xFF4A4A4A);
  static const decrease = Color(0xFFFF6467);
  static const decreaseBg = Color(0xFFFFE2E2);
  static const decreaseAmount = Color(0xFFC10007);
  static const increase = Color(0xFF05DF72);
  static const increaseBg = Color(0xFFDBFCE7);
  static const increaseAmount = Color(0xFF008236);
  static const memo = Color(0xFF757575);
  static const memoBg = Color(0xFFE0E0E0);
  static const sectionBg = Color(0xFFFFF2D9);
}
