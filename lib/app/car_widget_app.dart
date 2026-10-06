import 'package:flutter/material.dart';
import 'package:carwidget/app/theme/app_theme.dart';
import 'router/app_router.dart';

class CarWidgetApp extends StatelessWidget {
  const CarWidgetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CarWidget',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const AppRouter(),
  );
}
