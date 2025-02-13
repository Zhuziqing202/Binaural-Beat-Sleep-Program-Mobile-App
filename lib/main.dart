import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pink_sleep/app.dart';
import 'package:pink_sleep/services/settings_service.dart';
import 'package:pink_sleep/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化服务
    await SettingsService.instance.init();
    
    // 最后初始化音频服务
    await AudioService.instance.initializePlayer();
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('应用初始化失败: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const App(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8FB1),
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
