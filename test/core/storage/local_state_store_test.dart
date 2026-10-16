import 'dart:convert';
import 'dart:io';

import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/widget_type.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/my_widgets/data/widget_collection_snapshot.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late LocalStateStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('carwidget_storage_test_');
    store = LocalStateStore();
    await store.initialize(directory: root);
  });

  tearDown(() async {
    await store.flush();
    await root.delete(recursive: true);
  });

  test('platform support directory is used for persistent storage', () async {
    const channel = MethodChannel('carwidget/local_storage_v1');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getSupportDirectory');
      return root.path;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final nativeStore = LocalStateStore();
    await nativeStore.initialize();
    nativeStore.setValue('sounds', {'connect': 'Car Horn'});
    await nativeStore.flush();
    final reopened = LocalStateStore();
    await reopened.initialize(directory: root);
    expect(reopened.readMap('sounds')?['connect'], 'Car Horn');
  });

  test(
    'latest edits, cleared selections and empty garage survive restart',
    () async {
      store.setValue('sounds', {
        'connect': 'Car Horn',
        'disconnect': 'Thud',
        'home': 'Calling',
      });
      store.setValue('garage', {
        'cars': [
          {'brand': 'Acura', 'bodyStyle': 'SUV', 'year': '2025'},
        ],
        'selectedIndex': 0,
      });
      final writing = store.flush();
      store.setValue('sounds', {
        'connect': null,
        'disconnect': 'Air Horn',
        'home': 'Calling',
      });
      store.setValue('garage', {'cars': [], 'selectedIndex': 0});
      await writing;
      await store.flush();
      final reopened = LocalStateStore();
      await reopened.initialize(directory: root);
      expect(reopened.readMap('sounds'), {
        'connect': null,
        'disconnect': 'Air Horn',
        'home': 'Calling',
      });
      expect(reopened.readMap('garage')?['cars'], isEmpty);
      expect(store.saveError.value, isFalse);
    },
  );

  test(
    'all widget fields, images, layouts and preview order round trip',
    () async {
      final models = [
        for (final type in WidgetType.values)
          SavedWidgetModel(
            id: type.name,
            label: 'Custom label',
            type: type,
            imageBytes: Uint8List.fromList([1, 2, 3]),
            imageAsset: 'assets/images/map.png',
            layoutId: 'saved:${type.name}',
            borderGradientIndex: 2,
            borderOpacity: .4,
            symbol: 'A',
            countryFlagCode: 'PT',
            footballTeamId: 'team',
            synthwaveId: 'synthwave_2',
            affirmationText: 'My custom text',
            affirmationDate: DateTime(2026, 10, 16),
            affirmationTextColorValue: 0xFF123456,
            affirmationBackgroundColorValue: 0xFF654321,
            affirmationEyebrow: 'KEEP GOING',
            affirmationStyleIndex: 3,
            videoName: 'Video',
            videoStartMs: 1400,
            videoDurationMs: 4000,
            videoThumbnail: Uint8List.fromList([4, 5, 6]),
          ),
      ];
      final layout = BrandCarLayout(
        greeting: const WidgetElementPosition(.3, -.2),
        brand: const WidgetElementPosition(.2, .5),
        car: const WidgetElementPosition(-.5, -.1),
        location: const WidgetElementPosition(.7, .8),
        brandScale: 1.4,
        carScale: .8,
        carImageIndex: 3,
        carImageBytes: Uint8List.fromList([7, 8, 9]),
        greetingNickname: 'Driver',
        greetingFontIndex: 2,
        greetingColorValue: 0xFF123456,
        borderGradientIndex: 2,
        borderOpacity: .3,
        borderWidth: 5,
      );
      final snapshot = WidgetCollectionSnapshot(
        widgets: models,
        videos: const [
          SavedWidgetModel(
            id: 'library',
            label: 'Library',
            type: WidgetType.video,
          ),
        ],
        layouts: {'saved:carLogoAndName': layout},
        previewSlots: [models[0], models[1]],
        selectionOrder: [models[1].id, models[0].id],
      );
      store.setValue('widgetCollection', snapshot.toJson(store));
      await store.flush();
      final reopened = LocalStateStore();
      await reopened.initialize(directory: root);
      final restored = WidgetCollectionSnapshot.fromJson(
        reopened.readMap('widgetCollection')!,
        reopened,
      );
      expect(
        restored.widgets.map((value) => value.toJson()).toList(),
        models.map((value) => value.toJson()).toList(),
      );
      expect(restored.videos.single.id, 'library');
      expect(
        restored.layouts['saved:carLogoAndName']!.toJson(),
        layout.toJson(),
      );
      expect(restored.previewSlots.map((value) => value?.id), [
        models[0].id,
        models[1].id,
      ]);
      expect(restored.selectionOrder, [models[1].id, models[0].id]);
    },
  );

  test(
    'video survives picker cache removal and app directory relocation',
    () async {
      final cache = await Directory.systemTemp.createTemp('carwidget_picker_');
      final source = await File(
        '${cache.path}/movie.mov',
      ).writeAsBytes([1, 2, 3, 4]);
      final localPath = await store.importVideo(source.path);
      final relativePath = store.relativeMediaPath(localPath);
      expect(relativePath, startsWith('media/'));
      store.setValue('video', {'path': relativePath});
      await store.flush();
      await cache.delete(recursive: true);
      expect(await File(localPath).readAsBytes(), [1, 2, 3, 4]);
      root = await root.rename('${root.path}_moved');
      final reopened = LocalStateStore();
      await reopened.initialize(directory: root);
      final resolved = reopened.resolveMediaPath(
        reopened.readMap('video')!['path'] as String,
      )!;
      expect(resolved, startsWith(root.path));
      expect(await File(resolved).readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test('interrupted main file recovers the last valid backup', () async {
    store.setValue('sounds', {'connect': 'Car Horn'});
    await store.flush();
    store.setValue('sounds', {'connect': 'Thud'});
    await store.flush();
    await File('${root.path}/state_v1.json').writeAsString('{broken');
    final reopened = LocalStateStore();
    await reopened.initialize(directory: root);
    expect(reopened.readMap('sounds')?['connect'], 'Car Horn');
    reopened.setValue('sounds', {'connect': 'Calling'});
    await reopened.flush();
    final again = LocalStateStore();
    await again.initialize(directory: root);
    expect(again.readMap('sounds')?['connect'], 'Calling');
  });

  test('unknown versions and unrecoverable data are not reset', () async {
    final file = File('${root.path}/state_v1.json');
    final futureData = jsonEncode({'schemaVersion': 2, 'data': {}});
    await file.writeAsString(futureData);
    await expectLater(
      LocalStateStore().initialize(directory: root),
      throwsUnsupportedError,
    );
    expect(await file.readAsString(), futureData);
    await file.writeAsString('{broken');
    await expectLater(
      LocalStateStore().initialize(directory: root),
      throwsFormatException,
    );
    expect(await file.readAsString(), '{broken');
  });
}
