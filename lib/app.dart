import 'package:flutter/material.dart';
import 'logic/game_controller.dart';
import 'screens/home_screen.dart';
import 'theme/whist_theme.dart';

class WhistApp extends StatefulWidget {
  const WhistApp({super.key, this.gameController});

  final GameController? gameController;

  @override
  State<WhistApp> createState() => _WhistAppState();
}

class _WhistAppState extends State<WhistApp> {
  late final GameController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.gameController ?? GameController();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whist',
      debugShowCheckedModeBanner: false,
      theme: buildWhistTheme(),
      home: HomeScreen(controller: controller),
    );
  }
}
