import 'dart:math' as math;

import 'package:flutter/material.dart';

class FootballTeamArtwork extends StatelessWidget {
  const FootballTeamArtwork({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _FootballTeamPainter(teamId),
    child: const SizedBox.expand(),
  );
}

class _FootballTeamPainter extends CustomPainter {
  const _FootballTeamPainter(this.teamId);

  final String teamId;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final side = size.shortestSide;
    final bounds = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side * .88,
      height: side * .88,
    );
    switch (teamId) {
      case 'algeria':
        _paintAlgeria(canvas, bounds);
        break;
      case 'lafc':
        _paintLafc(canvas, bounds);
        break;
      case 'arsenal':
        _paintArsenal(canvas, bounds);
        break;
      default:
        _paintFallback(canvas, bounds, teamId.toUpperCase());
    }
  }

  void _paintAlgeria(Canvas canvas, Rect bounds) {
    final center = bounds.center;
    final radius = bounds.width * .46;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF147A3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .055,
    );

    final ballCenter = Offset(center.dx, center.dy - radius * .05);
    final ballRadius = radius * .34;
    canvas.drawCircle(ballCenter, ballRadius, Paint()..color = Colors.white);
    canvas.drawCircle(
      ballCenter,
      ballRadius,
      Paint()
        ..color = const Color(0xFF18221D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .04,
    );
    final pentagon = Path();
    for (var index = 0; index < 5; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final point = Offset(
        ballCenter.dx + math.cos(angle) * ballRadius * .43,
        ballCenter.dy + math.sin(angle) * ballRadius * .43,
      );
      if (index == 0) {
        pentagon.moveTo(point.dx, point.dy);
      } else {
        pentagon.lineTo(point.dx, point.dy);
      }
    }
    pentagon.close();
    canvas.drawPath(pentagon, Paint()..color = const Color(0xFF18221D));
    _drawText(
      canvas,
      'FAF',
      Offset(center.dx, center.dy + radius * .54),
      radius * .22,
      const Color(0xFF147A3D),
      FontWeight.w900,
    );
  }

  void _paintLafc(Canvas canvas, Rect bounds) {
    final gold = const Color(0xFFC6A15B);
    final shield = _shieldPath(bounds);
    canvas.drawPath(shield, Paint()..color = const Color(0xFF101820));
    canvas.drawPath(
      shield,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = bounds.width * .045,
    );
    final starY = bounds.top + bounds.height * .19;
    for (var index = -1; index <= 1; index++) {
      _drawStar(
        canvas,
        Offset(bounds.center.dx + index * bounds.width * .21, starY),
        bounds.width * .085,
        gold,
      );
    }
    _drawText(
      canvas,
      'LA',
      Offset(bounds.center.dx, bounds.top + bounds.height * .49),
      bounds.width * .28,
      gold,
      FontWeight.w900,
    );
    _drawText(
      canvas,
      'FC',
      Offset(bounds.center.dx, bounds.top + bounds.height * .75),
      bounds.width * .23,
      gold,
      FontWeight.w900,
    );
  }

  void _paintArsenal(Canvas canvas, Rect bounds) {
    final red = const Color(0xFFCE1024);
    final gold = const Color(0xFFD6B05D);
    final shield = _shieldPath(bounds);
    canvas.drawPath(shield, Paint()..color = red);
    canvas.drawPath(
      shield,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = bounds.width * .045,
    );
    _drawText(
      canvas,
      'ARSENAL',
      Offset(bounds.center.dx, bounds.top + bounds.height * .2),
      bounds.width * .13,
      Colors.white,
      FontWeight.w900,
    );

    final center = Offset(bounds.center.dx, bounds.top + bounds.height * .56);
    final linePaint = Paint()
      ..color = gold
      ..strokeWidth = bounds.width * .055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bounds.left + bounds.width * .28, center.dy),
      Offset(bounds.right - bounds.width * .2, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(bounds.left + bounds.width * .37, center.dy - bounds.height * .09),
      Offset(bounds.left + bounds.width * .37, center.dy + bounds.height * .09),
      linePaint,
    );
    canvas.drawCircle(
      Offset(bounds.left + bounds.width * .4, center.dy + bounds.height * .16),
      bounds.width * .105,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = bounds.width * .045,
    );
    canvas.drawCircle(
      Offset(bounds.left + bounds.width * .69, center.dy + bounds.height * .16),
      bounds.width * .105,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = bounds.width * .045,
    );
  }

  void _paintFallback(Canvas canvas, Rect bounds, String label) {
    final shield = _shieldPath(bounds);
    canvas.drawPath(shield, Paint()..color = const Color(0xFF252D33));
    canvas.drawPath(
      shield,
      Paint()
        ..color = const Color(0xFFC6A15B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bounds.width * .04,
    );
    _drawText(
      canvas,
      label,
      bounds.center,
      bounds.width * .15,
      Colors.white,
      FontWeight.w800,
    );
  }

  Path _shieldPath(Rect bounds) => Path()
    ..moveTo(bounds.left + bounds.width * .08, bounds.top)
    ..lineTo(bounds.right - bounds.width * .08, bounds.top)
    ..lineTo(
      bounds.right - bounds.width * .14,
      bounds.top + bounds.height * .67,
    )
    ..quadraticBezierTo(
      bounds.center.dx,
      bounds.bottom + bounds.height * .12,
      bounds.left + bounds.width * .14,
      bounds.top + bounds.height * .67,
    )
    ..close();

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var index = 0; index < 10; index++) {
      final angle = -math.pi / 2 + index * math.pi / 5;
      final pointRadius = index.isEven ? radius : radius * .45;
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight fontWeight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: fontSize * .01,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FootballTeamPainter oldDelegate) =>
      teamId != oldDelegate.teamId;
}
