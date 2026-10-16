import 'package:flutter/material.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart';
import 'app/theme/app_theme.dart';
import 'app/car_widget_app.dart';

export 'app/car_widget_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalStateStore.instance.initialize();
    initializeMyWidgetsStorage();
    WidgetsBinding.instance.addObserver(LocalStateStore.instance);
    runApp(const CarWidgetApp());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load saved data. Please try again.'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: main, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
