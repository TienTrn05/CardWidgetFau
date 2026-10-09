import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B1018);
  static const surface = Color(0xFF232C33);
  static const selectedSurface = Color(0xFF073527);
  static const green = Color(0xFF00E987);
  static const muted = Color(0xFF87939C);
  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
  static const badge = Color(0xFFFF864B);
  static const goldLight = Color(0xFFFFE59B);
  static const gold = Color(0xFFF4B447);
  static const goldDark = Color(0xFFA96A18);

  static const subtleBorder = Color(0x0FFFFFFF);
  static const progressTrack = Color(0x24FFFFFF);
  static const inactiveDot = Color(0x8AFFFFFF);
  static const greenGlow = Color(0x2E00E987);
  static const greenHalo = Color(0x1A00E987);
  static const greenTile = Color(0x1F00E987);
}

abstract final class AppGradients {
  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
  );

  static const preview = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.selectedSurface, AppColors.surface],
  );

  static const loadingBackground = RadialGradient(
    center: Alignment(0, -0.8),
    radius: 1.15,
    colors: [AppColors.selectedSurface, AppColors.background],
    stops: [0, 0.72],
  );

  static const loadingMark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.green, AppColors.selectedSurface],
  );

  static const heroFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.transparent,
      Color(0x110B1018),
      Color(0x440B1018),
      Color(0xBB0B1018),
      AppColors.background,
    ],
    stops: [0.0, 0.35, 0.55, 0.75, 1.0],
  );
}

abstract final class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.green,
      onPrimary: AppColors.background,
      secondary: AppColors.gold,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.white,
      error: AppColors.badge,
      onError: AppColors.background,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.white
            : AppColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.green
            : AppColors.surface,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.green,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
    ),
  );
}
