import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carwidget/features/onboarding/presentation/pages/loading_screen.dart';
import 'package:carwidget/features/premium/presentation/pages/buy_screen.dart';
import 'home_shell.dart';

enum Stage { loading, buy, home }

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  Stage stage = Stage.loading;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => stage = Stage.buy);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (stage) {
    Stage.loading => const LoadingScreen(),
    Stage.buy => BuyScreen(
      onContinue: () => setState(() => stage = Stage.home),
    ),
    Stage.home => const HomeShell(),
  };
}
