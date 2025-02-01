import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pink_sleep/screens/home_screen.dart';
import 'package:pink_sleep/theme/app_theme.dart';
import 'package:pink_sleep/services/settings_service.dart';
import 'package:pink_sleep/services/notification_service.dart';
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

  // 初始化服务
  await SettingsService.instance.init();
  await NotificationService.instance.init();
  
  runApp(const App());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pink Sleep',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
