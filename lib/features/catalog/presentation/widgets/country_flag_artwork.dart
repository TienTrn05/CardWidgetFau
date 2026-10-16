import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/country_flag_model.dart';

class CountryFlagArtwork extends StatelessWidget {
  const CountryFlagArtwork({super.key, required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    for (final flag in countryFlagModels) {
      if (flag.code == countryCode) {
        return SizedBox.expand(
          child: Image.asset(flag.imageAsset, fit: BoxFit.cover),
        );
      }
    }
    return const SizedBox.expand();
  }
}

class CountryFlagArtworkFrame extends StatelessWidget {
  const CountryFlagArtworkFrame({
    super.key,
    required this.countryCode,
    required this.borderGradientColors,
    this.borderColor = const Color(0xFF39424A),
    this.borderWidth = 2,
    this.borderRadius = 24,
  });

  final String countryCode;
  final List<Color>? borderGradientColors;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _CountryFlagBorderPainter(
      colors: borderGradientColors,
      color: borderColor,
      width: borderWidth,
      radius: borderRadius,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.expand(
        child: CountryFlagArtwork(countryCode: countryCode),
      ),
    ),
  );
}

class _CountryFlagBorderPainter extends CustomPainter {
  const _CountryFlagBorderPainter({
    required this.colors,
    required this.color,
    required this.width,
    required this.radius,
  });

  final List<Color>? colors;
  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final borderRect = bounds.deflate(width / 2);
    if (borderRect.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    if (colors != null) {
      paint.shader = LinearGradient(colors: colors!).createShader(bounds);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        borderRect,
        Radius.circular(math.max(0, radius - width / 2)),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountryFlagBorderPainter oldDelegate) =>
      colors != oldDelegate.colors ||
      color != oldDelegate.color ||
      width != oldDelegate.width ||
      radius != oldDelegate.radius;
}
