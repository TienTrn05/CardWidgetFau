import 'package:carwidget/main.dart';
import 'package:carwidget/features/Prenium/presentation/pages/buy_screen.dart';
import 'package:carwidget/features/settings/data/app_icon_preference.dart';
import 'package:carwidget/features/settings/data/settings_content.dart';
import 'package:carwidget/features/settings/data/widget_tutorial_content.dart';
import 'package:carwidget/features/settings/presentation/pages/settings_page.dart';
import 'package:carwidget/features/settings/presentation/pages/widget_tutorial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await SettingsContent.load();
    await WidgetTutorialContent.load();
  });

  test('tutorial images are bundled with the app', () async {
    final content = await WidgetTutorialContent.load();
    final assets = content.tabs
        .expand((tab) => tab.steps)
        .expand((step) => step.images)
        .map((image) => image.asset)
        .whereType<String>();
    expect(assets, isNotEmpty);
    for (final asset in assets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  testWidgets('widget tutorial tabs and steps fit iPhone safe areas', (
    tester,
  ) async {
    const topInset = 59.0;
    const bottomInset = 34.0;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final screenSize in [const Size(320, 568), const Size(393, 852)]) {
      tester.view.physicalSize = screenSize;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: screenSize,
              padding: const EdgeInsets.only(
                top: topInset,
                bottom: bottomInset,
              ),
            ),
            child: WidgetTutorialPage(key: ValueKey(screenSize.height)),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Steps'), findsOneWidget);
      expect(find.text('CarPlay Sounds'), findsOneWidget);
      expect(find.text('Home Sounds'), findsOneWidget);
      expect(find.byKey(const ValueKey('tutorial-image-1-1')), findsOneWidget);
      expect(tester.getTopLeft(find.text('Steps')).dy, greaterThan(topInset));

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tutorial-image-3-1')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getBottomRight(find.byKey(const ValueKey('tutorial-image-3-1')))
            .dy,
        lessThan(screenSize.height - bottomInset),
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tutorial-image-6-2')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const ValueKey('tutorial-image-6-2')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tutorial-note')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.textContaining('To set up a disconnect sound'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Home Sounds'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Open the Shortcuts app.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tutorial-image-4-1')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('tutorial-image-4-1')))
            .aspectRatio,
        closeTo(828 / 864, 0.001),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tutorial-image-6-2')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byKey(const ValueKey('tutorial-image-6-2')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('tutorial-note')),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('when you leave home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('icon choice persists and tutorial guide opens', (tester) async {
    const channel = MethodChannel('carwidget/app_icon_preference');
    var savedIcon = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getSelectedIcon') return savedIcon;
          if (call.method == 'setSelectedIcon') {
            savedIcon = call.arguments as int;
          }
          return null;
        });
    addTearDown(() {
      AppIconPreference.selected.value = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsPage(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change icon'));
    await tester.pumpAndSettle();
    expect(find.text('Change icon'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('app-icon-1')));
    await tester.pump();
    expect(savedIcon, 1);
    expect(AppIconPreference.selected.value, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video Tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('How to Add Widget to CarPlay?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings displays and copies the installation ID', (
    tester,
  ) async {
    const channel = MethodChannel('carwidget/device_identity');
    const id = '6BA79EF1-0A1A-4313-9EA0-67C5973036FE';
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getOrCreateId');
          return id;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsPage(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Device ID'));
    await tester.pumpAndSettle();
    expect(find.text(id), findsOneWidget);

    await tester.tap(find.text('Device ID'));
    await tester.pump();
    expect(copiedText, id);
  });

  testWidgets('share app opens the platform share sheet', (tester) async {
    const channel = MethodChannel('carwidget/share_app');
    var opened = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'share');
          opened = true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsPage(onBack: () {})),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Share App'));
    await tester.tap(find.text('Share App'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('settings cards remain usable with iPhone safe areas', (
    tester,
  ) async {
    const topInset = 59.0;
    const bottomInset = 34.0;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final screenSize in [const Size(320, 568), const Size(393, 852)]) {
      tester.view.physicalSize = screenSize;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: screenSize,
              padding: const EdgeInsets.only(
                top: topInset,
                bottom: bottomInset,
              ),
            ),
            child: SafeArea(child: SettingsPage(onBack: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.byTooltip('Back')).dy,
        greaterThanOrEqualTo(topInset),
      );
      await tester.ensureVisible(find.text('Device ID'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomRight(find.text('Device ID')).dy,
        lessThan(screenSize.height - bottomInset),
      );
    }
  });

  testWidgets('paywall content clears iPhone safe areas', (tester) async {
    const screenSize = Size(393, 852);
    const topInset = 59.0;
    const bottomInset = 34.0;
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: screenSize,
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
          ),
          child: BuyScreen(onContinue: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.byType(PageView)).dy, 0);
    expect(
      tester.getTopLeft(find.byTooltip('Explore app')).dy,
      greaterThanOrEqualTo(topInset),
    );
    expect(
      tester.getTopLeft(find.text('Enable All Nav Features')).dy,
      greaterThan(tester.getBottomRight(find.byTooltip('Explore app')).dy),
    );
    expect(
      tester.getBottomRight(find.text('Privacy Policy')).dy,
      lessThan(screenSize.height - bottomInset),
    );
  });

  testWidgets('paywall details stay at the bottom as the hero grows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<(double, double)> measureAtHeight(
      double height, {
      double width = 390,
    }) async {
      tester.view.physicalSize = Size(width, height);
      await tester.pumpWidget(MaterialApp(home: BuyScreen(onContinue: () {})));
      await tester.pump();
      expect(tester.takeException(), isNull);
      return (
        tester.getSize(find.byType(PageView)).height,
        height - tester.getBottomRight(find.text('Privacy Policy')).dy,
      );
    }

    final (compactHero, compactBottomInset) = await measureAtHeight(
      568,
      width: 320,
    );
    final (shortHero, shortBottomInset) = await measureAtHeight(640);
    final (tallHero, tallBottomInset) = await measureAtHeight(900);

    expect(compactHero, greaterThan(0));
    expect(shortHero, greaterThan(0));
    expect(tallHero, greaterThan(shortHero));
    expect(compactBottomInset, closeTo(shortBottomInset, 1));
    expect(tallBottomInset, closeTo(shortBottomInset, 1));
  });

  testWidgets('loading, buy and main navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CarWidgetApp());
    expect(find.text('Car Widgets'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Enable All Nav Features'), findsOneWidget);
    expect(find.text('Start Free Trial'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Billing unavailable'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Explore app'));
    await tester.pumpAndSettle();
    expect(find.text('Widgets'), findsOneWidget);

    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    expect(find.text('Sounds'), findsOneWidget);

    await tester.tap(find.text('Card'));
    await tester.pumpAndSettle();
    expect(find.text('Cards'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('GUIDE'), findsOneWidget);
    expect(find.text('ADVANCE'), findsOneWidget);
    expect(find.text('Restore Purchase'), findsOneWidget);
    expect(find.text('Change icon'), findsOneWidget);
    expect(find.text('Widget Tutorial'), findsOneWidget);
    expect(find.text('Video Tutorial'), findsOneWidget);
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('Send a Feedback'), findsOneWidget);
    expect(find.text('Term & Privacy'), findsOneWidget);
    expect(find.text('Device ID'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);

    await tester.tap(find.text('Widget Tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Steps'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore Purchase'));
    await tester.pumpAndSettle();
    expect(find.text('Restore Purchase is not available yet.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Cards'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Restore Purchase'), findsOneWidget);
  });
}
