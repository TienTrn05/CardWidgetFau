import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/logo_widget_content.dart';
import 'package:flutter/material.dart';

class LogoWidgetEditResult {
  const LogoWidgetEditResult({
    required this.borderGradientIndex,
    required this.borderOpacity,
  });

  final int? borderGradientIndex;
  final double borderOpacity;
}

class LogoWidgetEditorPage extends StatefulWidget {
  const LogoWidgetEditorPage({
    super.key,
    required this.model,
    this.initialGradientIndex,
    this.initialBorderOpacity = 1,
    this.isEditingSavedWidget = false,
    this.onAdd,
  });

  final LogoWidgetModel model;
  final int? initialGradientIndex;
  final double initialBorderOpacity;
  final bool isEditingSavedWidget;
  final ValueChanged<LogoWidgetEditResult>? onAdd;

  @override
  State<LogoWidgetEditorPage> createState() => _LogoWidgetEditorPageState();
}

class _LogoWidgetEditorPageState extends State<LogoWidgetEditorPage> {
  late int? _gradientIndex = widget.initialGradientIndex;
  late double _borderOpacity = widget.initialBorderOpacity;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.isEditingSavedWidget ? 'Edit Widget' : 'Preview',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Widget information',
                      onPressed: () => _showInfo(context),
                      icon: const Icon(
                        Icons.info_rounded,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = editorWidgetPreviewSize(box);
                  return Center(
                    child: SizedBox.square(
                      dimension: size,
                      child: _LogoPreviewCard(
                        model: widget.model,
                        gradientIndex: _gradientIndex,
                        opacity: _borderOpacity,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Border Gradient',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _GradientSwatch(
                                  selected: _gradientIndex == null,
                                  onTap: () =>
                                      setState(() => _gradientIndex = null),
                                ),
                                for (
                                  var index = 0;
                                  index < logoBorderGradients.length;
                                  index++
                                )
                                  _GradientSwatch(
                                    colors: logoBorderGradients[index],
                                    selected: _gradientIndex == index,
                                    opacity: _borderOpacity,
                                    onTap: () =>
                                        setState(() => _gradientIndex = index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Border Opacity',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(_borderOpacity * 100).round()}%',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _borderOpacity,
                              onChanged: (value) =>
                                  setState(() => _borderOpacity = value),
                              activeColor: AppColors.green,
                              inactiveColor: const Color(0xFF536068),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: FilledButton(
                        onPressed: _completeEditing,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          widget.isEditingSavedWidget
                              ? 'Save Changes'
                              : 'Add to My Widget',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _completeEditing() {
    final result = LogoWidgetEditResult(
      borderGradientIndex: _gradientIndex,
      borderOpacity: _borderOpacity,
    );
    if (widget.isEditingSavedWidget) {
      Navigator.of(context).pop(result);
    } else {
      widget.onAdd?.call(result);
      Navigator.of(context).pop();
    }
  }

  void _showInfo(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Widget Preview'),
      content: Text(
        widget.isEditingSavedWidget
            ? 'Changes to this logo are saved to My Widgets.'
            : 'This preview shows how your logo widget will look. Add it to My Widget to save it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

class _LogoPreviewCard extends StatelessWidget {
  const _LogoPreviewCard({
    required this.model,
    required this.gradientIndex,
    required this.opacity,
  });

  final LogoWidgetModel model;
  final int? gradientIndex;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = gradientIndex == null
        ? null
        : logoBorderGradients[gradientIndex! % logoBorderGradients.length]
              .map((color) => color.withValues(alpha: opacity))
              .toList();
    return Container(
      padding: EdgeInsets.all(colors == null ? 1.5 : 3),
      decoration: BoxDecoration(
        color: colors == null ? const Color(0xFF252D33) : null,
        borderRadius: BorderRadius.circular(42),
        border: colors == null
            ? Border.all(color: const Color(0xFF39424A), width: 1.5)
            : null,
        gradient: colors == null ? null : LinearGradient(colors: colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(39),
        child: ColoredBox(
          color: const Color(0xFF252D33),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: LogoArtwork(model: model),
          ),
        ),
      ),
    );
  }
}

class _GradientSwatch extends StatelessWidget {
  const _GradientSwatch({
    required this.selected,
    required this.onTap,
    this.colors,
    this.opacity = 1,
  });

  final List<Color>? colors;
  final bool selected;
  final double opacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48,
      height: 48,
      padding: EdgeInsets.all(selected ? 3 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: AppColors.green, width: 2)
            : colors == null
            ? Border.all(color: const Color(0xFFB0B7BD), width: 1.5)
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors == null ? AppColors.surface : null,
          gradient: colors == null
              ? null
              : LinearGradient(
                  colors: colors!
                      .map((color) => color.withValues(alpha: opacity))
                      .toList(),
                ),
        ),
        child: colors == null
            ? const Icon(Icons.remove_rounded, color: Colors.white70)
            : null,
      ),
    ),
  );
}
