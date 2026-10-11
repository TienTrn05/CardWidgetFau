import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:flutter/material.dart';

List<Color> brandCarBorderGradientColors(int gradientIndex, double opacity) =>
    logoBorderGradients[gradientIndex % logoBorderGradients.length]
        .map((color) => color.withValues(alpha: opacity))
        .toList();

class BrandCarPreviewFrame extends StatelessWidget {
  const BrandCarPreviewFrame({
    super.key,
    required this.layoutId,
    required this.child,
    this.contentPadding = const EdgeInsets.all(28),
  });

  final String layoutId;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, BrandCarLayout>>(
        valueListenable: brandCarLayouts,
        builder: (context, layouts, _) {
          final layout = layouts[layoutId];
          final gradientIndex = layout?.borderGradientIndex;
          final colors = gradientIndex == null
              ? null
              : brandCarBorderGradientColors(
                  gradientIndex,
                  layout!.borderOpacity,
                );
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
              child: ColoredBox(
                color: const Color(0xFF252D33),
                child: Padding(padding: contentPadding, child: child),
              ),
            ),
          );
        },
      );
}
