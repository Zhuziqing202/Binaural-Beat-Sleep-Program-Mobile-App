import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pink_sleep/app.dart';
import 'package:pink_sleep/services/notification_service.dart';
import 'package:pink_sleep/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务
  await Future.wait([
    SettingsService.instance.init(),
    NotificationService.instance.initialize(),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 在这里添加你的 BlocProvider
      ],
      child: const App(),
    );
  }
}
