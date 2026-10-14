import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/synthwave_model.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/synthwave_artwork.dart';
import 'package:flutter/material.dart';

class SynthwaveEditResult {
  const SynthwaveEditResult({
    required this.borderGradientIndex,
    required this.borderOpacity,
  });
  final int? borderGradientIndex;
  final double borderOpacity;
}

class SynthwaveEditorPage extends StatefulWidget {
  const SynthwaveEditorPage({
    super.key,
    required this.model,
    this.initialGradientIndex,
    this.initialBorderOpacity = 1,
    this.isEditingSavedWidget = false,
    this.onAdd,
  });
  final SynthwaveModel model;
  final int? initialGradientIndex;
  final double initialBorderOpacity;
  final bool isEditingSavedWidget;
  final ValueChanged<SynthwaveEditResult>? onAdd;

  @override
  State<SynthwaveEditorPage> createState() => _SynthwaveEditorPageState();
}

class _SynthwaveEditorPageState extends State<SynthwaveEditorPage> {
  late int? _gradientIndex = widget.initialGradientIndex;
  late double _opacity = widget.initialBorderOpacity;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Widget information',
                  onPressed: _showInfo,
                  icon: const Icon(
                    Icons.info_rounded,
                    color: AppColors.green,
                    size: 27,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox.square(
                  dimension: editorWidgetPreviewSize(constraints),
                  child: _SynthwavePreviewCard(
                    model: widget.model,
                    gradientIndex: _gradientIndex,
                    opacity: _opacity,
                  ),
                ),
              ),
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
                                '${(_opacity * 100).round()}%',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _opacity,
                            onChanged: (value) =>
                                setState(() => _opacity = value),
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
                    height: 60,
                    child: FilledButton(
                      onPressed: _complete,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
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
  );

  void _complete() {
    final result = SynthwaveEditResult(
      borderGradientIndex: _gradientIndex,
      borderOpacity: _opacity,
    );
    if (widget.isEditingSavedWidget) {
      Navigator.of(context).pop(result);
    } else {
      widget.onAdd?.call(result);
      Navigator.of(context).pop();
    }
  }

  void _showInfo() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Widget Preview'),
      content: Text(
        widget.isEditingSavedWidget
            ? 'Changes to this synthwave widget are saved to My Widgets.'
            : 'Choose a border style, then add this synthwave widget to My Widgets.',
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

class _SynthwavePreviewCard extends StatelessWidget {
  const _SynthwavePreviewCard({
    required this.model,
    required this.gradientIndex,
    required this.opacity,
  });
  final SynthwaveModel model;
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
        borderRadius: BorderRadius.circular(36),
        border: colors == null
            ? Border.all(color: const Color(0xFF39424A), width: 1.5)
            : null,
        gradient: colors == null ? null : LinearGradient(colors: colors),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(33),
        child: SynthwaveArtwork(synthwaveId: model.id),
      ),
    );
  }
}

class _GradientSwatch extends StatelessWidget {
  const _GradientSwatch({
    required this.selected,
    required this.onTap,
    this.colors,
  });
  final List<Color>? colors;
  final bool selected;
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
          gradient: colors == null ? null : LinearGradient(colors: colors!),
        ),
        child: colors == null
            ? const Icon(Icons.remove_rounded, color: Colors.white70)
            : null,
      ),
    ),
  );
}
