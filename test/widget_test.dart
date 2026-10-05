import 'package:carwidget/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading, buy and main navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CarWidgetApp());
    expect(find.text('Đang chuẩn bị không gian của bạn'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Khám phá ứng dụng'), findsOneWidget);

    await tester.ensureVisible(find.text('Khám phá ứng dụng'));
    await tester.tap(find.text('Khám phá ứng dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Widgets'), findsOneWidget);

    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    expect(find.text('Sounds'), findsOneWidget);

    await tester.tap(find.text('Card'));
    await tester.pumpAndSettle();
    expect(find.text('Cards'), findsOneWidget);

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(2));

    await tester.tap(find.text('Thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đóng cài đặt'));
    await tester.pumpAndSettle();
    expect(find.text('Cards'), findsOneWidget);
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );
  });
}
