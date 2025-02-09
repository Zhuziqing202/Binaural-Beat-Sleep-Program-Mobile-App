import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _targetSleepHoursKey = 'targetSleepHours';
  static const String _targetWakeTimeKey = 'targetWakeTime';
  static const String _enableSleepReminderKey = 'enableSleepReminder';
  static const String _enableWakeReminderKey = 'enableWakeReminder';
  static const String _enableWeeklyReportKey = 'enableWeeklyReport';

  static final SettingsService instance = SettingsService._init();
  SharedPreferences? _prefs;
  bool _useDefaultSettings = false;

  SettingsService._init();

  Future<void> init() async {
    if (_prefs != null) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _useDefaultSettings = false;
    } catch (e) {
      debugPrint('SharedPreferences 初始化失败，将使用默认设置: $e');
      _useDefaultSettings = true;
      // 不抛出异常，而是继续使用默认设置
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (_useDefaultSettings) {
      debugPrint('使用默认设置模式，设置将不会被保存');
      return;
    }

    try {
      if (_prefs == null) await init();
      if (_prefs == null) return; // 如果仍然无法初始化，直接返回

      await _prefs!.setDouble(_targetSleepHoursKey, settings.targetSleepHours);
      await _prefs!.setString(_targetWakeTimeKey, settings.targetWakeTime);
      await _prefs!
          .setBool(_enableSleepReminderKey, settings.enableSleepReminder);
      await _prefs!
          .setBool(_enableWakeReminderKey, settings.enableWakeReminder);
      await _prefs!
          .setBool(_enableWeeklyReportKey, settings.enableWeeklyReport);
    } catch (e) {
      debugPrint('保存设置失败，将使用当前设置: $e');
    }
  }

  AppSettings loadSettings() {
    if (_useDefaultSettings || _prefs == null) {
      debugPrint('使用默认设置');
      return _getDefaultSettings();
    }

    try {
      return AppSettings(
        targetSleepHours: _prefs!.getDouble(_targetSleepHoursKey) ?? 8.0,
        targetWakeTime: _prefs!.getString(_targetWakeTimeKey) ?? '06:30',
        enableSleepReminder: _prefs!.getBool(_enableSleepReminderKey) ?? true,
        enableWakeReminder: _prefs!.getBool(_enableWakeReminderKey) ?? true,
        enableWeeklyReport: _prefs!.getBool(_enableWeeklyReportKey) ?? true,
      );
    } catch (e) {
      debugPrint('加载设置失败，使用默认设置: $e');
      return _getDefaultSettings();
    }
  }

  AppSettings _getDefaultSettings() {
    return AppSettings(
      targetSleepHours: 8.0,
      targetWakeTime: '06:30',
      enableSleepReminder: true,
      enableWakeReminder: true,
      enableWeeklyReport: true,
    );
  }
}
