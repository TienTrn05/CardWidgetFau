import 'dart:math' as math;

import 'package:flutter/material.dart';

class CountryFlagArtwork extends StatelessWidget {
  const CountryFlagArtwork({super.key, required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CountryFlagPainter(countryCode),
    child: const SizedBox.expand(),
  );
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

class _CountryFlagPainter extends CustomPainter {
  const _CountryFlagPainter(this.countryCode);

  final String countryCode;

  @override
  void paint(Canvas canvas, Size size) {
    switch (countryCode) {
      case 'pt':
        _paintPortugal(canvas, size);
        break;
      case 'al':
        _paintAlbania(canvas, size);
        break;
      case 'dz':
        _paintAlgeria(canvas, size);
        break;
    }
  }

  void _paintPortugal(Canvas canvas, Size size) {
    _fill(canvas, size, const Color(0xFF046A38));
    canvas.drawRect(
      Rect.fromLTWH(size.width * .4, 0, size.width * .6, size.height),
      Paint()..color = const Color(0xFFDA001F),
    );
    final center = Offset(size.width * .4, size.height * .5);
    canvas.drawCircle(
      center,
      size.shortestSide * .19,
      Paint()..color = const Color(0xFFFFD447),
    );
    canvas.drawCircle(
      center,
      size.shortestSide * .105,
      Paint()..color = const Color(0xFFDA001F),
    );
    final emblem = Paint()
      ..color = const Color(0xFFFFD447)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .025;
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.shortestSide * .24,
        height: size.shortestSide * .3,
      ),
      emblem,
    );
  }

  void _paintAlbania(Canvas canvas, Size size) {
    _fill(canvas, size, const Color(0xFFE4002B));
    final center = Offset(size.width * .5, size.height * .5);
    final scale = size.shortestSide;
    final eagle = Path()
      ..moveTo(center.dx, center.dy - scale * .04)
      ..cubicTo(
        center.dx - scale * .18,
        center.dy - scale * .2,
        center.dx - scale * .35,
        center.dy - scale * .2,
        center.dx - scale * .43,
        center.dy - scale * .24,
      )
      ..lineTo(center.dx - scale * .34, center.dy - scale * .1)
      ..lineTo(center.dx - scale * .43, center.dy - scale * .08)
      ..lineTo(center.dx - scale * .27, center.dy + scale * .02)
      ..lineTo(center.dx - scale * .37, center.dy + scale * .14)
      ..lineTo(center.dx - scale * .19, center.dy + scale * .1)
      ..lineTo(center.dx - scale * .11, center.dy + scale * .27)
      ..lineTo(center.dx, center.dy + scale * .15)
      ..lineTo(center.dx + scale * .11, center.dy + scale * .27)
      ..lineTo(center.dx + scale * .19, center.dy + scale * .1)
      ..lineTo(center.dx + scale * .37, center.dy + scale * .14)
      ..lineTo(center.dx + scale * .27, center.dy + scale * .02)
      ..lineTo(center.dx + scale * .43, center.dy - scale * .08)
      ..lineTo(center.dx + scale * .34, center.dy - scale * .1)
      ..lineTo(center.dx + scale * .43, center.dy - scale * .24)
      ..cubicTo(
        center.dx + scale * .25,
        center.dy - scale * .19,
        center.dx + scale * .14,
        center.dy - scale * .16,
        center.dx,
        center.dy - scale * .04,
      )
      ..close();
    canvas.drawPath(eagle, Paint()..color = const Color(0xFF111820));
    canvas.drawCircle(
      Offset(center.dx, center.dy - scale * .18),
      scale * .085,
      Paint()..color = const Color(0xFF111820),
    );
  }

  void _paintAlgeria(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & Size(size.width * .5, size.height),
      Paint()..color = const Color(0xFF006233),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .5, 0, size.width * .5, size.height),
      Paint()..color = const Color(0xFFF8F8F4),
    );
    final center = Offset(size.width * .51, size.height * .5);
    final radius = size.shortestSide * .2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFD21034));
    canvas.drawCircle(
      center.translate(radius * .34, -radius * .18),
      radius * .82,
      Paint()..color = const Color(0xFFF8F8F4),
    );
    final star = Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final radiusAtPoint = point.isEven ? radius * .62 : radius * .27;
      final offset = Offset(
        center.dx + math.cos(angle) * radiusAtPoint,
        center.dy + math.sin(angle) * radiusAtPoint,
      );
      if (point == 0) {
        star.moveTo(offset.dx, offset.dy);
      } else {
        star.lineTo(offset.dx, offset.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xFFD21034));
  }

  void _fill(Canvas canvas, Size size, Color color) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = color);

  @override
  bool shouldRepaint(covariant _CountryFlagPainter oldDelegate) =>
      countryCode != oldDelegate.countryCode;
}
