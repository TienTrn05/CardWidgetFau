import 'package:flutter/material.dart';
import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'router/app_router.dart';

class CarWidgetApp extends StatelessWidget {
  const CarWidgetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CarWidget',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    builder: (context, child) => ValueListenableBuilder<bool>(
      valueListenable: LocalStateStore.instance.saveError,
      builder: (context, failed, _) {
        if (!failed) return child!;
        return Column(
          children: [
            Material(
              color: AppColors.surface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Could not save changes.')),
                      TextButton(
                        onPressed: LocalStateStore.instance.flush,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: child!),
          ],
        );
      },
    ),
    home: const AppRouter(),
  );
}
