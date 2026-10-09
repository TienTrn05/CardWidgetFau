import 'dart:typed_data';

import 'package:carwidget/features/catalog/data/models/widget_type.dart';

class SavedWidgetModel {
  const SavedWidgetModel({
    required this.id,
    required this.label,
    this.imageBytes,
    this.imageAsset,
    this.layoutId,
    this.type = WidgetType.logoAndName,
    this.borderGradientIndex,
    this.borderOpacity = 1,
    this.symbol,
    this.videoPath,
    this.videoName,
    this.videoStartMs = 0,
    this.videoDurationMs,
    this.videoThumbnail,
  });

  final String id;
  final String label;
  final Uint8List? imageBytes;
  final String? imageAsset;
  final String? layoutId;
  final WidgetType type;
  final int? borderGradientIndex;
  final double borderOpacity;
  final String? symbol;
  final String? videoPath;
  final String? videoName;
  final int videoStartMs;
  final int? videoDurationMs;
  final Uint8List? videoThumbnail;

  String get nameLogo => label;
}

const brandCarWidgetModels = <SavedWidgetModel>[
  SavedWidgetModel(
    id: 'brand_car_fiat',
    label: 'FIAT',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_acura',
    label: 'ACURA',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_porsche',
    label: 'PORSCHE',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_bmw',
    label: 'BMW',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_mercedes',
    label: 'MERCEDES',
    type: WidgetType.carLogoAndName,
  ),
];
