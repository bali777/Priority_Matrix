import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/theme.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
  await Hive.openBox('settingsBox');

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: PriorityMatrixApp()));
}

class PriorityMatrixApp extends StatelessWidget {
  const PriorityMatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priority Matrix',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: buildDarkTheme(),
      home: const HomePage(),
    );
  }
}
