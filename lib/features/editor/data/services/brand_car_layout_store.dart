import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:flutter/foundation.dart';

final brandCarLayouts = ValueNotifier<Map<String, BrandCarLayout>>({});

String brandCarDraftLayoutId(String widgetId) => 'draft:$widgetId';

BrandCarLayout brandCarLayoutFor(String widgetId) =>
    brandCarLayouts.value[widgetId] ?? const BrandCarLayout();

void setBrandCarElementPosition(
  String widgetId,
  BrandCarElement element,
  WidgetElementPosition position,
) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[widgetId] = brandCarLayoutFor(
    widgetId,
  ).withPosition(element, position);
  brandCarLayouts.value = layouts;
}

void setBrandCarBrandScale(String layoutId, double scale) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(layoutId).withBrandScale(scale);
  brandCarLayouts.value = layouts;
}

void setBrandCarImage(String layoutId, int imageIndex) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(layoutId).withCarImageIndex(imageIndex);
  brandCarLayouts.value = layouts;
}

void setBrandCarCustomImage(String layoutId, Uint8List bytes) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(layoutId).withCarImageBytes(bytes);
  brandCarLayouts.value = layouts;
}

void setBrandCarImageScale(String layoutId, double scale) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(layoutId).withCarScale(scale);
  brandCarLayouts.value = layouts;
}

void setBrandCarGreetingNickname(String layoutId, String nickname) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(
    layoutId,
  ).withGreetingNickname(nickname);
  brandCarLayouts.value = layouts;
}

void setBrandCarGreetingFont(String layoutId, int fontIndex) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(
    layoutId,
  ).withGreetingFontIndex(fontIndex);
  brandCarLayouts.value = layouts;
}

void setBrandCarGreetingColor(String layoutId, int colorValue) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(
    layoutId,
  ).withGreetingColorValue(colorValue);
  brandCarLayouts.value = layouts;
}

void setBrandCarBorderGradient(String layoutId, int? gradientIndex) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(
    layoutId,
  ).withBorderGradientIndex(gradientIndex);
  brandCarLayouts.value = layouts;
}

void setBrandCarBorderOpacity(String layoutId, double opacity) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
  layouts[layoutId] = brandCarLayoutFor(layoutId).withBorderOpacity(opacity);
  brandCarLayouts.value = layouts;
}

void resetBrandCarWidgetLayout(String widgetId) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value)
    ..remove(widgetId);
  brandCarLayouts.value = layouts;
}

void removeBrandCarLayout(String layoutId) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value)
    ..remove(layoutId);
  brandCarLayouts.value = layouts;
}

void copyBrandCarLayout(String sourceId, String destinationId) {
  final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value)
    ..[destinationId] = brandCarLayoutFor(sourceId);
  brandCarLayouts.value = layouts;
}
