import 'dart:io';
import 'dart:typed_data';

import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/cards/data/models/affirmation_model.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'widget mutations and preview selection persist across reloads',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'carwidget_collection_',
      );
      final store = LocalStateStore();
      await store.initialize(directory: root);
      initializeMyWidgetsStorage(storage: store);
      addTearDown(() async {
        initializeMyWidgetsStorage(storage: LocalStateStore());
        await Future<void>.delayed(Duration.zero);
        await store.flush();
        await root.delete(recursive: true);
      });

      addBrandCarWidgetToMyWidgets(brandCarWidgetModels.first);
      final car = savedWidgetsListenable.value.single;
      setBrandCarGreetingNickname(car.layoutId!, 'Driver');
      setBrandCarElementPosition(
        car.layoutId!,
        BrandCarElement.car,
        const WidgetElementPosition(.25, .5),
      );
      setBrandCarCustomImage(car.layoutId!, Uint8List.fromList([1, 2, 3]));
      addAffirmationToMyWidgets(
        AffirmationModel(text: 'Keep going', date: DateTime(2026, 10, 16)),
      );
      final affirmation = savedWidgetsListenable.value.last;
      updateAffirmationInMyWidgets(
        widgetId: affirmation.id,
        affirmation: AffirmationModel(
          text: 'Updated text',
          date: DateTime(2026, 10, 17),
          styleIndex: 3,
        ),
      );
      final source = await File(
        '${root.path}/picked.mp4',
      ).writeAsBytes([4, 5, 6]);
      final mediaPath = await store.importVideo(source.path);
      addVideoWidgetToLibrary(
        videoPath: mediaPath,
        videoName: 'My video',
        videoStartMs: 2000,
        videoDurationMs: 5000,
        videoThumbnail: Uint8List.fromList([7, 8, 9]),
      );
      final video = videoWidgetsListenable.value.single;
      carPlayPreviewQueue.value = [car, video];
      await Future<void>.delayed(Duration.zero);
      await store.flush();

      final reopened = LocalStateStore();
      await reopened.initialize(directory: root);
      initializeMyWidgetsStorage(storage: reopened);
      expect(savedWidgetsListenable.value.length, 2);
      expect(savedWidgetsListenable.value.last.affirmationText, 'Updated text');
      expect(savedWidgetsListenable.value.last.affirmationStyleIndex, 3);
      expect(brandCarLayoutFor(car.layoutId!).greetingNickname, 'Driver');
      expect(brandCarLayoutFor(car.layoutId!).car.x, .25);
      expect(brandCarLayoutFor(car.layoutId!).carImageBytes, [1, 2, 3]);
      expect(videoWidgetsListenable.value.single.videoStartMs, 2000);
      expect(videoWidgetsListenable.value.single.videoPath, mediaPath);
      expect(carPlayPreviewQueue.value.map((value) => value?.id), [
        car.id,
        video.id,
      ]);

      removeSavedWidget(car.id);
      removeSavedWidget(affirmation.id);
      removeVideoWidgetFromLibrary(video.id);
      await Future<void>.delayed(Duration.zero);
      await reopened.flush();
      final emptyStore = LocalStateStore();
      await emptyStore.initialize(directory: root);
      initializeMyWidgetsStorage(storage: emptyStore);
      expect(savedWidgetsListenable.value, isEmpty);
      expect(videoWidgetsListenable.value, isEmpty);
      expect(carPlayPreviewQueue.value, [null, null]);
      expect(brandCarLayouts.value, isEmpty);
    },
  );
}
