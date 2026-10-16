import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/cards/presentation/pages/driving_mode_page.dart';
import 'package:carwidget/features/cards/presentation/pages/my_car_page.dart';
import 'package:carwidget/features/cards/presentation/widgets/driving_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _topInset = 59.0;
const _bottomInset = 34.0;

Future<void> _pumpDashboard(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: _topInset, bottom: _bottomInset),
          textScaler: TextScaler.linear(textScale),
        ),
        child: const DrivingModePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(430, 932),
    const Size(844, 390),
  ]) {
    for (final textScale in [1.0, 1.8]) {
      testWidgets('dashboard fits $size at text scale $textScale', (
        tester,
      ) async {
        await _pumpDashboard(tester, size, textScale: textScale);

        final close = find.byTooltip('Close Driving Mode');
        final dock = find.byKey(const ValueKey('driving-dock'));
        final map = find.byKey(const ValueKey('driving-map'));
        final music = find.byKey(
          const ValueKey('driving-music'),
          skipOffstage: false,
        );
        final info = find.byKey(
          const ValueKey('driving-info'),
          skipOffstage: false,
        );

        expect(find.byType(DrivingMapView), findsOneWidget);
        expect(tester.getTopLeft(close).dy, greaterThanOrEqualTo(_topInset));
        expect(
          tester.getBottomRight(dock).dy,
          lessThanOrEqualTo(size.height - _bottomInset),
        );
        expect(tester.getSize(map).height, greaterThanOrEqualTo(200));
        expect(
          tester.getBottomRight(map).dy,
          lessThan(tester.getTopLeft(music).dy),
        );
        expect(
          tester.getBottomRight(music).dy,
          lessThan(tester.getTopLeft(info).dy),
        );
        expect(tester.takeException(), isNull);

        final initialInfoTop = tester.getTopLeft(info).dy;
        final initialDockTop = tester.getTopLeft(dock).dy;
        await tester.drag(
          find.byKey(const ValueKey('driving-dashboard-list')),
          const Offset(0, -1600),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(info).dy, lessThan(initialInfoTop));
        expect(tester.getTopLeft(dock).dy, initialDockTop);
        expect(
          tester.getBottomRight(info).dy,
          lessThan(tester.getTopLeft(dock).dy),
        );
        expect(
          tester.getTopLeft(info).dy,
          lessThan(tester.getTopLeft(dock).dy),
        );
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Apps'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(GridView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(find.text('Weather'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('map expansion and apps return to the dashboard', (tester) async {
    await _pumpDashboard(tester, const Size(393, 852));

    await tester.tap(find.byTooltip('Expand map'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close map'), findsOneWidget);
    expect(find.byKey(const ValueKey('driving-dock')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Close map'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.byType(DrivingMapView), findsNothing);

    await tester.tap(find.byTooltip('Close apps'));
    await tester.pumpAndSettle();
    expect(find.byType(DrivingMapView), findsOneWidget);

    await tester.tap(find.byTooltip('Maps'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close map'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Music dock reveals playback controls on a compact screen', (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(320, 568));
    await tester.tap(find.byTooltip('Apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Music'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(find.text('Playing'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Not Playing'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Driving Mode opens and closes from My Car', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: MyCarPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go Now'));
    await tester.pumpAndSettle();
    expect(find.byType(DrivingModePage), findsOneWidget);
    await tester.tap(find.byTooltip('Close Driving Mode'));
    await tester.pumpAndSettle();
    expect(find.text('My Car'), findsOneWidget);
    expect(find.byType(DrivingModePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
