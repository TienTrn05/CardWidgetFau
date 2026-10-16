import 'package:flutter/material.dart';

Future<T?> showSlideRightDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  String? barrierLabel,
  Color barrierColor = Colors.black54,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
  barrierColor: barrierColor,
  transitionDuration: const Duration(milliseconds: 320),
  pageBuilder: (context, animation, secondaryAnimation) =>
      SafeArea(child: builder(context)),
  transitionBuilder: (context, animation, secondaryAnimation, child) {
    final slide = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(slide),
      child: child,
    );
  },
);

PageRoute<T> slideRightPageRoute<T>({required WidgetBuilder builder}) =>
    PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(slide),
          child: child,
        );
      },
    );
