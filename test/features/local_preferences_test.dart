import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/cards/presentation/pages/my_car_page.dart';
import 'package:carwidget/features/startup_sounds/presentation/pages/sounds_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = LocalStateStore.instance;

  testWidgets('sound choices are stored and restore after page recreation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final page = MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: SoundsPage()),
    );
    await tester.pumpWidget(page);
    for (final sound in ['Car Horn', 'Calling', 'Thud']) {
      await tester.tap(find.text('Add a sound').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(sound));
      await tester.tap(find.text(sound));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page);
    await tester.pumpAndSettle();
    expect(find.text('Car Horn'), findsOneWidget);
    expect(find.text('Calling'), findsOneWidget);
    expect(find.text('Thud'), findsOneWidget);
    expect(store.readMap('sounds'), {
      'connect': 'Car Horn',
      'disconnect': 'Calling',
      'home': 'Thud',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding and removing a car persists, including an empty garage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    store.setValue('garage', {'cars': [], 'selectedIndex': 0});
    final page = MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: MyCarPage()),
    );
    await tester.pumpWidget(page);
    await tester.tap(find.text('Add Car'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abarth'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUV'));
    await tester.pumpAndSettle();
    final year = DateTime.now().year.toString();
    await tester.tap(find.text(year));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page);
    await tester.pumpAndSettle();
    expect(find.text('Abarth'), findsOneWidget);
    expect(find.text('SUV $year'), findsOneWidget);
    expect(store.readMap('garage')!['cars'], [
      {'brand': 'Abarth', 'bodyStyle': 'SUV', 'year': year},
    ]);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page);
    await tester.pumpAndSettle();
    expect(find.text('Your garage is empty'), findsOneWidget);
    expect(store.readMap('garage')!['cars'], isEmpty);
    expect(tester.takeException(), isNull);
  });
}
