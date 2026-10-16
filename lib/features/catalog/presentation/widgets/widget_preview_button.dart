import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_mockup.dart';
import 'package:flutter/material.dart';

class WidgetPreviewButton extends StatelessWidget {
  const WidgetPreviewButton({super.key, required this.previewBuilder});

  final WidgetBuilder previewBuilder;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC000000),
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 0),
          child: SizedBox(
            width: constraints.maxWidth * .84,
            height: (constraints.maxHeight * .70 + 40).clamp(
              0.0,
              constraints.maxHeight,
            ),
            child: CarPlayPreviewMockup(
              previewBuilder: previewBuilder,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    ),
    icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.green),
    label: const Text('Preview'),
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    ),
  );
}
