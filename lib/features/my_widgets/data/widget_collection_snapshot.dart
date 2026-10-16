import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';

class WidgetCollectionSnapshot {
  const WidgetCollectionSnapshot({
    required this.widgets,
    required this.videos,
    required this.layouts,
    required this.previewSlots,
    required this.selectionOrder,
  });

  final List<SavedWidgetModel> widgets;
  final List<SavedWidgetModel> videos;
  final Map<String, BrandCarLayout> layouts;
  final List<SavedWidgetModel?> previewSlots;
  final List<String> selectionOrder;

  Map<String, dynamic> toJson(LocalStateStore store) {
    Map<String, dynamic> encodeWidget(SavedWidgetModel widget) =>
        widget.toJson()
          ..['videoPath'] = store.relativeMediaPath(widget.videoPath);
    final layoutIds = [
      ...widgets,
      ...videos,
    ].map((widget) => widget.layoutId).toSet();
    final selectedIds = previewSlots
        .whereType<SavedWidgetModel>()
        .map((widget) => widget.id)
        .toSet();
    return {
      'widgets': widgets.map(encodeWidget).toList(),
      'videos': videos.map(encodeWidget).toList(),
      'layouts': {
        for (final entry in layouts.entries)
          if (layoutIds.contains(entry.key)) entry.key: entry.value.toJson(),
      },
      'previewSlots': previewSlots.map((widget) => widget?.id).toList(),
      'selectionOrder': [
        ...selectionOrder.where(selectedIds.contains),
        ...selectedIds.where((id) => !selectionOrder.contains(id)),
      ],
    };
  }

  factory WidgetCollectionSnapshot.fromJson(
    Map<String, dynamic> json,
    LocalStateStore store,
  ) {
    List<SavedWidgetModel> decodeWidgets(String key) =>
        (json[key] as List? ?? []).map((value) {
          final data = Map<String, dynamic>.from(value as Map);
          data['videoPath'] = store.resolveMediaPath(
            data['videoPath'] as String?,
          );
          return SavedWidgetModel.fromJson(data);
        }).toList();
    final widgets = decodeWidgets('widgets');
    final videos = decodeWidgets('videos');
    final byId = {
      for (final widget in [...widgets, ...videos]) widget.id: widget,
    };
    final slotIds = json['previewSlots'] as List? ?? [];
    final slots = List<SavedWidgetModel?>.generate(
      2,
      (index) => index < slotIds.length ? byId[slotIds[index]] : null,
    );
    final selectedIds = slots
        .whereType<SavedWidgetModel>()
        .map((widget) => widget.id)
        .toSet();
    final order = (json['selectionOrder'] as List? ?? [])
        .cast<String>()
        .where(selectedIds.contains)
        .toSet()
        .toList();
    order.addAll(selectedIds.where((id) => !order.contains(id)));
    return WidgetCollectionSnapshot(
      widgets: widgets,
      videos: videos,
      layouts: (json['layouts'] as Map? ?? {}).map(
        (key, value) => MapEntry(
          key as String,
          BrandCarLayout.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      previewSlots: slots,
      selectionOrder: order,
    );
  }
}
