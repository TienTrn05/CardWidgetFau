import 'dart:math' as math;

import 'package:flutter/material.dart';

class CarPlayPreviewDock extends StatelessWidget {
  const CarPlayPreviewDock({
    super.key,
    required this.iconSize,
    this.expanded = false,
  });

  final double iconSize;
  final bool expanded;

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
    padding: EdgeInsets.symmetric(
      vertical: expanded ? 18 : 4,
      horizontal: expanded ? 8 : 5,
    ),
    child: Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '9:41',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: expanded ? 16 : 12,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      color: Colors.white,
                      size: expanded ? 17 : 13,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '5G',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: expanded ? 12 : 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DockIcon(asset: 'assets/images/map.png', size: iconSize),
            SizedBox(height: expanded ? 8 : 4),
            _DockIcon(asset: 'assets/images/music.png', size: iconSize),
            SizedBox(height: expanded ? 8 : 4),
            _DockIcon(asset: 'assets/images/phone.png', size: iconSize),
          ],
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: expanded ? 24 : 18,
              height: expanded ? 24 : 18,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class CarPlayPreviewMockup extends StatelessWidget {
  const CarPlayPreviewMockup({
    super.key,
    required this.previewBuilder,
    required this.onClose,
  });

  final WidgetBuilder previewBuilder;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final landscapeWidth = constraints.maxHeight;
      final landscapeHeight = constraints.maxWidth;
      if (landscapeWidth <= 0 || landscapeHeight <= 0) {
        return const SizedBox.shrink();
      }

      final railWidth = landscapeWidth * .17;
      final dockIconSize = math
          .min(56.0, math.min(railWidth - 16, (landscapeHeight - 140) / 3))
          .clamp(0.0, 56.0);
      final previewSize = math
          .min(landscapeHeight * .58, (landscapeWidth - railWidth - 28) * .66)
          .clamp(0.0, landscapeHeight);

      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF073D92),
                      Color(0xFF64AAB0),
                      Color(0xFF1A9DA3),
                    ],
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: SizedBox(
                      width: landscapeWidth,
                      height: landscapeHeight,
                      child: Row(
                        children: [
                          SizedBox(
                            width: railWidth,
                            child: CarPlayPreviewDock(
                              iconSize: dockIconSize,
                              expanded: true,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Transform.scale(
                                scale: .9,
                                child: SizedBox.square(
                                  dimension: previewSize,
                                  child: previewBuilder(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: IconButton.filledTonal(
                tooltip: 'Minimize preview',
                onPressed: onClose,
                style: IconButton.styleFrom(
                  minimumSize: const Size(34, 34),
                  maximumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0x990B1118),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.zoom_in_map_rounded, size: 22),
              ),
            ),
          ],
        ),
      );
    },
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
