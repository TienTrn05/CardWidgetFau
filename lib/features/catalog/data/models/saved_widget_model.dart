import 'dart:convert';
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
    this.countryFlagCode,
    this.footballTeamId,
    this.synthwaveId,
    this.affirmationText,
    this.affirmationDate,
    this.affirmationTextColorValue = 0xFF211917,
    this.affirmationBackgroundColorValue = 0xFFF5D9CF,
    this.affirmationEyebrow,
    this.affirmationStyleIndex = 0,
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
  final String? countryFlagCode;
  final String? footballTeamId;
  final String? synthwaveId;
  final String? affirmationText;
  final DateTime? affirmationDate;
  final int affirmationTextColorValue;
  final int affirmationBackgroundColorValue;
  final String? affirmationEyebrow;
  final int affirmationStyleIndex;
  final String? videoPath;
  final String? videoName;
  final int videoStartMs;
  final int? videoDurationMs;
  final Uint8List? videoThumbnail;

  String get nameLogo => label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    'imageBytes': imageBytes == null ? null : base64Encode(imageBytes!),
    'imageAsset': imageAsset,
    'layoutId': layoutId,
    'borderGradientIndex': borderGradientIndex,
    'borderOpacity': borderOpacity,
    'symbol': symbol,
    'countryFlagCode': countryFlagCode,
    'footballTeamId': footballTeamId,
    'synthwaveId': synthwaveId,
    'affirmationText': affirmationText,
    'affirmationDate': affirmationDate?.toIso8601String(),
    'affirmationTextColorValue': affirmationTextColorValue,
    'affirmationBackgroundColorValue': affirmationBackgroundColorValue,
    'affirmationEyebrow': affirmationEyebrow,
    'affirmationStyleIndex': affirmationStyleIndex,
    'videoPath': videoPath,
    'videoName': videoName,
    'videoStartMs': videoStartMs,
    'videoDurationMs': videoDurationMs,
    'videoThumbnail': videoThumbnail == null
        ? null
        : base64Encode(videoThumbnail!),
  };

  factory SavedWidgetModel.fromJson(Map<String, dynamic> json) =>
      SavedWidgetModel(
        id: json['id'] as String,
        label: json['label'] as String,
        type: WidgetType.values.byName(json['type'] as String),
        imageBytes: json['imageBytes'] == null
            ? null
            : base64Decode(json['imageBytes'] as String),
        imageAsset: json['imageAsset'] as String?,
        layoutId: json['layoutId'] as String?,
        borderGradientIndex: json['borderGradientIndex'] as int?,
        borderOpacity: (json['borderOpacity'] as num?)?.toDouble() ?? 1,
        symbol: json['symbol'] as String?,
        countryFlagCode: json['countryFlagCode'] as String?,
        footballTeamId: json['footballTeamId'] as String?,
        synthwaveId: json['synthwaveId'] as String?,
        affirmationText: json['affirmationText'] as String?,
        affirmationDate: json['affirmationDate'] == null
            ? null
            : DateTime.parse(json['affirmationDate'] as String),
        affirmationTextColorValue:
            json['affirmationTextColorValue'] as int? ?? 0xFF211917,
        affirmationBackgroundColorValue:
            json['affirmationBackgroundColorValue'] as int? ?? 0xFFF5D9CF,
        affirmationEyebrow: json['affirmationEyebrow'] as String?,
        affirmationStyleIndex: json['affirmationStyleIndex'] as int? ?? 0,
        videoPath: json['videoPath'] as String?,
        videoName: json['videoName'] as String?,
        videoStartMs: json['videoStartMs'] as int? ?? 0,
        videoDurationMs: json['videoDurationMs'] as int?,
        videoThumbnail: json['videoThumbnail'] == null
            ? null
            : base64Decode(json['videoThumbnail'] as String),
      );
}

const brandCarWidgetModels = <SavedWidgetModel>[
  SavedWidgetModel(
    id: 'brand_car_abarth',
    label: 'ABARTH',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_acura',
    label: 'ACURA',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_aiways',
    label: 'AIWAYS',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_alfa_romeo',
    label: 'ALFA ROMEO',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_alpine',
    label: 'ALPINE',
    type: WidgetType.carLogoAndName,
  ),
  SavedWidgetModel(
    id: 'brand_car_aston_martin',
    label: 'ASTON MARTIN',
    type: WidgetType.carLogoAndName,
  ),
];
