import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../screens/alarm_screen.dart';
import 'dart:convert';

final navigatorKey = GlobalKey<NavigatorState>();

class AlarmInfo {
  final DateTime scheduledTime;
  final bool isSmartWake;
  final int? smartWakeWindow;
  final int snoozeCount;

  AlarmInfo({
    required this.scheduledTime,
    required this.isSmartWake,
    this.smartWakeWindow,
    this.snoozeCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'scheduledTime': scheduledTime.toIso8601String(),
    'isSmartWake': isSmartWake,
    'smartWakeWindow': smartWakeWindow,
    'snoozeCount': snoozeCount,
  };

  factory AlarmInfo.fromJson(Map<String, dynamic> json) {
    try {
      return AlarmInfo(
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
        isSmartWake: json['isSmartWake'] as bool,
        smartWakeWindow: json['smartWakeWindow'] as int?,
        snoozeCount: (json['snoozeCount'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      print('Error parsing AlarmInfo: $e');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'AlarmInfo(scheduledTime: $scheduledTime, isSmartWake: $isSmartWake, smartWakeWindow: $smartWakeWindow, snoozeCount: $snoozeCount)';
  }
}

class AlarmService {
  static final AlarmService instance = AlarmService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  AlarmInfo? _currentAlarm;
  static const String _alarmInfoKey = 'alarm_info';
  static const int maxSnoozeCount = 3;
  static const int snoozeDurationMinutes = 5;
  
  AlarmService._init();

  Future<void> init() async {
    final androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'alarm_category',
          actions: [
            DarwinNotificationAction.plain(
              'snooze',
              '再睡5分钟',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'stop',
              '停止闹钟',
              options: {
                DarwinNotificationActionOption.destructive,
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: {
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        )
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _handleNotificationResponse,
    );

    // 恢复保存的闹钟设置
    await _restoreAlarmSettings();
  }

  static void _handleNotificationResponse(NotificationResponse response) async {
    if (response.payload != 'alarm') return;

    if (response.actionId == 'snooze') {
      await instance.snoozeAlarm();
    } else if (response.actionId == 'stop') {
      await instance.cancelAlarm();
    } else {
      // 打开闹钟响铃界面
      instance._showAlarmScreen();
    }
  }

  void _showAlarmScreen() {
    if (navigatorKey.currentContext != null) {
      // 如果当前在应用内，直接跳转
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const AlarmScreen(),
        ),
      );
    }
  }

  Future<void> _showNotification() async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Channel',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        const AndroidNotificationAction('snooze', '再睡5分钟'),
        const AndroidNotificationAction('stop', '停止闹钟'),
      ],
    );

    final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'alarm_category',
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      0,
      '闹钟',
      '该起床啦！新的一天开始了！',
      platformChannelSpecifics,
      payload: 'alarm',
    );

    // 如果在应用内，直接跳转到闹钟界面
    _showAlarmScreen();
  }

  Future<bool> requestPermissions() async {
    // 请求通知权限
    final platform = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (platform != null) {
      await platform.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
    }

    // 请求所有必要权限
    final permissions = await Future.wait([
      Permission.notification.request(),
      Permission.scheduleExactAlarm.request(),
      Permission.systemAlertWindow.request(),
    ]);

    // 检查权限状态
    return permissions.every((status) => status.isGranted);
  }

  Future<void> _saveAlarmSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentAlarm != null) {
        final jsonString = jsonEncode(_currentAlarm!.toJson());
        print('Saving alarm settings: $jsonString');
        await prefs.setString(_alarmInfoKey, jsonString);
      } else {
        await prefs.remove(_alarmInfoKey);
      }
    } catch (e) {
      print('Error saving alarm settings: $e');
    }
  }

  Future<void> _restoreAlarmSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmJson = prefs.getString(_alarmInfoKey);
      print('Restored alarm json: $alarmJson');
      
      if (alarmJson != null) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(alarmJson);
          _currentAlarm = AlarmInfo.fromJson(jsonMap);
          
          // 如果闹钟时间已过，则清除设置
          if (_currentAlarm!.scheduledTime.isBefore(DateTime.now())) {
            print('Alarm time has passed, clearing settings');
            await cancelAlarm();
          } else {
            print('Restoring alarm for: ${_currentAlarm!.scheduledTime}');
            // 重新设置闹钟，但保持原有的 snoozeCount
            final snoozeCount = _currentAlarm!.snoozeCount;
            await setAlarm(
              wakeTime: _currentAlarm!.scheduledTime,
              isSmartWake: _currentAlarm!.isSmartWake,
              smartWakeWindow: _currentAlarm!.smartWakeWindow,
            );
            _currentAlarm = AlarmInfo(
              scheduledTime: _currentAlarm!.scheduledTime,
              isSmartWake: _currentAlarm!.isSmartWake,
              smartWakeWindow: _currentAlarm!.smartWakeWindow,
              snoozeCount: snoozeCount,
            );
            await _saveAlarmSettings();
          }
        } catch (e) {
          print('Error parsing alarm json: $e');
          await prefs.remove(_alarmInfoKey);
        }
      }
    } catch (e) {
      print('Error restoring alarm settings: $e');
    }
  }

  Future<void> setAlarm({
    required DateTime wakeTime,
    bool isSmartWake = false,
    int? smartWakeWindow,
  }) async {
    try {
      DateTime actualWakeTime = wakeTime;
      
      if (isSmartWake && smartWakeWindow != null) {
        final earliestWakeTime = wakeTime.subtract(Duration(minutes: smartWakeWindow));
        final random = Random();
        final randomMinutes = random.nextInt(smartWakeWindow);
        actualWakeTime = earliestWakeTime.add(Duration(minutes: randomMinutes));
      }

      // 先取消现有的闹钟
      await cancelAlarm();

      _currentAlarm = AlarmInfo(
        scheduledTime: wakeTime,
        isSmartWake: isSmartWake,
        smartWakeWindow: smartWakeWindow,
      );

      final scheduledDate = tz.TZDateTime.from(actualWakeTime, tz.local);
      
      // 确保闹钟时间在未来
      if (scheduledDate.isBefore(DateTime.now())) {
        throw Exception('Cannot set alarm for past time');
      }

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Channel',
        channelDescription: 'Channel for alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );

      final iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'alarm_category',
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.zonedSchedule(
        0,
        '闹钟',
        '该起床啦！',
        scheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'alarm',
      );

      // 保存闹钟设置
      await _saveAlarmSettings();

      print('Alarm scheduled for: ${actualWakeTime.toString()}');
    } catch (e) {
      print('Error setting alarm: $e');
      rethrow;
    }
  }

  Future<void> snoozeAlarm() async {
    if (_currentAlarm == null || 
        _currentAlarm!.snoozeCount >= maxSnoozeCount) {
      await cancelAlarm();
      return;
    }

    final newWakeTime = DateTime.now().add(
      const Duration(minutes: snoozeDurationMinutes)
    );

    _currentAlarm = AlarmInfo(
      scheduledTime: newWakeTime,
      isSmartWake: false,
      snoozeCount: _currentAlarm!.snoozeCount + 1,
    );

    await setAlarm(wakeTime: newWakeTime);
  }

  Future<void> cancelAlarm() async {
    await _notifications.cancel(0);
    _currentAlarm = null;
    await _saveAlarmSettings();
  }

  Future<bool> checkPendingAlarm() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.any((notification) => notification.id == 0);
  }

  Future<AlarmInfo?> getAlarmInfo() async {
    return _currentAlarm;
  }
} 