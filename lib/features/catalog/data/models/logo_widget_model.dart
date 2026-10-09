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

const logoWidgetModels = <LogoWidgetModel>[
  LogoWidgetModel(
    id: 'logo_abarth',
    nameLogo: 'Abarth',
    symbol: 'A',
    type: WidgetType.logoAndName,
  ),
  LogoWidgetModel(
    id: 'logo_acura',
    nameLogo: 'Acura',
    symbol: 'A',
    type: WidgetType.logoAndName,
  ),
  LogoWidgetModel(
    id: 'logo_aiways',
    nameLogo: 'Aiways',
    symbol: 'AIWAYS',
    type: WidgetType.logoAndName,
  ),
  LogoWidgetModel(
    id: 'logo_alfa_romeo',
    nameLogo: 'Alfa Romeo',
    symbol: 'AR',
    type: WidgetType.logoAndName,
  ),
  LogoWidgetModel(
    id: 'logo_audi',
    nameLogo: 'Audi',
    symbol: 'A',
    type: WidgetType.logoAndName,
  ),
  LogoWidgetModel(
    id: 'logo_bmw',
    nameLogo: 'BMW',
    symbol: 'BMW',
    type: WidgetType.logoAndName,
  ),
];
