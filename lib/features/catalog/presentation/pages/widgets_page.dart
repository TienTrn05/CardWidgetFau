import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/widget_type.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_section.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/logos_section.dart';
import 'package:carwidget/features/catalog/presentation/widgets/video_widgets_section.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/editor/presentation/widgets/brand_car_border_style.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart';

class WidgetsPage extends StatelessWidget {
  const WidgetsPage({super.key});

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      Text(
        'CAR Widgets Preview',
        style: Theme.of(
          context,
        ).textTheme.headlineLarge?.copyWith(fontSize: 30),
      ),
      const SizedBox(height: 22),
      const _CarPlayPreview(),
      const SizedBox(height: 32),
      const MyWidgetsSection(),
      const SizedBox(height: 30),
      const BrandCarSection(),
      const SizedBox(height: 30),
      const LogosSection(),
      const SizedBox(height: 30),
      const VideoWidgetsSection(),
    ],
  );
}

class _CarPlayPreview extends StatelessWidget {
  const _CarPlayPreview();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth = constraints.maxWidth - 16;
      final railWidth = contentWidth * .17;
      final widgetSize = carPlayWidgetPreviewSize(
        context,
        constraints.maxWidth,
      );
      final cardSize = widgetSize;
      final dockIconSize = math.min(
        38.0,
        math.min(railWidth - 10, (widgetSize - 15) / 3),
      );

      return SizedBox(
        height: widgetSize + 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -18,
              right: -18,
              top: -9,
              bottom: -9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFF647C83), width: 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF073D92),
                      Color(0xFF64AAB0),
                      Color(0xFF1A9DA3),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -13,
              top: 0,
              bottom: 0,
              width: railWidth,
              child: _CarPlayDock(iconSize: dockIconSize),
            ),
            Positioned(
              left: railWidth - 6,
              right: -13,
              top: 0,
              bottom: 0,
              child: ValueListenableBuilder<List<SavedWidgetModel?>>(
                valueListenable: carPlayPreviewQueue,
                builder: (context, queuedWidgets, _) {
                  final firstWidget = queuedWidgets[0];
                  final secondWidget = queuedWidgets[1];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: cardSize,
                        child: _CarPlayWidgetCard(
                          widget: firstWidget,
                          onTap: firstWidget == null
                              ? () => showFirstSavedWidgetPreview(context)
                              : () => showSavedWidgetPreview(
                                  context,
                                  firstWidget,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox.square(
                        dimension: cardSize,
                        child: _CarPlayWidgetCard(
                          widget: secondWidget,
                          onTap: secondWidget == null
                              ? () => showFirstSavedWidgetPreview(context)
                              : () => showSavedWidgetPreview(
                                  context,
                                  secondWidget,
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CarPlayDock extends StatelessWidget {
  const _CarPlayDock({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xC910416D), Color(0x99506F7B), Color(0xA8758380)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
    child: Column(
      children: [
        const Text(
          '9:41',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_cellular_alt, color: Colors.white, size: 13),
            SizedBox(width: 2),
            Text(
              '5G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        _DockIcon(asset: 'assets/images/map.png', size: iconSize),
        const SizedBox(height: 4),
        _DockIcon(asset: 'assets/images/music.png', size: iconSize),
        const SizedBox(height: 4),
        _DockIcon(asset: 'assets/images/phone.png', size: iconSize),
        const Spacer(),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    ),
  );
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    ),
  );
}

class _CarPlayWidgetCard extends StatelessWidget {
  const _CarPlayWidgetCard({this.widget, this.onTap});

  final SavedWidgetModel? widget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: ValueListenableBuilder<Map<String, BrandCarLayout>>(
      valueListenable: brandCarLayouts,
      builder: (context, layouts, _) {
        final brandCarLayout = widget?.layoutId == null
            ? null
            : layouts[widget!.layoutId];
        final brandCarGradientIndex = brandCarLayout?.borderGradientIndex;
        final borderGradientIndex =
            widget?.borderGradientIndex ??
            (widget?.type == WidgetType.carLogoAndName
                ? brandCarGradientIndex
                : null);
        final borderOpacity = widget?.type == WidgetType.carLogoAndName
            ? brandCarLayout?.borderOpacity ?? 1.0
            : widget?.borderOpacity ?? 1.0;
        final gradientColors = borderGradientIndex == null
            ? null
            : widget?.type == WidgetType.carLogoAndName
            ? brandCarBorderGradientColors(borderGradientIndex, borderOpacity)
            : logoBorderGradients[borderGradientIndex %
                      logoBorderGradients.length]
                  .map((color) => color.withValues(alpha: borderOpacity))
                  .toList();

        return Container(
          padding: EdgeInsets.all(gradientColors == null ? 10 : 2),
          decoration: BoxDecoration(
            color: gradientColors != null
                ? null
                : widget == null
                ? const Color(0x22FFFFFF)
                : const Color(0xFF20272D),
            gradient: gradientColors == null
                ? null
                : LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(20),
            border: gradientColors == null
                ? Border.all(color: const Color(0x77FFFFFF), width: 1.2)
                : null,
          ),
          child: Container(
            padding: EdgeInsets.all(gradientColors == null ? 0 : 8),
            decoration: gradientColors == null
                ? null
                : BoxDecoration(
                    color: const Color(0xFF20272D),
                    borderRadius: BorderRadius.circular(18),
                  ),
            child: widget == null
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Preview\nno Widget',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'See your widget will\nlook on CarPlay',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .92),
                              fontSize: 15,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SavedWidgetArtwork(widget: widget!),
                  ),
          ),
        );
      },
    ),
  );
}
