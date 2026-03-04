import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/money_entry.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(MoneyEntryAdapter());
  await Hive.openBox<MoneyEntry>('moneyBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おかねメモ',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Rounded Mplus 1c',
      ),
      home: const MainPage(),
    );
  }
}
