import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';
import 'app_flow.dart';

class CarWidgetApp extends StatelessWidget {
  const CarWidgetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CarWidget',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lime,
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      ),
    ),
    home: const AppFlow(),
  );
}
