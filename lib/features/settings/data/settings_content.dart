import 'dart:convert';

import 'package:flutter/services.dart';

class SettingsContent {
  const SettingsContent({required this.title, required this.sections});

  final String title;
  final List<SettingsSection> sections;

  static SettingsContent? _cached;

  static SettingsContent? get cached => _cached;

  static Future<SettingsContent> load() async {
    if (_cached != null) return _cached!;
    final source = await rootBundle.loadString('assets/data/settings.json');
    return _cached = SettingsContent.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  factory SettingsContent.fromJson(Map<String, dynamic> json) =>
      SettingsContent(
        title: json['title'] as String,
        sections: (json['sections'] as List<dynamic>)
            .map(
              (section) =>
                  SettingsSection.fromJson(section as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class SettingsSection {
  const SettingsSection({required this.title, required this.items});

  final String title;
  final List<SettingsItem> items;

  factory SettingsSection.fromJson(Map<String, dynamic> json) =>
      SettingsSection(
        title: json['title'] as String,
        items: (json['items'] as List<dynamic>)
            .map((item) => SettingsItem.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class SettingsItem {
  const SettingsItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final String icon;

  factory SettingsItem.fromJson(Map<String, dynamic> json) => SettingsItem(
    id: json['id'] as String,
    title: json['title'] as String,
    icon: json['icon'] as String,
  );
}
