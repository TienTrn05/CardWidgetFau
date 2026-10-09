import 'dart:math' as math;

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/data/services/device_location_service.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_image_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_font_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/image_crop_dialog.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/settings/presentation/widgets/tutorial_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

final _savedWidgets = ValueNotifier<List<SavedWidgetModel>>(
  initialSavedWidgetModels,
);
final carPlayPreviewQueue = ValueNotifier<List<SavedWidgetModel?>>([
  null,
  null,
]);
final _previewSelectionOrder = <String>[];
var _brandCarCopySequence = 0;
void addBrandCarWidgetToMyWidgets(
  BuildContext context,
  SavedWidgetModel template,
) {
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
      layoutId: layoutId,
    ),
  ];
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('${template.label} added to My Widgets.')),
    );
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
  final layoutId = removedWidget.layoutId;
  if (layoutId != null) {
    removeBrandCarLayout(layoutId);
  }
  carPlayPreviewQueue.value = carPlayPreviewQueue.value
      .map((widget) => widget?.id == removedWidget.id ? null : widget)
      .toList();
  _previewSelectionOrder.remove(removedWidget.id);
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
}) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .86),
  builder: (_) => _WidgetPreviewDialog(initialIndex: initialIndex),
);

Future<void> showSavedWidgetPreview(
  BuildContext context,
  SavedWidgetModel widget,
) {
  final index = _savedWidgets.value.indexWhere(
    (savedWidget) => savedWidget.id == widget.id,
  );
  if (index < 0) return Future<void>.value();
  return _showWidgetPreview(context, initialIndex: index);
}

Future<void> showFirstSavedWidgetPreview(BuildContext context) {
  if (_savedWidgets.value.isEmpty) return Future<void>.value();
  return _showWidgetPreview(context, initialIndex: 0);
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

    final widget = SavedWidgetModel(
      id: 'photo_${DateTime.now().microsecondsSinceEpoch}',
      label: 'PHOTO',
      imageBytes: croppedImageBytes,
    );
    _savedWidgets.value = [..._savedWidgets.value, widget];
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
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MyWidgetsPage()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 8,
                ),
                child: Text(
                  'See All',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
        builder: (context, widgets, _) => GridView.builder(
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
                    widgetId: widget.id,
                    layoutId: widget.layoutId,
                    onTap: () =>
                        _showWidgetPreview(context, initialIndex: index),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
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
                          widgetId: widgets[index - 1].id,
                          layoutId: widgets[index - 1].layoutId,
                          onTap: () => _showWidgetPreview(
                            context,
                            initialIndex: index - 1,
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
    foregroundPainter: _DashedBorderPainter(),
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
              width: 66,
              height: 66,
              child: Stack(
                children: [
                  Positioned(
                    left: 18,
                    top: 7,
                    child: Transform.rotate(
                      angle: .12,
                      child: Container(
                        width: 47,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF008C61),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 3,
                    child: Transform.rotate(
                      angle: -.12,
                      child: Container(
                        width: 47,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.background,
                          size: 38,
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
      ..strokeWidth = 2.5;

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
    required this.widgetId,
    required this.child,
    this.layoutId,
    this.onTap,
  });

  final String widgetId;
  final Widget child;
  final String? layoutId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SavedWidgetModel?>>(
        valueListenable: carPlayPreviewQueue,
        builder: (context, selectedWidgets, _) {
          final isSelected = selectedWidgets.any(
            (widget) => widget?.id == widgetId,
          );
          return ValueListenableBuilder<Map<String, BrandCarLayout>>(
            valueListenable: brandCarLayouts,
            builder: (context, layouts, _) {
              final layout = layoutId == null ? null : layouts[layoutId];
              final customBorderColor = layout?.borderColorValue;
              final borderColor = customBorderColor != null
                  ? Color(
                      customBorderColor,
                    ).withValues(alpha: layout!.borderOpacity)
                  : isSelected
                  ? AppColors.green
                  : const Color(0xFF303940);
              final borderWidth = customBorderColor != null
                  ? math.min(layout!.borderWidth, 1.5)
                  : isSelected
                  ? 2.0
                  : 1.0;
              return Material(
                color: const Color(0xFF20272D),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Center(child: child),
                  ),
                ),
              );
            },
          );
        },
      );
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

    if (widget.id.startsWith('brand_car_')) {
      return _BrandCarArtwork(
        widget: widget,
        layoutId: layoutId ?? widget.layoutId ?? widget.id,
        isEditable: isEditable,
      );
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
          final inset = isEditable || layouts.containsKey(layoutId)
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
                      fontSize: 16,
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
                      fontSize: 15 * layout.brandScale,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          cityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isEditable &&
                    layout.borderColorValue != null &&
                    layout.borderWidth > 0)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Color(
                                layout.borderColorValue!,
                              ).withValues(alpha: layout.borderOpacity),
                              width: math.min(layout.borderWidth, 1.5),
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

class _WidgetPreviewDialog extends StatefulWidget {
  const _WidgetPreviewDialog({required this.initialIndex});

  final int initialIndex;

  @override
  State<_WidgetPreviewDialog> createState() => _WidgetPreviewDialogState();
}

class _WidgetPreviewDialogState extends State<_WidgetPreviewDialog> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<SavedWidgetModel>>(
    valueListenable: _savedWidgets,
    builder: (context, widgets, _) {
      if (widgets.isEmpty) return const SizedBox.shrink();

      final currentIndex = _currentIndex.clamp(0, widgets.length - 1);
      final currentWidget = widgets[currentIndex];
      final screenSize = MediaQuery.sizeOf(context);

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
                        onPressed: () => _showPreviewInfo(context),
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
                    'This only updates the preview. CarPlay setup is done separately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.35),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, stageConstraints) {
                      final previewSize =
                          math
                              .max(
                                0.0,
                                math.min(
                                  360.0,
                                  math.min(
                                    screenSize.width - 72,
                                    stageConstraints.maxHeight - 42,
                                  ),
                                ),
                              )
                              .toDouble() *
                          .7;
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox.square(
                                dimension: previewSize,
                                child: _SavedWidgetCard(
                                  widgetId: currentWidget.id,
                                  layoutId: currentWidget.layoutId,
                                  child: SavedWidgetArtwork(
                                    widget: currentWidget,
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
                                      onTap: () =>
                                          setState(() => _currentIndex = index),
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
                                  ? () => setState(() => _currentIndex--)
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
                                  ? () => setState(() => _currentIndex++)
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
                    ),
                    child: const Text(
                      'Select Widget',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => _showEditNotice(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Edit Widget',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

  void _showPreviewInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: const Text(
          'This only updates the preview. CarPlay setup is done separately.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showEditNotice(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Widget editing is coming soon.')),
      );
  }
}
