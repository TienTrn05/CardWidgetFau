import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_filled_rounded, color: lime, size: 70),
            SizedBox(height: 22),
            Text(
              'CARWIDGET',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: lime,
                backgroundColor: panel,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Đang chuẩn bị không gian của bạn',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    ),
  );
}
