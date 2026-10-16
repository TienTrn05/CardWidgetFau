import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/my_widgets/data/widget_collection_snapshot.dart';
import 'package:carwidget/features/cards/data/models/affirmation_model.dart';
import 'package:carwidget/features/cards/presentation/pages/affirmation_settings_page.dart';
import 'package:carwidget/features/cards/presentation/widgets/affirmation_card_artwork.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/country_flag_model.dart';
import 'package:carwidget/features/catalog/data/models/football_team_model.dart';
import 'package:carwidget/features/catalog/data/models/synthwave_model.dart';
import 'package:carwidget/features/catalog/data/models/widget_type.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/data/services/device_location_service.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/slide_right_transition.dart';
import 'package:carwidget/features/catalog/presentation/pages/logo_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/pages/country_flag_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/pages/photo_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/pages/football_team_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/pages/synthwave_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/country_flag_artwork.dart';
import 'package:carwidget/features/catalog/presentation/widgets/football_team_artwork.dart';
import 'package:carwidget/features/catalog/presentation/widgets/synthwave_artwork.dart';
import 'package:carwidget/features/catalog/presentation/pages/video_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_image_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_font_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/image_crop_dialog.dart';
import 'package:carwidget/features/catalog/presentation/widgets/logo_widget_content.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/editor/presentation/pages/brand_car_editor_page.dart';
import 'package:carwidget/features/editor/presentation/widgets/brand_car_border_style.dart';
import 'package:carwidget/features/settings/presentation/widgets/tutorial_sheet.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

final _savedWidgets = ValueNotifier<List<SavedWidgetModel>>([]);
ValueListenable<List<SavedWidgetModel>> get savedWidgetsListenable =>
    _savedWidgets;
final _videoWidgets = ValueNotifier<List<SavedWidgetModel>>([]);
ValueListenable<List<SavedWidgetModel>> get videoWidgetsListenable =>
    _videoWidgets;
const _widgetKitChannel = MethodChannel('carwidget/widgetkit_v1');
// Re-enable after App Group signing is available for both iOS targets.
const _isIPhoneWidgetExportEnabled = false;
final carPlayPreviewQueue = _createCarPlayPreviewQueue();
final _previewSelectionOrder = <String>[];
var _brandCarCopySequence = 0;

VoidCallback? _detachWidgetStorage;

void initializeMyWidgetsStorage({LocalStateStore? storage}) {
  _detachWidgetStorage?.call();
  final store = storage ?? LocalStateStore.instance;
  final snapshot = WidgetCollectionSnapshot.fromJson(
    store.readMap('widgetCollection') ?? {},
    store,
  );
  brandCarLayouts.value = snapshot.layouts;
  _savedWidgets.value = snapshot.widgets;
  _videoWidgets.value = snapshot.videos;
  carPlayPreviewQueue.value = snapshot.previewSlots;
  _previewSelectionOrder
    ..clear()
    ..addAll(snapshot.selectionOrder);

  var active = true;
  var pending = false;
  void save() {
    if (pending) return;
    pending = true;
    scheduleMicrotask(() {
      pending = false;
      if (!active) return;
      store.setValue(
        'widgetCollection',
        WidgetCollectionSnapshot(
          widgets: _savedWidgets.value,
          videos: _videoWidgets.value,
          layouts: brandCarLayouts.value,
          previewSlots: carPlayPreviewQueue.value,
          selectionOrder: List.of(_previewSelectionOrder),
        ).toJson(store),
      );
    });
  }

  final sources = [
    _savedWidgets,
    _videoWidgets,
    carPlayPreviewQueue,
    brandCarLayouts,
  ];
  for (final source in sources) {
    source.addListener(save);
  }
  _detachWidgetStorage = () {
    active = false;
    for (final source in sources) {
      source.removeListener(save);
    }
  };
}

ValueNotifier<List<SavedWidgetModel?>> _createCarPlayPreviewQueue() {
  final queue = ValueNotifier<List<SavedWidgetModel?>>([null, null]);
  if (_isIPhoneWidgetExportEnabled) {
    queue.addListener(_syncIPhoneWidgetSelection);
  }
  return queue;
}

List<String> _selectedWidgetIds() => List<String>.generate(
  2,
  (index) => index < carPlayPreviewQueue.value.length
      ? carPlayPreviewQueue.value[index]?.id ?? ''
      : '',
);

void _syncIPhoneWidgetSelection() {
  if (!Platform.isIOS || !_isIPhoneWidgetExportEnabled) return;
  _widgetKitChannel
      .invokeMethod<void>('setSelectedWidgets', _selectedWidgetIds())
      .catchError((_) {});
}

void _deleteWidgetKitImage(String widgetId) {
  if (!Platform.isIOS || !_isIPhoneWidgetExportEnabled) return;
  _widgetKitChannel
      .invokeMethod<void>('deleteWidget', widgetId)
      .catchError((_) {});
}

void addAffirmationToMyWidgets(AffirmationModel affirmation) {
  final widgetId =
      'affirmation_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: widgetId,
      label: affirmation.text,
      type: WidgetType.affirmation,
      affirmationText: affirmation.text,
      affirmationDate: affirmation.date,
      affirmationTextColorValue: affirmation.textColorValue,
      affirmationBackgroundColorValue: affirmation.backgroundColorValue,
      affirmationEyebrow: affirmation.eyebrow,
      affirmationStyleIndex: affirmation.styleIndex,
    ),
  ];
}

void updateAffirmationInMyWidgets({
  required String widgetId,
  required AffirmationModel affirmation,
}) {
  SavedWidgetModel updateAffirmation(SavedWidgetModel widget) =>
      widget.id != widgetId
      ? widget
      : SavedWidgetModel(
          id: widget.id,
          label: affirmation.text,
          type: WidgetType.affirmation,
          affirmationText: affirmation.text,
          affirmationDate: affirmation.date,
          affirmationTextColorValue: affirmation.textColorValue,
          affirmationBackgroundColorValue: affirmation.backgroundColorValue,
          affirmationEyebrow: affirmation.eyebrow,
          affirmationStyleIndex: affirmation.styleIndex,
        );

  _savedWidgets.value = _savedWidgets.value.map(updateAffirmation).toList();
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget == null ? null : updateAffirmation(widget))
      .toList();
}

void addBrandCarWidgetToMyWidgets(SavedWidgetModel template) {
  final copyId =
      '${template.id}_copy_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  final draftLayoutId = brandCarDraftLayoutId(template.id);
  final layoutId = 'saved:$copyId';
  copyBrandCarLayout(draftLayoutId, layoutId);
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: copyId,
      label: template.label,
      imageBytes: template.imageBytes,
      imageAsset: template.imageAsset,
      layoutId: layoutId,
      type: template.type,
    ),
  ];
}

void addLogoWidgetToMyWidgets(
  LogoWidgetModel template, {
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  final copyId =
      '${template.id}_copy_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: copyId,
      label: template.nameLogo,
      imageAsset: template.imageAsset,
      type: template.type,
      borderGradientIndex: borderGradientIndex,
      borderOpacity: borderOpacity,
      symbol: template.symbol,
    ),
  ];
}

void addCountryFlagToMyWidgets(
  CountryFlagModel template, {
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  final copyId =
      'flag_${template.code}_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: copyId,
      label: template.name,
      type: WidgetType.countryFlag,
      countryFlagCode: template.code,
      borderGradientIndex: borderGradientIndex,
      borderOpacity: borderOpacity,
    ),
  ];
}

void updateCountryFlagInMyWidgets({
  required String widgetId,
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  SavedWidgetModel updateFlagStyle(SavedWidgetModel widget) =>
      widget.id != widgetId
      ? widget
      : SavedWidgetModel(
          id: widget.id,
          label: widget.label,
          type: widget.type,
          countryFlagCode: widget.countryFlagCode,
          borderGradientIndex: borderGradientIndex,
          borderOpacity: borderOpacity,
        );

  _savedWidgets.value = _savedWidgets.value.map(updateFlagStyle).toList();
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget == null ? null : updateFlagStyle(widget))
      .toList();
}

void addFootballTeamToMyWidgets(
  FootballTeamModel template, {
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  final copyId =
      'team_${template.id}_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: copyId,
      label: template.name,
      type: WidgetType.footballTeam,
      footballTeamId: template.id,
      borderGradientIndex: borderGradientIndex,
      borderOpacity: borderOpacity,
    ),
  ];
}

void addSynthwaveToMyWidgets(
  SynthwaveModel template, {
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  final copyId =
      'synthwave_${template.id}_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: copyId,
      label: template.name,
      type: WidgetType.synthwave,
      synthwaveId: template.id,
      borderGradientIndex: borderGradientIndex,
      borderOpacity: borderOpacity,
    ),
  ];
}

void updateSynthwaveInMyWidgets({
  required String widgetId,
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  SavedWidgetModel updateStyle(SavedWidgetModel widget) => widget.id != widgetId
      ? widget
      : SavedWidgetModel(
          id: widget.id,
          label: widget.label,
          imageBytes: widget.imageBytes,
          imageAsset: widget.imageAsset,
          layoutId: widget.layoutId,
          type: widget.type,
          borderGradientIndex: borderGradientIndex,
          borderOpacity: borderOpacity,
          symbol: widget.symbol,
          countryFlagCode: widget.countryFlagCode,
          footballTeamId: widget.footballTeamId,
          synthwaveId: widget.synthwaveId,
          videoPath: widget.videoPath,
          videoName: widget.videoName,
          videoStartMs: widget.videoStartMs,
          videoDurationMs: widget.videoDurationMs,
          videoThumbnail: widget.videoThumbnail,
        );

  _savedWidgets.value = _savedWidgets.value.map(updateStyle).toList();
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget == null ? null : updateStyle(widget))
      .toList();
}

void updateFootballTeamInMyWidgets({
  required String widgetId,
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  SavedWidgetModel updateTeamStyle(SavedWidgetModel widget) =>
      widget.id != widgetId
      ? widget
      : SavedWidgetModel(
          id: widget.id,
          label: widget.label,
          imageBytes: widget.imageBytes,
          imageAsset: widget.imageAsset,
          layoutId: widget.layoutId,
          type: widget.type,
          borderGradientIndex: borderGradientIndex,
          borderOpacity: borderOpacity,
          symbol: widget.symbol,
          countryFlagCode: widget.countryFlagCode,
          footballTeamId: widget.footballTeamId,
          synthwaveId: widget.synthwaveId,
          videoPath: widget.videoPath,
          videoName: widget.videoName,
          videoStartMs: widget.videoStartMs,
          videoDurationMs: widget.videoDurationMs,
          videoThumbnail: widget.videoThumbnail,
        );

  _savedWidgets.value = _savedWidgets.value.map(updateTeamStyle).toList();
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget == null ? null : updateTeamStyle(widget))
      .toList();
}

void updatePhotoWidgetInMyWidgets({
  required String widgetId,
  required int? borderGradientIndex,
  required double borderOpacity,
}) {
  SavedWidgetModel updatePhotoStyle(SavedWidgetModel widget) =>
      widget.id != widgetId
      ? widget
      : SavedWidgetModel(
          id: widget.id,
          label: widget.label,
          imageBytes: widget.imageBytes,
          imageAsset: widget.imageAsset,
          layoutId: widget.layoutId,
          type: widget.type,
          borderGradientIndex: borderGradientIndex,
          borderOpacity: borderOpacity,
          symbol: widget.symbol,
          countryFlagCode: widget.countryFlagCode,
          footballTeamId: widget.footballTeamId,
          synthwaveId: widget.synthwaveId,
          videoPath: widget.videoPath,
          videoName: widget.videoName,
          videoStartMs: widget.videoStartMs,
          videoDurationMs: widget.videoDurationMs,
          videoThumbnail: widget.videoThumbnail,
        );

  _savedWidgets.value = _savedWidgets.value.map(updatePhotoStyle).toList();
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget == null ? null : updatePhotoStyle(widget))
      .toList();
}

void addVideoWidgetToMyWidgets({
  required String videoPath,
  required String videoName,
  required int videoStartMs,
  required int videoDurationMs,
  required Uint8List videoThumbnail,
}) {
  final widgetId =
      'video_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  _savedWidgets.value = [
    ..._savedWidgets.value,
    SavedWidgetModel(
      id: widgetId,
      label: videoName,
      type: WidgetType.video,
      videoPath: videoPath,
      videoName: videoName,
      videoStartMs: videoStartMs,
      videoDurationMs: videoDurationMs,
      videoThumbnail: videoThumbnail,
    ),
  ];
}

void addVideoWidgetToLibrary({
  String? widgetId,
  required String videoPath,
  required String videoName,
  required int videoStartMs,
  required int videoDurationMs,
  required Uint8List videoThumbnail,
}) {
  final id =
      widgetId ??
      'video_${DateTime.now().microsecondsSinceEpoch}_${_brandCarCopySequence++}';
  final videoWidget = SavedWidgetModel(
    id: id,
    label: videoName,
    type: WidgetType.video,
    videoPath: videoPath,
    videoName: videoName,
    videoStartMs: videoStartMs,
    videoDurationMs: videoDurationMs,
    videoThumbnail: videoThumbnail,
  );
  final existingIndex = _videoWidgets.value.indexWhere(
    (widget) => widget.id == id,
  );
  if (existingIndex < 0) {
    _videoWidgets.value = [..._videoWidgets.value, videoWidget];
  } else {
    _videoWidgets.value = _videoWidgets.value
        .map((widget) => widget.id == id ? videoWidget : widget)
        .toList();
  }
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget?.id == id ? videoWidget : widget)
      .toList();
}

void removeVideoWidgetFromLibrary(String widgetId) {
  _videoWidgets.value = _videoWidgets.value
      .where((widget) => widget.id != widgetId)
      .toList();
  _removeWidgetFromPreview(widgetId);
}

void updateVideoWidgetInMyWidgets({
  required String widgetId,
  required String videoPath,
  required String videoName,
  required int videoStartMs,
  required int videoDurationMs,
  required Uint8List videoThumbnail,
}) {
  final existingIndex = _savedWidgets.value.indexWhere(
    (widget) => widget.id == widgetId,
  );
  if (existingIndex < 0) return;
  final existingWidget = _savedWidgets.value[existingIndex];

  final updatedWidget = SavedWidgetModel(
    id: existingWidget.id,
    label: existingWidget.label,
    type: WidgetType.video,
    videoPath: videoPath,
    videoName: videoName,
    videoStartMs: videoStartMs,
    videoDurationMs: videoDurationMs,
    videoThumbnail: videoThumbnail,
  );
  _savedWidgets.value = _savedWidgets.value
      .map((widget) => widget.id == widgetId ? updatedWidget : widget)
      .toList();
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget?.id == widgetId ? updatedWidget : widget)
      .toList();
}

void _enqueueWidgetForCarPlayPreview(SavedWidgetModel widget) {
  final slots = List<SavedWidgetModel?>.of(carPlayPreviewQueue.value);
  if (slots.any((queuedWidget) => queuedWidget?.id == widget.id)) return;

  final emptySlot = slots.indexOf(null);
  if (emptySlot >= 0) {
    slots[emptySlot] = widget;
  } else {
    final oldestId = _previewSelectionOrder.removeAt(0);
    final oldestSlot = slots.indexWhere(
      (queuedWidget) => queuedWidget?.id == oldestId,
    );
    slots[oldestSlot >= 0 ? oldestSlot : 0] = widget;
  }
  _previewSelectionOrder.add(widget.id);
  carPlayPreviewQueue.value = slots;
}

void _removeSavedWidgetAt(int index) {
  if (index < 0 || index >= _savedWidgets.value.length) return;
  final widgets = List<SavedWidgetModel>.of(_savedWidgets.value);
  final removedWidget = widgets.removeAt(index);
  _savedWidgets.value = widgets;
  _deleteWidgetKitImage(removedWidget.id);
  final layoutId = removedWidget.layoutId;
  if (layoutId != null) {
    removeBrandCarLayout(layoutId);
  }
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget?.id == removedWidget.id ? null : widget)
      .toList();
  _previewSelectionOrder.remove(removedWidget.id);
}

void removeSavedWidget(String widgetId) {
  final index = _savedWidgets.value.indexWhere(
    (widget) => widget.id == widgetId,
  );
  _removeSavedWidgetAt(index);
}

void _removeWidgetFromPreview(String widgetId) {
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget?.id == widgetId ? null : widget)
      .toList();
  _previewSelectionOrder.remove(widgetId);
}

Future<void> _showWidgetPreview(
  BuildContext context, {
  required int initialIndex,
  required ValueListenable<List<SavedWidgetModel>> widgetsListenable,
  bool isVideoLibrary = false,
}) {
  if (widgetsListenable.value.isEmpty) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .86),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .92,
        minChildSize: .56,
        maxChildSize: .98,
        expand: false,
        builder: (context, scrollController) => _EmptyWidgetPreviewSheet(
          scrollController: scrollController,
          onClose: () => Navigator.of(sheetContext).pop(),
          onInfo: () => _showPreviewInfoDialog(context),
        ),
      ),
    );
  }

  return showSlideRightDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .86),
    builder: (_) => _WidgetPreviewDialog(
      initialIndex: initialIndex,
      widgetsListenable: widgetsListenable,
      isVideoLibrary: isVideoLibrary,
    ),
  );
}

Future<void> showSavedWidgetPreview(
  BuildContext context,
  SavedWidgetModel widget,
) {
  final index = _savedWidgets.value.indexWhere(
    (savedWidget) => savedWidget.id == widget.id,
  );
  if (index >= 0) {
    return _showWidgetPreview(
      context,
      initialIndex: index,
      widgetsListenable: _savedWidgets,
    );
  }

  final videoIndex = _videoWidgets.value.indexWhere(
    (videoWidget) => videoWidget.id == widget.id,
  );
  if (videoIndex < 0) return Future<void>.value();
  return _showWidgetPreview(
    context,
    initialIndex: videoIndex,
    widgetsListenable: _videoWidgets,
    isVideoLibrary: true,
  );
}

void _showPreviewInfoDialog(BuildContext context) => showTutorialSheet(context);

Future<void> showVideoWidgetPreview(
  BuildContext context,
  SavedWidgetModel widget,
) {
  final index = _videoWidgets.value.indexWhere(
    (videoWidget) => videoWidget.id == widget.id,
  );
  if (index < 0) return Future<void>.value();
  return _showWidgetPreview(
    context,
    initialIndex: index,
    widgetsListenable: _videoWidgets,
    isVideoLibrary: true,
  );
}

Future<void> showFirstSavedWidgetPreview(BuildContext context) {
  return _showWidgetPreview(
    context,
    initialIndex: 0,
    widgetsListenable: _savedWidgets,
  );
}

Future<void> _pickWidgetImage(BuildContext context) async {
  try {
    final selectedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (selectedImage == null || !context.mounted) return;

    final imageBytes = await selectedImage.readAsBytes();
    if (!context.mounted) return;
    final croppedImageBytes = await showImageCropDialog(context, imageBytes);
    if (croppedImageBytes == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: PhotoWidgetEditorPage(
          imageBytes: croppedImageBytes,
          onAdd: (result) {
            final photoWidget = SavedWidgetModel(
              id: 'photo_${DateTime.now().microsecondsSinceEpoch}',
              label: 'PHOTO',
              imageBytes: croppedImageBytes,
              type: WidgetType.image,
              borderGradientIndex: result.borderGradientIndex,
              borderOpacity: result.borderOpacity,
            );
            _savedWidgets.value = [..._savedWidgets.value, photoWidget];
          },
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Could not open the photo library.')),
      );
  }
}

class MyWidgetsSection extends StatelessWidget {
  const MyWidgetsSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _TutorialBanner(onTap: () => showTutorialSheet(context)),
      const SizedBox(height: 28),
      Row(
        children: [
          const Expanded(
            child: Text(
              'My Widgets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(6, 0),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyWidgetsPage(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9.5,
                    vertical: 4.5,
                  ),
                  child: Text(
                    'See All',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const _WidgetsCarousel(),
    ],
  );
}

class MyWidgetsPage extends StatelessWidget {
  const MyWidgetsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'My Widgets',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ValueListenableBuilder<List<SavedWidgetModel>>(
        valueListenable: _savedWidgets,
        builder: (context, widgets, _) => widgets.isEmpty
            ? const Center(
                child: Text(
                  'No widgets yet. Add one from the catalog.',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: widgets.length,
                itemBuilder: (context, index) {
                  final widget = widgets[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _SavedWidgetCard(
                          layoutId: widget.layoutId,
                          borderGradientIndex: widget.borderGradientIndex,
                          borderOpacity: widget.borderOpacity,
                          countryFlagCode: widget.countryFlagCode,
                          onTap: () => _showWidgetPreview(
                            context,
                            initialIndex: index,
                            widgetsListenable: _savedWidgets,
                          ),
                          child: SavedWidgetArtwork(widget: widget),
                        ),
                      ),
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Material(
                          color: const Color(0xCC080D12),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              _removeSavedWidgetAt(index);
                            },
                            child: const SizedBox.square(
                              dimension: 25,
                              child: Icon(Icons.close_rounded, size: 17),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    ),
  );
}

class _TutorialBanner extends StatelessWidget {
  const _TutorialBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF252D33),
    borderRadius: BorderRadius.circular(23),
    child: InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 45),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFF46525A), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_rounded,
                color: AppColors.background,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'How to Add Widget to CarPlay?',
                maxLines: 2,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WidgetsCarousel extends StatelessWidget {
  const _WidgetsCarousel();

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SavedWidgetModel>>(
        valueListenable: _savedWidgets,
        builder: (context, widgets, _) => LayoutBuilder(
          builder: (context, constraints) {
            final cardSize = carPlayWidgetPreviewSize(
              context,
              constraints.maxWidth,
            );
            return SizedBox(
              height: cardSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: widgets.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => SizedBox.square(
                  dimension: cardSize,
                  child: index == 0
                      ? _AddWidgetTile(onTap: () => _pickWidgetImage(context))
                      : _SavedWidgetCard(
                          layoutId: widgets[index - 1].layoutId,
                          borderGradientIndex:
                              widgets[index - 1].borderGradientIndex,
                          borderOpacity: widgets[index - 1].borderOpacity,
                          countryFlagCode: widgets[index - 1].countryFlagCode,
                          onTap: () => _showWidgetPreview(
                            context,
                            initialIndex: index - 1,
                            widgetsListenable: _savedWidgets,
                          ),
                          child: SavedWidgetArtwork(widget: widgets[index - 1]),
                        ),
                ),
              ),
            );
          },
        ),
      );
}

class _AddWidgetTile extends StatelessWidget {
  const _AddWidgetTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const _DashedBorderPainter(),
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                children: [
                  Positioned(
                    left: 14,
                    top: 6,
                    child: Transform.rotate(
                      angle: .12,
                      child: Container(
                        width: 37,
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFF008C61),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 2,
                    child: Transform.rotate(
                      angle: -.12,
                      child: Container(
                        width: 37,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.background,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Add Widget',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.deflate(1.5), const Radius.circular(24)),
      );
    final paint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dashEnd = (distance + 8).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, dashEnd), paint);
        distance += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SavedWidgetCard extends StatelessWidget {
  const _SavedWidgetCard({
    required this.child,
    this.layoutId,
    this.borderGradientIndex,
    this.borderOpacity = 1,
    this.matchLogoPreviewStyle = false,
    this.countryFlagCode,
    this.onTap,
  });

  final Widget child;
  final String? layoutId;
  final int? borderGradientIndex;
  final double borderOpacity;
  final bool matchLogoPreviewStyle;
  final String? countryFlagCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, BrandCarLayout>>(
        valueListenable: brandCarLayouts,
        builder: (context, layouts, _) {
          final layout = layoutId == null ? null : layouts[layoutId];
          final brandCarGradientIndex = layout?.borderGradientIndex;
          const borderColor = Color(0xFF303940);
          final borderWidth = brandCarGradientIndex != null
              ? math.min(layout!.borderWidth, 3.0)
              : 1.0;
          final gradientColors = borderGradientIndex == null
              ? brandCarGradientIndex == null
                    ? null
                    : brandCarBorderGradientColors(
                        brandCarGradientIndex,
                        layout!.borderOpacity,
                      )
              : logoBorderGradients[borderGradientIndex! %
                        logoBorderGradients.length]
                    .map((color) => color.withValues(alpha: borderOpacity))
                    .toList();
          if (matchLogoPreviewStyle) {
            return _LogoStyleSavedWidgetCard(
              gradientColors: gradientColors,
              onTap: onTap,
              child: child,
            );
          }
          if (countryFlagCode != null) {
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: CountryFlagArtworkFrame(
                  countryCode: countryFlagCode!,
                  borderGradientColors: gradientColors,
                  borderColor: borderColor,
                  borderWidth: gradientColors == null ? borderWidth : 2,
                  borderRadius: 24,
                ),
              ),
            );
          }
          return Material(
            color: const Color(0xFF20272D),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: gradientColors == null
                      ? const Color(0xFF20272D)
                      : null,
                  gradient: gradientColors == null
                      ? null
                      : LinearGradient(colors: gradientColors),
                ),
                child: Padding(
                  padding: EdgeInsets.all(gradientColors == null ? 0 : 2),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xFF20272D),
                      borderRadius: BorderRadius.circular(22),
                      border: gradientColors == null
                          ? Border.all(color: borderColor, width: borderWidth)
                          : null,
                    ),
                    child: Center(child: child),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _PhotoSavedWidgetPreview extends StatelessWidget {
  const _PhotoSavedWidgetPreview({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) {
    final colors = widget.borderGradientIndex == null
        ? null
        : logoBorderGradients[widget.borderGradientIndex! %
                  logoBorderGradients.length]
              .map((color) => color.withValues(alpha: widget.borderOpacity))
              .toList();
    return Container(
      padding: EdgeInsets.all(colors == null ? 1.5 : 1),
      decoration: BoxDecoration(
        color: colors == null ? const Color(0xFF252D33) : null,
        borderRadius: BorderRadius.circular(42),
        border: colors == null
            ? Border.all(color: const Color(0xFF39424A), width: 1.5)
            : null,
        gradient: colors == null ? null : LinearGradient(colors: colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: widget.imageBytes == null
            ? SavedWidgetArtwork(widget: widget)
            : Image.memory(
                widget.imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                  size: 36,
                ),
              ),
      ),
    );
  }
}

class _CountryFlagSavedWidgetPreview extends StatelessWidget {
  const _CountryFlagSavedWidgetPreview({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) {
    final colors = widget.borderGradientIndex == null
        ? null
        : logoBorderGradients[widget.borderGradientIndex! %
                  logoBorderGradients.length]
              .map((color) => color.withValues(alpha: widget.borderOpacity))
              .toList();
    return CountryFlagArtworkFrame(
      countryCode: widget.countryFlagCode!,
      borderGradientColors: colors,
      borderRadius: 42,
      borderWidth: colors == null ? 1.5 : 3,
    );
  }
}

class _LogoStyleSavedWidgetCard extends StatelessWidget {
  const _LogoStyleSavedWidgetCard({
    required this.gradientColors,
    required this.child,
    this.onTap,
  });

  final List<Color>? gradientColors;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(42),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(42),
      child: Ink(
        decoration: BoxDecoration(
          color: gradientColors == null ? const Color(0xFF252D33) : null,
          borderRadius: BorderRadius.circular(42),
          border: gradientColors == null
              ? Border.all(color: const Color(0xFF39424A), width: 1.5)
              : null,
          gradient: gradientColors == null
              ? null
              : LinearGradient(colors: gradientColors!),
        ),
        child: Padding(
          padding: EdgeInsets.all(gradientColors == null ? 1.5 : 3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(39),
            child: ColoredBox(
              color: const Color(0xFF252D33),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SynthwaveSavedWidgetPreview extends StatelessWidget {
  const _SynthwaveSavedWidgetPreview({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) {
    final colors = widget.borderGradientIndex == null
        ? null
        : logoBorderGradients[widget.borderGradientIndex! %
                  logoBorderGradients.length]
              .map((color) => color.withValues(alpha: widget.borderOpacity))
              .toList();
    return Container(
      padding: EdgeInsets.all(colors == null ? 1.5 : 3),
      decoration: BoxDecoration(
        color: colors == null ? const Color(0xFF252D33) : null,
        borderRadius: BorderRadius.circular(42),
        border: colors == null
            ? Border.all(color: const Color(0xFF39424A), width: 1.5)
            : null,
        gradient: colors == null ? null : LinearGradient(colors: colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: SavedWidgetArtwork(widget: widget),
      ),
    );
  }
}

class SavedWidgetArtwork extends StatelessWidget {
  const SavedWidgetArtwork({
    super.key,
    required this.widget,
    this.isEditable = false,
    this.layoutId,
  });

  final SavedWidgetModel widget;
  final bool isEditable;
  final String? layoutId;

  @override
  Widget build(BuildContext context) {
    if (widget.type == WidgetType.affirmation &&
        widget.affirmationText != null &&
        widget.affirmationDate != null) {
      return AffirmationCardArtwork(
        affirmation: AffirmationModel(
          text: widget.affirmationText!,
          date: widget.affirmationDate!,
          textColorValue: widget.affirmationTextColorValue,
          backgroundColorValue: widget.affirmationBackgroundColorValue,
          eyebrow: widget.affirmationEyebrow,
          styleIndex: widget.affirmationStyleIndex,
        ),
      );
    }

    if (widget.type == WidgetType.countryFlag &&
        widget.countryFlagCode != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: SizedBox.expand(
          child: CountryFlagArtwork(countryCode: widget.countryFlagCode!),
        ),
      );
    }

    if (widget.type == WidgetType.footballTeam &&
        widget.footballTeamId != null) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: FootballTeamArtwork(teamId: widget.footballTeamId!),
      );
    }

    if (widget.type == WidgetType.synthwave && widget.synthwaveId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SynthwaveArtwork(synthwaveId: widget.synthwaveId!),
      );
    }

    if (widget.type == WidgetType.video) {
      if (widget.videoPath != null) {
        return _LoopingVideoArtwork(widget: widget);
      }
      final thumbnail = widget.videoThumbnail;
      if (thumbnail != null) {
        return SizedBox.expand(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Image.memory(thumbnail, fit: BoxFit.cover),
          ),
        );
      }
      return _VideoWidgetArtwork(name: widget.videoName ?? widget.label);
    }

    final imageBytes = widget.imageBytes;
    if (imageBytes != null) {
      return SizedBox.expand(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.muted,
              size: 36,
            ),
          ),
        ),
      );
    }

    if (widget.type == WidgetType.logoAndName && widget.symbol != null) {
      return LogoWidgetTileContent(
        model: LogoWidgetModel(
          id: widget.id,
          nameLogo: widget.label,
          symbol: widget.symbol!,
          type: widget.type,
          imageAsset: widget.imageAsset,
        ),
      );
    }

    final imageAsset = widget.imageAsset;
    if (imageAsset != null) {
      return SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.muted,
              size: 36,
            ),
          ),
        ),
      );
    }

    if (widget.type == WidgetType.carLogoAndName) {
      return _BrandCarArtwork(
        widget: widget,
        layoutId: layoutId ?? widget.layoutId ?? widget.id,
        isEditable: isEditable,
      );
    }

    if (widget.type == WidgetType.plate) {
      return _PlateArtwork(label: widget.label);
    }

    return _AbarthArtwork(label: widget.label);
  }
}

class _BrandCarArtwork extends StatelessWidget {
  const _BrandCarArtwork({
    required this.widget,
    required this.layoutId,
    this.isEditable = false,
  });

  final SavedWidgetModel widget;
  final String layoutId;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    DeviceLocationService.loadIfNeeded();
    return ValueListenableBuilder<Map<String, BrandCarLayout>>(
      valueListenable: brandCarLayouts,
      builder: (context, layouts, _) => LayoutBuilder(
        builder: (context, constraints) {
          final inset = isEditable
              ? 0.0
              : layouts.containsKey(layoutId)
              ? 1.0
              : 12.0;
          final canvasSize = Size(
            math.max(0.0, constraints.maxWidth - inset * 2),
            math.max(0.0, constraints.maxHeight - inset * 2),
          );
          final carSize = math.min(88.0, canvasSize.width * .54);
          final layout = layouts[layoutId] ?? const BrandCarLayout();
          final carImage =
              brandCarImageOptions[layout.carImageIndex %
                  brandCarImageOptions.length];
          final carImageBytes = layout.carImageBytes;
          final greetingFontFamily =
              brandCarFontOptions[layout.greetingFontIndex
                      .clamp(0, brandCarFontOptions.length - 1)
                      .toInt()]
                  .fontFamily;
          final carArtwork = carImageBytes == null
              ? Icon(
                  carImage.icon,
                  color: carImage.color,
                  size: carSize * layout.carScale,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 7,
                      offset: Offset(0, 4),
                    ),
                  ],
                )
              : Image.memory(
                  carImageBytes,
                  width: carSize * layout.carScale * 1.5,
                  height: carSize * layout.carScale,
                  fit: BoxFit.contain,
                );
          return Padding(
            padding: EdgeInsets.all(inset),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _brandCarElement(
                  widgetId: layoutId,
                  element: BrandCarElement.greeting,
                  position: layout.greeting,
                  size: canvasSize,
                  editable: isEditable,
                  child: Text(
                    'Hello,\n${layout.greetingNickname}',
                    style: TextStyle(
                      color: Color(layout.greetingColorValue),
                      fontFamily: greetingFontFamily,
                      fontSize: isEditable ? 16 : 14,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _brandCarElement(
                  widgetId: layoutId,
                  element: BrandCarElement.brand,
                  position: layout.brand,
                  size: canvasSize,
                  editable: isEditable,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .58),
                      fontSize: (isEditable ? 15 : 12) * layout.brandScale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _brandCarElement(
                  widgetId: layoutId,
                  element: BrandCarElement.car,
                  position: layout.car,
                  size: canvasSize,
                  editable: isEditable,
                  child: carArtwork,
                ),
                ValueListenableBuilder<String>(
                  valueListenable: DeviceLocationService.cityName,
                  builder: (context, cityName, _) => _brandCarElement(
                    widgetId: layoutId,
                    element: BrandCarElement.location,
                    position: layout.location,
                    size: canvasSize,
                    editable: isEditable,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: canvasSize.width * .76,
                      ),
                      child: Tooltip(
                        message: cityName == 'Location unavailable'
                            ? 'Tap to retry location'
                            : cityName,
                        child: InkWell(
                          onTap: cityName == 'Location unavailable'
                              ? DeviceLocationService.retry
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 1,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    cityName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: .8),
                                      fontSize: isEditable ? 9 : 8,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _brandCarElement({
    required String widgetId,
    required BrandCarElement element,
    required WidgetElementPosition position,
    required Size size,
    required bool editable,
    required Widget child,
  }) => _DraggableBrandCarElement(
    key: ValueKey('$widgetId-${element.name}'),
    widgetId: widgetId,
    element: element,
    position: position,
    canvasSize: size,
    editable: editable,
    child: child,
  );
}

class _DraggableBrandCarElement extends StatefulWidget {
  const _DraggableBrandCarElement({
    super.key,
    required this.widgetId,
    required this.element,
    required this.position,
    required this.canvasSize,
    required this.editable,
    required this.child,
  });

  final String widgetId;
  final BrandCarElement element;
  final WidgetElementPosition position;
  final Size canvasSize;
  final bool editable;
  final Widget child;

  @override
  State<_DraggableBrandCarElement> createState() =>
      _DraggableBrandCarElementState();
}

class _DraggableBrandCarElementState extends State<_DraggableBrandCarElement> {
  void _onPanUpdate(DragUpdateDetails details) {
    final width = math.max(widget.canvasSize.width, 1);
    final height = math.max(widget.canvasSize.height, 1);
    final currentPosition = brandCarLayoutFor(
      widget.widgetId,
    ).positionFor(widget.element);
    setBrandCarElementPosition(
      widget.widgetId,
      widget.element,
      currentPosition.movedBy(
        details.delta.dx * 2 / width,
        details.delta.dy * 2 / height,
        maxAbsX: 1,
        maxAbsY: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment(widget.position.x, widget.position.y),
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: widget.editable ? _onPanUpdate : null,
      child: DecoratedBox(
        decoration: widget.editable
            ? BoxDecoration(
                border: Border.all(
                  color: AppColors.green.withValues(alpha: .8),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(7),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: EdgeInsets.all(widget.editable ? 4 : 0),
          child: widget.child,
        ),
      ),
    ),
  );
}

class _AbarthArtwork extends StatelessWidget {
  const _AbarthArtwork({this.label = 'ABARTH'});

  final String label;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(
      width: 138,
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.shield_rounded, color: Colors.black, size: 148),
          const Icon(Icons.shield_rounded, color: Color(0xFFE9C900), size: 136),
          Positioned(
            top: 29,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1975A6),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: label == 'ABARTH' ? 15 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 56,
            child: Icon(Icons.bolt_rounded, color: Colors.black, size: 66),
          ),
          Positioned(
            bottom: 23,
            child: Container(
              width: 59,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFB51720),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(
                Icons.speed_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlateArtwork extends StatelessWidget {
  const _PlateArtwork({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 224,
      height: 76,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF111820), width: 5),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111820),
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    ),
  );
}

class _VideoWidgetArtwork extends StatelessWidget {
  const _VideoWidgetArtwork({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.background,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoopingVideoArtwork extends StatefulWidget {
  const _LoopingVideoArtwork({required this.widget});

  final SavedWidgetModel widget;

  @override
  State<_LoopingVideoArtwork> createState() => _LoopingVideoArtworkState();
}

class _LoopingVideoArtworkState extends State<_LoopingVideoArtwork> {
  late final VideoPlayerController _controller;
  var _isReady = false;
  var _isRestarting = false;
  var _isDisposed = false;

  int get _trimEndMs {
    final totalDurationMs = _controller.value.duration.inMilliseconds;
    final trimDurationMs = widget.widget.videoDurationMs;
    if (trimDurationMs == null || trimDurationMs <= 0) {
      return totalDurationMs;
    }
    return math.min(
      widget.widget.videoStartMs + trimDurationMs,
      totalDurationMs,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.widget.videoPath!));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      await _controller.setVolume(0);
      final durationMs = _controller.value.duration.inMilliseconds;
      final startMs = widget.widget.videoStartMs.clamp(0, durationMs);
      await _controller.setLooping(false);
      await _controller.seekTo(Duration(milliseconds: startMs));
      _controller.addListener(_handlePlayback);
      if (!mounted) return;
      setState(() => _isReady = true);
      await _controller.play();
    } catch (_) {
      // Keep showing the saved thumbnail when the source video is unavailable.
    }
  }

  void _handlePlayback() {
    if (_isDisposed || !mounted) return;
    if (_controller.value.isPlaying &&
        _controller.value.position.inMilliseconds >= _trimEndMs &&
        !_isRestarting) {
      _restartTrimmedPlayback();
    }
  }

  Future<void> _restartTrimmedPlayback() async {
    if (_isDisposed || !mounted || _isRestarting) return;
    _isRestarting = true;
    try {
      await _controller.pause();
      if (_isDisposed || !mounted) return;
      await _controller.seekTo(
        Duration(milliseconds: widget.widget.videoStartMs),
      );
      if (!_isDisposed && mounted) await _controller.play();
    } catch (_) {
      // The controller can finish an in-flight operation as this tile is removed.
    } finally {
      _isRestarting = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.removeListener(_handlePlayback);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(23),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.widget.videoThumbnail != null)
          Image.memory(widget.widget.videoThumbnail!, fit: BoxFit.cover)
        else
          const ColoredBox(color: Colors.black),
        if (_isReady)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
      ],
    ),
  );
}

class _EmptyWidgetPreviewSheet extends StatelessWidget {
  const _EmptyWidgetPreviewSheet({
    required this.scrollController,
    required this.onClose,
    required this.onInfo,
  });

  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      controller: scrollController,
      child: SizedBox(
        height: constraints.maxHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF0B0E17),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Close preview',
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded, size: 25),
                        ),
                        const Expanded(
                          child: Text(
                            'Preview Widget',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'About the preview',
                          onPressed: onInfo,
                          icon: const Icon(
                            Icons.info_rounded,
                            color: AppColors.green,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      'This only updates the preview. CarPlay setup is done separately.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, progress, child) => Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - progress)),
                            child: Transform.scale(
                              scale: .94 + .06 * progress,
                              child: child,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003B2B),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.widgets_rounded,
                                  color: AppColors.green,
                                  size: 58,
                                ),
                              ),
                              const SizedBox(height: 34),
                              const Text(
                                'No Widget Added',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 17,
                                    height: 1.35,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Browse widgets below and tap ',
                                    ),
                                    TextSpan(
                                      text: '“Add Widget”',
                                      style: const TextStyle(
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' to build your collection.',
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _WidgetPreviewDialog extends StatefulWidget {
  const _WidgetPreviewDialog({
    required this.initialIndex,
    required this.widgetsListenable,
    this.isVideoLibrary = false,
  });

  final int initialIndex;
  final ValueListenable<List<SavedWidgetModel>> widgetsListenable;
  final bool isVideoLibrary;

  @override
  State<_WidgetPreviewDialog> createState() => _WidgetPreviewDialogState();
}

class _WidgetPreviewDialogState extends State<_WidgetPreviewDialog> {
  late int _currentIndex = widget.initialIndex;
  var _navigationDirection = 1;
  var _isExportingToIPhone = false;
  final _previewBoundaryKey = GlobalKey();

  void _selectIndex(int index) {
    if (_isExportingToIPhone || index == _currentIndex) return;

    setState(() {
      _navigationDirection = index > _currentIndex ? 1 : -1;
      _currentIndex = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<SavedWidgetModel>>(
    valueListenable: widget.widgetsListenable,
    builder: (context, widgets, _) {
      if (widgets.isEmpty) {
        return const SizedBox.shrink();
      }

      final currentIndex = _currentIndex.clamp(0, widgets.length - 1);
      final currentWidget = widgets[currentIndex];
      final selectedSlot = carPlayPreviewQueue.value.indexWhere(
        (selectedWidget) => selectedWidget?.id == currentWidget.id,
      );
      final mediaSize = MediaQuery.sizeOf(context);
      final safeAreaInsets = MediaQuery.paddingOf(context);
      final logoPreviewHeight =
          (mediaSize.height - safeAreaInsets.vertical - 52) * 2 / 5;

      return Dialog(
        backgroundColor: const Color(0xFF101019),
        insetPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: FractionallySizedBox(
          widthFactor: 1,
          heightFactor: .985,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 25),
                      ),
                      const Expanded(
                        child: Text(
                          'Preview Widget',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'About the preview',
                        onPressed: () => _showPreviewInfoDialog(context),
                        icon: const Icon(
                          Icons.info_rounded,
                          color: AppColors.green,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'iPhone Widget export is temporarily disabled. CarPlay preview selection is still available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.35),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, stageConstraints) {
                      final previewSize =
                          editorWidgetPreviewSize(
                            BoxConstraints(
                              maxWidth: stageConstraints.maxWidth,
                              maxHeight: math.min(
                                stageConstraints.maxHeight,
                                math.max(0, logoPreviewHeight),
                              ),
                            ),
                          ) *
                          .9;
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RepaintBoundary(
                                key: _previewBoundaryKey,
                                child: SizedBox.square(
                                  dimension: previewSize,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) {
                                      final isOutgoing =
                                          animation.status ==
                                          AnimationStatus.reverse;
                                      final direction = _navigationDirection
                                          .toDouble();
                                      final slideProgress = isOutgoing
                                          ? ReverseAnimation(animation)
                                          : animation;
                                      final slide =
                                          Tween<Offset>(
                                            begin: isOutgoing
                                                ? Offset.zero
                                                : Offset(direction, 0),
                                            end: isOutgoing
                                                ? Offset(-direction, 0)
                                                : Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: slideProgress,
                                              curve: Curves.easeInOutCubic,
                                            ),
                                          );

                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: slide,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: KeyedSubtree(
                                      key: ValueKey(currentWidget.id),
                                      child:
                                          currentWidget.type ==
                                                  WidgetType.countryFlag &&
                                              currentWidget.countryFlagCode !=
                                                  null
                                          ? _CountryFlagSavedWidgetPreview(
                                              widget: currentWidget,
                                            )
                                          : currentWidget.type ==
                                                WidgetType.image
                                          ? _PhotoSavedWidgetPreview(
                                              widget: currentWidget,
                                            )
                                          : currentWidget.type ==
                                                WidgetType.video
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child: SavedWidgetArtwork(
                                                widget: currentWidget,
                                              ),
                                            )
                                          : currentWidget.type ==
                                                WidgetType.synthwave
                                          ? _SynthwaveSavedWidgetPreview(
                                              widget: currentWidget,
                                            )
                                          : currentWidget.type ==
                                                WidgetType.affirmation
                                          ? SavedWidgetArtwork(
                                              widget: currentWidget,
                                            )
                                          : _SavedWidgetCard(
                                              layoutId: currentWidget.layoutId,
                                              borderGradientIndex: currentWidget
                                                  .borderGradientIndex,
                                              borderOpacity:
                                                  currentWidget.borderOpacity,
                                              matchLogoPreviewStyle: true,
                                              child: SavedWidgetArtwork(
                                                widget: currentWidget,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 17),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (
                                    var index = 0;
                                    index < widgets.length;
                                    index++
                                  )
                                    GestureDetector(
                                      onTap: () => _selectIndex(index),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 6,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 160,
                                          ),
                                          width: index == currentIndex ? 9 : 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: index == currentIndex
                                                ? AppColors.green
                                                : const Color(0xFF59606B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filled(
                              tooltip: 'Previous widget',
                              onPressed: currentIndex > 0
                                  ? () => _selectIndex(currentIndex - 1)
                                  : null,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.background,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: AppColors.surface,
                              ),
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 28,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton.filled(
                              tooltip: 'Next widget',
                              onPressed: currentIndex < widgets.length - 1
                                  ? () => _selectIndex(currentIndex + 1)
                                  : null,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.background,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: AppColors.surface,
                              ),
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      _enqueueWidgetForCarPlayPreview(currentWidget);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Select Widget'),
                  ),
                ),
                if (Platform.isIOS && _isIPhoneWidgetExportEnabled) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isExportingToIPhone || selectedSlot < 0
                          ? null
                          : () => _exportCurrentWidget(currentWidget),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_to_home_screen_rounded),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selectedSlot == 0
                              ? 'Car Widget'
                              : selectedSlot == 1
                              ? 'Car Widget 2'
                              : 'Select for CarPlay first',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      if (currentWidget.type == WidgetType.carLogoAndName) {
                        openSavedBrandCarWidgetEditor(context, currentWidget);
                      } else if (currentWidget.type == WidgetType.logoAndName &&
                          currentWidget.symbol != null) {
                        _editSavedLogoWidget(currentWidget);
                      } else if (currentWidget.type == WidgetType.video &&
                          currentWidget.videoPath != null) {
                        _editSavedVideoWidget(context, currentWidget);
                      } else if (currentWidget.type == WidgetType.image &&
                          currentWidget.imageBytes != null) {
                        _editSavedPhotoWidget(currentWidget);
                      } else if (currentWidget.type == WidgetType.countryFlag &&
                          currentWidget.countryFlagCode != null) {
                        _editSavedCountryFlagWidget(currentWidget);
                      } else if (currentWidget.type ==
                              WidgetType.footballTeam &&
                          currentWidget.footballTeamId != null) {
                        _editSavedFootballTeamWidget(currentWidget);
                      } else if (currentWidget.type == WidgetType.synthwave &&
                          currentWidget.synthwaveId != null) {
                        _editSavedSynthwaveWidget(currentWidget);
                      } else if (currentWidget.type == WidgetType.affirmation &&
                          currentWidget.affirmationText != null &&
                          currentWidget.affirmationDate != null) {
                        _editSavedAffirmationWidget(currentWidget);
                      } else {
                        _showEditNotice(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Edit Widget'),
                  ),
                ),
                TextButton(
                  onPressed: () => _removeCurrentWidget(currentWidget),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: const Text('Remove from Preview'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  void _removeCurrentWidget(SavedWidgetModel widget) {
    _removeWidgetFromPreview(widget.id);
    Navigator.of(context).pop();
  }

  Future<void> _exportCurrentWidget(SavedWidgetModel widget) async {
    if (!_isIPhoneWidgetExportEnabled) return;

    final selectedSlot = carPlayPreviewQueue.value.indexWhere(
      (selectedWidget) => selectedWidget?.id == widget.id,
    );
    if (selectedSlot < 0) return;

    setState(() => _isExportingToIPhone = true);
    try {
      await _widgetKitChannel.invokeMethod<void>(
        'setSelectedWidgets',
        _selectedWidgetIds(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 320));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _previewBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize) {
        throw StateError('The widget preview is not ready yet.');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw StateError('Could not encode the widget image.');
        }
        await _widgetKitChannel.invokeMethod<void>('saveWidget', {
          'id': widget.id,
          'name': widget.label,
          'imageBytes': bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          ),
        });
      } finally {
        image.dispose();
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Widget saved to iPhone'),
          content: Text(
            'To add it to your Home Screen:\n\n'
            '1. Touch and hold an empty area on the Home Screen.\n'
            '2. Tap Edit, then Add Widget.\n'
            '3. Choose ${selectedSlot == 0 ? 'Car Widget' : 'Car Widget 2'} and select a size.\n\n'
            'Export again after editing the design to refresh its iPhone widget.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not save the iPhone widget.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save the iPhone widget: $error')),
      );
    } finally {
      if (mounted) setState(() => _isExportingToIPhone = false);
    }
  }

  Future<void> _editSavedLogoWidget(SavedWidgetModel savedWidget) async {
    final result = await showDialog<LogoWidgetEditResult>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: LogoWidgetEditorPage(
          model: LogoWidgetModel(
            id: savedWidget.id,
            nameLogo: savedWidget.label,
            symbol: savedWidget.symbol!,
            type: savedWidget.type,
            imageAsset: savedWidget.imageAsset,
          ),
          initialGradientIndex: savedWidget.borderGradientIndex,
          initialBorderOpacity: savedWidget.borderOpacity,
          isEditingSavedWidget: true,
        ),
      ),
    );
    if (!mounted || result == null) return;

    SavedWidgetModel updateLogoStyle(SavedWidgetModel widget) =>
        widget.id != savedWidget.id
        ? widget
        : SavedWidgetModel(
            id: widget.id,
            label: widget.label,
            imageBytes: widget.imageBytes,
            imageAsset: widget.imageAsset,
            layoutId: widget.layoutId,
            type: widget.type,
            borderGradientIndex: result.borderGradientIndex,
            borderOpacity: result.borderOpacity,
            symbol: widget.symbol,
            countryFlagCode: widget.countryFlagCode,
            footballTeamId: widget.footballTeamId,
            synthwaveId: widget.synthwaveId,
            videoPath: widget.videoPath,
            videoName: widget.videoName,
            videoStartMs: widget.videoStartMs,
            videoDurationMs: widget.videoDurationMs,
            videoThumbnail: widget.videoThumbnail,
          );

    _savedWidgets.value = _savedWidgets.value.map(updateLogoStyle).toList();
    carPlayPreviewQueue.value = carPlayPreviewQueue.value
        .map((widget) => widget == null ? null : updateLogoStyle(widget))
        .toList();
  }

  Future<void> _editSavedCountryFlagWidget(SavedWidgetModel savedWidget) async {
    final result = await showDialog<CountryFlagEditResult>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: CountryFlagEditorPage(
          model: CountryFlagModel(
            code: savedWidget.countryFlagCode!,
            name: savedWidget.label,
          ),
          initialGradientIndex: savedWidget.borderGradientIndex,
          initialBorderOpacity: savedWidget.borderOpacity,
          isEditingSavedWidget: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    updateCountryFlagInMyWidgets(
      widgetId: savedWidget.id,
      borderGradientIndex: result.borderGradientIndex,
      borderOpacity: result.borderOpacity,
    );
  }

  Future<void> _editSavedFootballTeamWidget(
    SavedWidgetModel savedWidget,
  ) async {
    final team = footballTeamModels.firstWhere(
      (model) => model.id == savedWidget.footballTeamId,
      orElse: () => FootballTeamModel(
        id: savedWidget.footballTeamId!,
        name: savedWidget.label,
      ),
    );
    final result = await showDialog<FootballTeamEditResult>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: FootballTeamEditorPage(
          model: team,
          initialGradientIndex: savedWidget.borderGradientIndex,
          initialBorderOpacity: savedWidget.borderOpacity,
          isEditingSavedWidget: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    updateFootballTeamInMyWidgets(
      widgetId: savedWidget.id,
      borderGradientIndex: result.borderGradientIndex,
      borderOpacity: result.borderOpacity,
    );
  }

  Future<void> _editSavedSynthwaveWidget(SavedWidgetModel savedWidget) async {
    final model = synthwaveModels.firstWhere(
      (item) => item.id == savedWidget.synthwaveId,
      orElse: () =>
          SynthwaveModel(id: savedWidget.synthwaveId!, name: savedWidget.label),
    );
    final result = await showDialog<SynthwaveEditResult>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: SynthwaveEditorPage(
          model: model,
          initialGradientIndex: savedWidget.borderGradientIndex,
          initialBorderOpacity: savedWidget.borderOpacity,
          isEditingSavedWidget: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    updateSynthwaveInMyWidgets(
      widgetId: savedWidget.id,
      borderGradientIndex: result.borderGradientIndex,
      borderOpacity: result.borderOpacity,
    );
  }

  Future<void> _editSavedAffirmationWidget(SavedWidgetModel savedWidget) async {
    final result = await Navigator.of(context).push<AffirmationModel>(
      MaterialPageRoute<AffirmationModel>(
        builder: (_) => AffirmationSettingsPage(
          affirmation: AffirmationModel(
            text: savedWidget.affirmationText!,
            date: savedWidget.affirmationDate!,
            textColorValue: savedWidget.affirmationTextColorValue,
            backgroundColorValue: savedWidget.affirmationBackgroundColorValue,
            eyebrow: savedWidget.affirmationEyebrow,
            styleIndex: savedWidget.affirmationStyleIndex,
          ),
          isEditing: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    updateAffirmationInMyWidgets(widgetId: savedWidget.id, affirmation: result);
  }

  Future<void> _editSavedPhotoWidget(SavedWidgetModel savedWidget) async {
    final result = await showDialog<PhotoWidgetEditResult>(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: PhotoWidgetEditorPage(
          imageBytes: savedWidget.imageBytes!,
          initialGradientIndex: savedWidget.borderGradientIndex,
          initialBorderOpacity: savedWidget.borderOpacity,
          isEditingSavedWidget: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    updatePhotoWidgetInMyWidgets(
      widgetId: savedWidget.id,
      borderGradientIndex: result.borderGradientIndex,
      borderOpacity: result.borderOpacity,
    );
  }

  void _showEditNotice(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Editing is currently available for Photos, Videos, Logos, Country Flags, Football Teams, and Brand Car widgets.',
          ),
        ),
      );
  }

  Future<void> _editSavedVideoWidget(
    BuildContext context,
    SavedWidgetModel widget,
  ) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VideoWidgetEditorPage(
          videoPath: widget.videoPath!,
          videoName: widget.videoName ?? widget.label,
          initialStartMs: widget.videoStartMs,
          initialDurationMs: widget.videoDurationMs,
          onSaveEditedVideo: (startMs, durationMs, thumbnail) {
            if (this.widget.isVideoLibrary) {
              addVideoWidgetToLibrary(
                widgetId: widget.id,
                videoPath: widget.videoPath!,
                videoName: widget.videoName ?? widget.label,
                videoStartMs: startMs,
                videoDurationMs: durationMs,
                videoThumbnail: thumbnail,
              );
            } else {
              updateVideoWidgetInMyWidgets(
                widgetId: widget.id,
                videoPath: widget.videoPath!,
                videoName: widget.videoName ?? widget.label,
                videoStartMs: startMs,
                videoDurationMs: durationMs,
                videoThumbnail: thumbnail,
              );
            }
          },
        ),
      ),
    );
    if (!context.mounted || didSave != true) return;
    Navigator.of(context).pop();
  }
}
