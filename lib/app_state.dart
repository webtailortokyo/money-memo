import 'package:flutter/material.dart';
import 'constants.dart';

// タイトル変更を即時反映するための notifier
final appTitleNotifier = ValueNotifier<String>(AppStrings.appTitle);
