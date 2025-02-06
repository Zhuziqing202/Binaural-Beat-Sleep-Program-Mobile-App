import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pink_sleep/screens/home_screen.dart';
import 'package:pink_sleep/theme/app_theme.dart';
import 'package:pink_sleep/services/settings_service.dart';
import 'package:pink_sleep/services/notification_service.dart';
import 'package:pink_sleep/services/alarm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 初始化时区数据
  tz.initializeTimeZones();

  try {
    // 初始化服务
    await Future.wait([
      SettingsService.instance.init(),
      NotificationService.instance.init(),
      AlarmService.instance.init(),
    ]);
    
    // 请求必要权限
    await AlarmService.instance.requestPermissions();
    
    runApp(const App());
  } catch (e) {
    print('初始化错误: $e');
    // 即使发生错误也要运行应用
    runApp(const App());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pink Sleep',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
