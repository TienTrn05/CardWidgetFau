import 'dart:convert';

import 'package:flutter/services.dart';

class WidgetTutorialContent {
  const WidgetTutorialContent({
    required this.title,
    required this.stepLabel,
    required this.imagePlaceholderLabel,
    required this.noteLabel,
    required this.tabs,
  });

  final String title;
  final String stepLabel;
  final String imagePlaceholderLabel;
  final String noteLabel;
  final List<WidgetTutorialTab> tabs;

  static WidgetTutorialContent? _cached;

  static WidgetTutorialContent? get cached => _cached;

  static Future<WidgetTutorialContent> load() async {
    if (_cached != null) return _cached!;
    final source = await rootBundle.loadString(
      'assets/data/widget_tutorial.json',
    );
    return _cached = WidgetTutorialContent.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  factory WidgetTutorialContent.fromJson(Map<String, dynamic> json) =>
      WidgetTutorialContent(
        title: json['title'] as String,
        stepLabel: json['stepLabel'] as String,
        imagePlaceholderLabel: json['imagePlaceholderLabel'] as String,
        noteLabel: json['noteLabel'] as String,
        tabs: (json['tabs'] as List<dynamic>)
            .map(
              (tab) => WidgetTutorialTab.fromJson(tab as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class WidgetTutorialTab {
  const WidgetTutorialTab({
    required this.id,
    required this.title,
    required this.steps,
    required this.note,
  });

  final String id;
  final String title;
  final List<WidgetTutorialStep> steps;
  final String? note;

  factory WidgetTutorialTab.fromJson(Map<String, dynamic> json) =>
      WidgetTutorialTab(
        id: json['id'] as String,
        title: json['title'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map(
              (step) =>
                  WidgetTutorialStep.fromJson(step as Map<String, dynamic>),
            )
            .toList(growable: false),
        note: json['note'] as String?,
      );
}

class WidgetTutorialStep {
  const WidgetTutorialStep({required this.instruction, required this.images});

  final String instruction;
  final List<WidgetTutorialImage> images;

  factory WidgetTutorialStep.fromJson(Map<String, dynamic> json) =>
      WidgetTutorialStep(
        instruction: json['instruction'] as String,
        images: (json['images'] as List<dynamic>)
            .map(
              (image) =>
                  WidgetTutorialImage.fromJson(image as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class WidgetTutorialImage {
  const WidgetTutorialImage({
    required this.asset,
    required this.aspectRatio,
    required this.placeholderIcon,
    required this.placeholderTone,
  });

  final String? asset;
  final double aspectRatio;
  final String placeholderIcon;
  final String placeholderTone;

  factory WidgetTutorialImage.fromJson(Map<String, dynamic> json) =>
      WidgetTutorialImage(
        asset: json['asset'] as String?,
        aspectRatio: (json['aspectRatio'] as num).toDouble(),
        placeholderIcon: json['placeholderIcon'] as String,
        placeholderTone: json['placeholderTone'] as String,
      );
}
