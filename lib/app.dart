import 'package:flutter/material.dart';
import 'logic/game_controller.dart';
import 'screens/home_screen.dart';

class WhistApp extends StatefulWidget {
  const WhistApp({super.key});

  @override
  State<WhistApp> createState() => _WhistAppState();
}

class _WhistAppState extends State<WhistApp> {
  final GameController controller = GameController();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = ColorScheme.fromSeed(seedColor: const Color(0xFF295F57));
    final dark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF80C9B7),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Whist',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: light,
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: dark),
      home: HomeScreen(controller: controller),
    );
  }
}
