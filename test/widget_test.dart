import 'package:carwidget/main.dart';
import 'package:carwidget/features/premium/presentation/pages/buy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(find.byType(SwitchListTile), findsNWidgets(2));

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();
    expect(find.text('Cards'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );
  });
}
