import 'dart:math' as math;

import 'package:flutter/material.dart';

class SynthwaveArtwork extends StatelessWidget {
  const SynthwaveArtwork({super.key, required this.synthwaveId});

  final String synthwaveId;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SynthwavePainter(synthwaveId),
    child: const SizedBox.expand(),
  );
}

class SynthwaveArtworkFrame extends StatelessWidget {
  const SynthwaveArtworkFrame({
    super.key,
    required this.synthwaveId,
    required this.borderGradientColors,
    this.borderColor = const Color(0xFF39424A),
    this.borderWidth = 1.5,
    this.borderRadius = 20,
  });

  final String synthwaveId;
  final List<Color>? borderGradientColors;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(borderGradientColors == null ? borderWidth : 2),
    decoration: BoxDecoration(
      color: borderGradientColors == null ? borderColor : null,
      gradient: borderGradientColors == null
          ? null
          : LinearGradient(colors: borderGradientColors!),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius - 2),
      child: SynthwaveArtwork(synthwaveId: synthwaveId),
    ),
  );
}

class _SynthwavePainter extends CustomPainter {
  const _SynthwavePainter(this.synthwaveId);

  final String synthwaveId;

  static const _cityVariants = {2, 3, 5, 7, 9, 10};
  static const _mountainVariants = {1, 4, 6, 8, 10};
  static const _palmVariants = {3, 4, 7, 8};
  static const _wheelVariants = {1, 5, 10};
  static const _carPositions = <int, (double, double)>{
    1: (.5, .83),
    2: (.5, .79),
    3: (.59, .83),
    4: (.5, .83),
    5: (.38, .84),
    6: (.64, .82),
    7: (.42, .82),
    8: (.5, .85),
    9: (.61, .8),
    10: (.5, .84),
  };

  int get _variant {
    final parsed = int.tryParse(synthwaveId.split('_').last) ?? 1;
    return ((parsed - 1) % 10) + 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final horizon =
        size.height *
        switch (_variant) {
          2 => .52,
          5 => .49,
          6 => .61,
          7 => .53,
          8 => .47,
          9 => .55,
          10 => .58,
          _ => .56,
        };
    final accent = switch (_variant) {
      2 || 4 || 6 || 7 || 9 => const Color(0xFF35E3F7),
      5 => const Color(0xFFFFA14A),
      8 => const Color(0xFFFF4FB8),
      10 => const Color(0xFFFFD166),
      _ => const Color(0xFFFF2E91),
    };
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF180D43), Color(0xFF4A1F73), Color(0xFF151028)],
          stops: [0, .54, 1],
        ).createShader(rect),
    );

    _drawStars(canvas, size);
    _drawSun(canvas, size, horizon, accent);
    if (_cityVariants.contains(_variant)) {
      _drawCity(canvas, size, horizon, accent);
    }
    if (_mountainVariants.contains(_variant)) {
      _drawMountains(canvas, size, horizon, accent);
    }
    if (_palmVariants.contains(_variant)) {
      _drawPalmTrees(canvas, size, horizon);
    }
    _drawPerspectiveGrid(canvas, size, horizon, accent);
    if (_wheelVariants.contains(_variant)) _drawDashboardWheel(canvas, size);
    final (carX, carY) = _carPositions[_variant]!;
    _drawCar(canvas, size, accent, carY, centerXFactor: carX);
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE8C4).withValues(alpha: .8);
    for (var index = 0; index < 24; index++) {
      final x = ((index * 47 + _variant * 31) % 101) / 101 * size.width;
      final y = ((index * 29 + _variant * 17) % 43) / 100 * size.height;
      canvas.drawCircle(Offset(x, y), size.shortestSide * .006, paint);
    }
  }

  void _drawSun(Canvas canvas, Size size, double horizon, Color accent) {
    final sunX = switch (_variant) {
      3 || 7 => .62,
      5 || 8 => .38,
      9 => .46,
      10 => .57,
      _ => .5,
    };
    final center = Offset(
      size.width * sunX,
      horizon - size.height * (_variant == 6 ? .06 : .1),
    );
    final radius = size.shortestSide * (_variant == 8 ? .25 : .28);
    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(circle);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEC74), Color(0xFFFF984E), Color(0xFFE53B96)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final stripePaint = Paint()..color = const Color(0xFF32134E);
    for (var index = 0; index < 7; index++) {
      final y = center.dy + radius * (.23 + index * .12);
      final stripeHeight = radius * (index < 2 ? .035 : .055);
      canvas.drawRect(
        Rect.fromLTWH(center.dx - radius, y, radius * 2, stripeHeight),
        stripePaint,
      );
    }
    canvas.restore();
    canvas.drawLine(
      Offset(0, horizon),
      Offset(size.width, horizon),
      Paint()
        ..color = accent.withValues(alpha: .75)
        ..strokeWidth = size.height * .009,
    );
  }

  void _drawMountains(Canvas canvas, Size size, double horizon, Color accent) {
    final firstPeakX = switch (_variant) {
      6 => .34,
      8 => .62,
      10 => .25,
      _ => .22,
    };
    final secondPeakX = switch (_variant) {
      6 => .72,
      8 => .38,
      10 => .69,
      _ => .54,
    };
    final left = Path()
      ..moveTo(0, horizon + size.height * .07)
      ..lineTo(size.width * firstPeakX, horizon - size.height * .13)
      ..lineTo(size.width * (firstPeakX + .17), horizon + size.height * .08)
      ..lineTo(size.width * secondPeakX, horizon - size.height * .03)
      ..lineTo(size.width * (secondPeakX + .16), horizon + size.height * .09)
      ..lineTo(0, horizon + size.height * .12)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFF21153F));
    final ridgePaint = Paint()
      ..color = accent.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .012;
    canvas.drawLine(
      Offset(size.width * firstPeakX, horizon - size.height * .13),
      Offset(size.width * (firstPeakX + .17), horizon + size.height * .08),
      ridgePaint,
    );
    canvas.drawLine(
      Offset(size.width * secondPeakX, horizon - size.height * .03),
      Offset(size.width * (secondPeakX + .16), horizon + size.height * .09),
      ridgePaint,
    );
  }

  void _drawCity(Canvas canvas, Size size, double horizon, Color accent) {
    final baseY = horizon + size.height * (_variant == 5 ? .11 : .07);
    final colors = [
      const Color(0xFF21183E),
      const Color(0xFF30204B),
      const Color(0xFF17152E),
    ];
    for (var index = 0; index < 13; index++) {
      final width = size.width * (.045 + (index % 3) * .012);
      final height =
          size.height * (.1 + ((index * 7 + _variant * 3) % 9) * .019);
      final x = index * size.width / 12 - width / 2;
      final building = Rect.fromLTWH(x, baseY - height, width, height);
      canvas.drawRect(building, Paint()..color = colors[index % colors.length]);
      final windowPaint = Paint()
        ..color = accent.withValues(alpha: .65)
        ..strokeWidth = size.shortestSide * .008;
      for (var row = 0; row < 3; row++) {
        final y = building.top + height * (.22 + row * .22);
        canvas.drawLine(
          Offset(building.left + width * .27, y),
          Offset(building.right - width * .27, y),
          windowPaint,
        );
      }
    }
  }

  void _drawPalmTrees(Canvas canvas, Size size, double horizon) {
    final paint = Paint()
      ..color = const Color(0xFF160F2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .025
      ..strokeCap = StrokeCap.round;
    for (final side in [-1, 1]) {
      final base = Offset(
        side < 0 ? size.width * .11 : size.width * .89,
        horizon + size.height * .13,
      );
      final top = base.translate(-side * size.width * .035, -size.height * .32);
      canvas.drawLine(base, top, paint);
      for (var index = 0; index < 5; index++) {
        final direction = (index - 2) * .55;
        final tip = Offset(
          top.dx + math.sin(direction) * size.width * .22,
          top.dy + (index.isEven ? -1 : 1) * size.height * .055,
        );
        final frond = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(
            top.dx + math.sin(direction) * size.width * .1,
            top.dy - size.height * .11,
            tip.dx,
            tip.dy,
          );
        canvas.drawPath(frond, paint);
      }
    }
  }

  void _drawPerspectiveGrid(
    Canvas canvas,
    Size size,
    double horizon,
    Color accent,
  ) {
    final paint = Paint()
      ..color = accent.withValues(alpha: .78)
      ..strokeWidth = size.shortestSide * .008;
    final vanishX = switch (_variant) {
      3 || 7 => .58,
      5 || 8 => .4,
      6 => .62,
      9 => .46,
      _ => .5,
    };
    final vanish = Offset(size.width * vanishX, horizon);
    for (var index = -6; index <= 6; index++) {
      canvas.drawLine(
        vanish,
        Offset(size.width * (.5 + index * .13), size.height),
        paint,
      );
    }
    for (var index = 0; index < 7; index++) {
      final progress = (index + 1) / 8;
      final y = horizon + (size.height - horizon) * progress * progress;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDashboardWheel(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (_variant == 5 ? .84 : .16),
      size.height * (_variant == 10 ? .88 : .91),
    );
    final radius = size.shortestSide * (_variant == 10 ? .22 : .27);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF100F23)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * .09,
    );
    canvas.drawCircle(
      center,
      radius * .72,
      Paint()
        ..color = const Color(0xFFFF2E91)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * .018,
    );
  }

  void _drawCar(
    Canvas canvas,
    Size size,
    Color accent,
    double verticalPosition, {
    required double centerXFactor,
  }) {
    final centerX = size.width * centerXFactor;
    final y = size.height * verticalPosition;
    final carWidth = size.width * .55;
    final carHeight = size.height * .22;
    final body = Path()
      ..moveTo(centerX - carWidth * .5, y + carHeight * .38)
      ..lineTo(centerX - carWidth * .38, y + carHeight * .06)
      ..lineTo(centerX - carWidth * .2, y - carHeight * .33)
      ..quadraticBezierTo(
        centerX,
        y - carHeight * .52,
        centerX + carWidth * .2,
        y - carHeight * .33,
      )
      ..lineTo(centerX + carWidth * .38, y + carHeight * .06)
      ..lineTo(centerX + carWidth * .5, y + carHeight * .38)
      ..lineTo(centerX + carWidth * .42, y + carHeight * .53)
      ..lineTo(centerX - carWidth * .42, y + carHeight * .53)
      ..close();
    canvas.drawShadow(body, Colors.black, size.shortestSide * .05, true);
    canvas.drawPath(body, Paint()..color = const Color(0xFF11152F));
    canvas.drawPath(
      body,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * .018,
    );
    final windshield = Path()
      ..moveTo(centerX - carWidth * .22, y - carHeight * .27)
      ..quadraticBezierTo(
        centerX,
        y - carHeight * .4,
        centerX + carWidth * .22,
        y - carHeight * .27,
      )
      ..lineTo(centerX + carWidth * .3, y + carHeight * .04)
      ..lineTo(centerX - carWidth * .3, y + carHeight * .04)
      ..close();
    canvas.drawPath(windshield, Paint()..color = const Color(0xFF29285A));
    final lightPaint = Paint()
      ..color = const Color(0xFFFFE176)
      ..strokeWidth = size.shortestSide * .025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX - carWidth * .42, y + carHeight * .3),
      Offset(centerX - carWidth * .26, y + carHeight * .3),
      lightPaint,
    );
    canvas.drawLine(
      Offset(centerX + carWidth * .26, y + carHeight * .3),
      Offset(centerX + carWidth * .42, y + carHeight * .3),
      lightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SynthwavePainter oldDelegate) =>
      synthwaveId != oldDelegate.synthwaveId;
}
