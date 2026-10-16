import 'package:carwidget/app/router/home_shell.dart';
import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/settings/data/settings_content.dart';
import 'package:carwidget/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Settings animates and preserves the selected sound on return', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const identityChannel = MethodChannel('carwidget/device_identity');
    const iconChannel = MethodChannel('carwidget/app_icon_preference');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(identityChannel, (_) async => 'test-id');
    messenger.setMockMethodCallHandler(iconChannel, (_) async => 0);
    addTearDown(() {
      messenger.setMockMethodCallHandler(identityChannel, null);
      messenger.setMockMethodCallHandler(iconChannel, null);
    });

    await SettingsContent.load();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const HomeShell()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a sound').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Car Horn'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.byType(SettingsPage)).dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(SettingsPage)).dx, closeTo(0, .1));
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(find.byType(SettingsPage)).dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.text('Sounds'), findsOneWidget);
    expect(find.text('Car Horn'), findsOneWidget);
    expect(find.text('Add a sound'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
