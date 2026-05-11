import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants.dart';
import '../theme.dart';
import '../utils/notification_manager.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late bool _isEnabled;
  late String _frequency;
  late TimeOfDay _time;
  late int _dayOfWeek;
  late int _dayOfMonth;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(HiveConstants.settingsBoxName);
    _isEnabled = box.get(HiveConstants.keyPeriodicNotificationEnabled, defaultValue: false) as bool;
    _frequency = box.get(HiveConstants.keyPeriodicNotificationFrequency, defaultValue: 'daily') as String;
    
    final hour = box.get(HiveConstants.keyPeriodicNotificationTimeHour, defaultValue: 20) as int;
    final minute = box.get(HiveConstants.keyPeriodicNotificationTimeMinute, defaultValue: 0) as int;
    _time = TimeOfDay(hour: hour, minute: minute);
    
    _dayOfWeek = box.get(HiveConstants.keyPeriodicNotificationDayOfWeek, defaultValue: 1) as int;
    _dayOfMonth = box.get(HiveConstants.keyPeriodicNotificationDayOfMonth, defaultValue: 1) as int;
  }

  Future<void> _saveSettings() async {
    final box = Hive.box(HiveConstants.settingsBoxName);
    await box.put(HiveConstants.keyPeriodicNotificationEnabled, _isEnabled);
    await box.put(HiveConstants.keyPeriodicNotificationFrequency, _frequency);
    await box.put(HiveConstants.keyPeriodicNotificationTimeHour, _time.hour);
    await box.put(HiveConstants.keyPeriodicNotificationTimeMinute, _time.minute);
    await box.put(HiveConstants.keyPeriodicNotificationDayOfWeek, _dayOfWeek);
    await box.put(HiveConstants.keyPeriodicNotificationDayOfMonth, _dayOfMonth);

    if (_isEnabled) {
      await NotificationManager.requestPermissions();
    }
    await NotificationManager.schedulePeriodicNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          backgroundColor: context.appColors.background,
          elevation: 0,
          leading: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.arrow_back_ios, color: context.appColors.accent),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            AppStrings.settingsNotificationEdit,
            style: TextStyle(
              color: context.appColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SwitchListTile(
              title: Text(
                '通知を有効にする',
                style: TextStyle(color: context.appColors.mainText, fontWeight: FontWeight.bold),
              ),
              value: _isEnabled,
              activeColor: context.appColors.accent,
              onChanged: (bool value) {
                setState(() {
                  _isEnabled = value;
                });
                _saveSettings();
              },
            ),
            if (_isEnabled) ...[
              const Divider(height: 32),
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
                selected: {_frequency},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _frequency = newSelection.first;
                  });
                  _saveSettings();
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
              if (_frequency == 'weekly') ...[
                Text(AppStrings.setupNotificationDayOfWeek, style: TextStyle(color: context.appColors.mainText)),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: _dayOfWeek,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('月曜日')),
                    DropdownMenuItem(value: 2, child: Text('火曜日')),
                    DropdownMenuItem(value: 3, child: Text('水曜日')),
                    DropdownMenuItem(value: 4, child: Text('木曜日')),
                    DropdownMenuItem(value: 5, child: Text('金曜日')),
                    DropdownMenuItem(value: 6, child: Text('土曜日')),
                    DropdownMenuItem(value: 7, child: Text('日曜日')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _dayOfWeek = val);
                      _saveSettings();
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
              if (_frequency == 'monthly') ...[
                Text(AppStrings.setupNotificationDayOfMonth, style: TextStyle(color: context.appColors.mainText)),
                const SizedBox(height: 8),
                DropdownButton<int>(
                  value: _dayOfMonth,
                  isExpanded: true,
                  items: List.generate(28, (index) {
                    return DropdownMenuItem(value: index + 1, child: Text('${index + 1}日'));
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _dayOfMonth = val);
                      _saveSettings();
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
              Text(AppStrings.setupNotificationTime, style: TextStyle(color: context.appColors.mainText)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appColors.mainText),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newTime = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (newTime != null) {
                      setState(() => _time = newTime);
                      _saveSettings();
                    }
                  },
                  child: const Text('変更'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
