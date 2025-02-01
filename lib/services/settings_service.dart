import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _targetSleepHoursKey = 'targetSleepHours';
  static const String _targetSleepTimeKey = 'targetSleepTime';
  static const String _targetWakeTimeKey = 'targetWakeTime';
  static const String _enableSleepReminderKey = 'enableSleepReminder';
  static const String _enableWakeReminderKey = 'enableWakeReminder';
  static const String _enableWeeklyReportKey = 'enableWeeklyReport';
  static const String _enableHealthSyncKey = 'enableHealthSync';

  static final SettingsService instance = SettingsService._init();
  late SharedPreferences _prefs;

  SettingsService._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setDouble(_targetSleepHoursKey, settings.targetSleepHours);
    await _prefs.setString(_targetSleepTimeKey, settings.targetSleepTime);
    await _prefs.setString(_targetWakeTimeKey, settings.targetWakeTime);
    await _prefs.setBool(_enableSleepReminderKey, settings.enableSleepReminder);
    await _prefs.setBool(_enableWakeReminderKey, settings.enableWakeReminder);
    await _prefs.setBool(_enableWeeklyReportKey, settings.enableWeeklyReport);
    await _prefs.setBool(_enableHealthSyncKey, settings.enableHealthSync);
  }

  AppSettings loadSettings() {
    return AppSettings(
      targetSleepHours: _prefs.getDouble(_targetSleepHoursKey) ?? 8.0,
      targetSleepTime: _prefs.getString(_targetSleepTimeKey) ?? '22:30',
      targetWakeTime: _prefs.getString(_targetWakeTimeKey) ?? '06:30',
      enableSleepReminder: _prefs.getBool(_enableSleepReminderKey) ?? true,
      enableWakeReminder: _prefs.getBool(_enableWakeReminderKey) ?? true,
      enableWeeklyReport: _prefs.getBool(_enableWeeklyReportKey) ?? true,
      enableHealthSync: _prefs.getBool(_enableHealthSyncKey) ?? true,
    );
  }

  Future<void> updateTargetSleepHours(double hours) async {
    await _prefs.setDouble(_targetSleepHoursKey, hours);
  }

  Future<void> updateTargetSleepTime(String time) async {
    await _prefs.setString(_targetSleepTimeKey, time);
  }

  Future<void> updateTargetWakeTime(String time) async {
    await _prefs.setString(_targetWakeTimeKey, time);
  }

  Future<void> updateSleepReminder(bool enable) async {
    await _prefs.setBool(_enableSleepReminderKey, enable);
  }

  Future<void> updateWakeReminder(bool enable) async {
    await _prefs.setBool(_enableWakeReminderKey, enable);
  }

  Future<void> updateWeeklyReport(bool enable) async {
    await _prefs.setBool(_enableWeeklyReportKey, enable);
  }

  Future<void> updateHealthSync(bool enable) async {
    await _prefs.setBool(_enableHealthSyncKey, enable);
  }
} 