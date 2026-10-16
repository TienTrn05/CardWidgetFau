import 'package:carwidget/features/cards/data/car_catalog.dart';
import 'package:carwidget/features/catalog/data/models/widget_type.dart';
import 'package:flutter/material.dart';

const logoBorderGradients = <List<Color>>[
  [Color(0xFF00C6FF), Color(0xFF0072FF)],
  [Color(0xFFFF5F6D), Color(0xFFFFC371)],
  [Color(0xFFFF8A00), Color(0xFFFF3D00)],
  [Color(0xFF4776E6), Color(0xFF8E54E9)],
  [Color(0xFFA8E063), Color(0xFF56AB2F)],
  [Color(0xFFFFD194), Color(0xFFFFB000)],
  [Color(0xFFFF416C), Color(0xFFFF4B2B)],
  [Color(0xFFB721FF), Color(0xFF21D4FD)],
];

class LogoWidgetModel {
  const LogoWidgetModel({
    required this.id,
    required this.nameLogo,
    required this.symbol,
    required this.type,
    this.imageAsset,
  });

  final String id;
  final String? imageAsset;
  final String nameLogo;
  final String symbol;
  final WidgetType type;
}

const _logoSymbols = <String, String>{
  'Abarth': 'A',
  'Acura': 'A',
  'Aiways': 'AIWAYS',
  'Alfa Romeo': 'AR',
  'Audi': 'A',
  'BMW': 'BMW',
  'BAIC': 'BAIC',
  'BYD': 'BYD',
  'Citroën': 'C',
  'MINI': 'MINI',
  'Mercedes-Benz': 'MB',
};

final logoWidgetModels = List<LogoWidgetModel>.unmodifiable(
  carBrandNames.map(
    (name) => LogoWidgetModel(
      id: 'logo_${_logoSlug(name)}',
      nameLogo: name,
      symbol: _logoSymbols[name] ?? _logoInitials(name),
      type: WidgetType.logoAndName,
    ),
  ),
);

String _logoSlug(String name) => name
    .toLowerCase()
    .replaceAll('ë', 'e')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

String _logoInitials(String name) => name
    .split(RegExp(r'[\s-]+'))
    .where((word) => word.isNotEmpty)
    .take(2)
    .map((word) => word[0].toUpperCase())
    .join();
