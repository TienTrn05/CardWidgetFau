import 'package:carwidget/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppGradients.loadingBackground),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: AppGradients.loadingMark,
                  boxShadow: [
                    BoxShadow(color: AppColors.greenGlow, blurRadius: 28),
                  ],
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 12,
                      child: Icon(Icons.location_on_outlined, size: 34),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Car Widgets',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 92,
                height: 2,
                child: LinearProgressIndicator(
                  color: AppColors.green,
                  backgroundColor: AppColors.progressTrack,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
