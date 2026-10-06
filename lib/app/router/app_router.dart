import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carwidget/features/onboarding/presentation/pages/loading_screen.dart';
import 'package:carwidget/features/premium/presentation/pages/buy_screen.dart';
import 'home_shell.dart';

enum AppRoute { loading, buy, home }

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  AppRoute route = AppRoute.loading;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => route = AppRoute.buy);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (route) {
    AppRoute.loading => const LoadingScreen(),
    AppRoute.buy => BuyScreen(
      onContinue: () => setState(() => route = AppRoute.home),
    ),
    AppRoute.home => const HomeShell(),
  };
}
