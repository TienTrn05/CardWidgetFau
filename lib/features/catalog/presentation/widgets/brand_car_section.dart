import 'dart:math' as math;
import 'dart:typed_data';

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_image_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_font_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/image_crop_dialog.dart';
import 'package:carwidget/features/catalog/presentation/widgets/my_widgets_section.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BrandCarSection extends StatelessWidget {
  const BrandCarSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Brand Car',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SeeAllButton(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BrandCarWidgetsPage(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final cardSize = carPlayWidgetPreviewSize(
            context,
            constraints.maxWidth,
          );
          return SizedBox(
            height: cardSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: brandCarWidgetModels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox.square(
                dimension: cardSize,
                child: _BrandCarWidgetTile(widget: brandCarWidgetModels[index]),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class BrandCarWidgetsPage extends StatelessWidget {
  const BrandCarWidgetsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'Brand Car',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: brandCarWidgetModels.length,
            itemBuilder: (context, index) =>
                _BrandCarWidgetTile(widget: brandCarWidgetModels[index]),
          );
        },
      ),
    ),
  );
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        child: Text(
          'See All',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _BrandCarWidgetTile extends StatelessWidget {
  const _BrandCarWidgetTile({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF20272D),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => _showBrandCarWidgetPreview(context, widget),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF303940)),
        ),
        child: SavedWidgetArtwork(widget: widget),
      ),
    ),
  );
}

void _showBrandCarWidgetPreview(BuildContext context, SavedWidgetModel widget) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: _BrandCarWidgetPreviewDialog(widget: widget),
    ),
  );
}

class _BrandCarWidgetPreviewDialog extends StatefulWidget {
  const _BrandCarWidgetPreviewDialog({required this.widget});

  final SavedWidgetModel widget;

  @override
  State<_BrandCarWidgetPreviewDialog> createState() =>
      _BrandCarWidgetPreviewDialogState();
}

class _BrandCarWidgetPreviewDialogState
    extends State<_BrandCarWidgetPreviewDialog> {
  var _selectedTab = 0;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Preview',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Reset widget layout',
                      onPressed: () => resetBrandCarWidgetLayout(
                        brandCarDraftLayoutId(widget.widget.id),
                      ),
                      icon: const Icon(Icons.restart_alt_rounded, size: 21),
                    ),
                    IconButton(
                      tooltip: 'About this widget',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          content: const Text(
                            'Add this car design to My Widgets to use it in your CarPlay preview.',
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      ),
                      icon: const Icon(
                        Icons.info_rounded,
                        color: AppColors.green,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final previewSize = math
                    .min(constraints.maxWidth - 24, constraints.maxHeight - 24)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox.square(
                          dimension: previewSize,
                          child: Material(
                            color: const Color(0xFF20272D),
                            borderRadius: BorderRadius.circular(28),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: SavedWidgetArtwork(
                                widget: widget.widget,
                                isEditable: true,
                                layoutId: brandCarDraftLayoutId(
                                  widget.widget.id,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: _BrandCarCustomizationPanel(
              widget: widget.widget,
              selectedTab: _selectedTab,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BrandCarCustomizationPanel extends StatelessWidget {
  const _BrandCarCustomizationPanel({
    required this.widget,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final SavedWidgetModel widget;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final layoutId = brandCarDraftLayoutId(widget.id);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ValueListenableBuilder<Map<String, BrandCarLayout>>(
        valueListenable: brandCarLayouts,
        builder: (context, layouts, _) {
          final layout = layouts[layoutId] ?? const BrandCarLayout();
          final scale = selectedTab == 0 ? layout.brandScale : layout.carScale;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandCarEditorTabs(
                selectedTab: selectedTab,
                onTabSelected: onTabSelected,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedTab == 0) ...[
                        const Text(
                          'Select Car Logo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.green,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ] else if (selectedTab == 1) ...[
                        const Text(
                          'Select Car Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CarImageChooser(
                          selectedIndex: layout.carImageIndex,
                          isCustomImageSelected: layout.carImageBytes != null,
                          customImageBytes: layout.carImageBytes,
                          onSelected: (index) =>
                              setBrandCarImage(layoutId, index),
                          onAddImage: () async {
                            final selected = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 95,
                            );
                            if (selected == null || !context.mounted) return;
                            final imageBytes = await selected.readAsBytes();
                            if (!context.mounted) return;
                            final croppedImage = await showImageCropDialog(
                              context,
                              imageBytes,
                            );
                            if (croppedImage != null && context.mounted) {
                              setBrandCarCustomImage(layoutId, croppedImage);
                            }
                          },
                        ),
                      ] else if (selectedTab == 2) ...[
                        _BrandCarTextControls(
                          layout: layout,
                          onNicknameChanged: (value) =>
                              setBrandCarGreetingNickname(layoutId, value),
                          onFontChanged: (value) =>
                              setBrandCarGreetingFont(layoutId, value),
                          onColorChanged: (value) =>
                              setBrandCarGreetingColor(layoutId, value),
                        ),
                      ] else if (selectedTab == 3) ...[
                        _BrandCarBorderControls(
                          layout: layout,
                          onColorChanged: (value) =>
                              setBrandCarBorderColor(layoutId, value),
                          onOpacityChanged: (value) =>
                              setBrandCarBorderOpacity(layoutId, value),
                        ),
                      ],
                      if (selectedTab < 2) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              'Size',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(scale * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.green,
                            inactiveTrackColor: const Color(0xFF3A424A),
                            thumbColor: Colors.white,
                            overlayColor: AppColors.green.withValues(
                              alpha: .14,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            min: .6,
                            max: 3,
                            divisions: 24,
                            value: scale.clamp(.6, 3),
                            onChanged: (value) => selectedTab == 0
                                ? setBrandCarBrandScale(layoutId, value)
                                : setBrandCarImageScale(layoutId, value),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    addBrandCarWidgetToMyWidgets(context, widget);
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Add to My Widget',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandCarBorderControls extends StatelessWidget {
  const _BrandCarBorderControls({
    required this.layout,
    required this.onColorChanged,
    required this.onOpacityChanged,
  });

  final BrandCarLayout layout;
  final ValueChanged<int?> onColorChanged;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Border Color',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _BorderColorSwatch(
            colorValue: null,
            selected: layout.borderColorValue == null,
            onTap: () => onColorChanged(null),
          ),
          for (final colorValue in _borderColors)
            _BorderColorSwatch(
              colorValue: colorValue,
              selected: layout.borderColorValue == colorValue,
              onTap: () => onColorChanged(colorValue),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Text(
            'Opacity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            '${(layout.borderOpacity * 100).round()}%',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
      SliderTheme(
        data: _brandCarSliderTheme(context),
        child: Slider(
          min: 0,
          max: 1,
          divisions: 10,
          value: layout.borderOpacity.clamp(0.0, 1.0),
          onChanged: onOpacityChanged,
        ),
      ),
    ],
  );
}

SliderThemeData _brandCarSliderTheme(BuildContext context) =>
    SliderTheme.of(context).copyWith(
      activeTrackColor: AppColors.green,
      inactiveTrackColor: const Color(0xFF3A424A),
      thumbColor: Colors.white,
      overlayColor: AppColors.green.withValues(alpha: .14),
      trackHeight: 4,
    );

const _borderColors = <int>[
  0xFF527BED,
  0xFFF44336,
  0xFFFF9800,
  0xFF29B6F6,
  0xFF00D99A,
  0xFFFFC107,
  0xFFEC4899,
  0xFFAB47BC,
];

class _BorderColorSwatch extends StatelessWidget {
  const _BorderColorSwatch({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int? colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected ? Border.all(color: AppColors.green, width: 2) : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorValue == null
              ? const Color(0xFF39414A)
              : Color(colorValue!),
          shape: BoxShape.circle,
        ),
        child: colorValue == null
            ? const Icon(Icons.remove_rounded, color: Colors.white70, size: 21)
            : null,
      ),
    ),
  );
}

class _BrandCarTextControls extends StatelessWidget {
  const _BrandCarTextControls({
    required this.layout,
    required this.onNicknameChanged,
    required this.onFontChanged,
    required this.onColorChanged,
  });

  final BrandCarLayout layout;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<int> onFontChanged;
  final ValueChanged<int> onColorChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'My Nickname',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      _NicknameTextField(
        value: layout.greetingNickname,
        onChanged: onNicknameChanged,
      ),
      const SizedBox(height: 12),
      const Text(
        'Select Font',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final selectedFont = await _showFontSelectionDialog(
              context,
              layout.greetingFontIndex,
            );
            if (selectedFont != null) onFontChanged(selectedFont);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    brandCarFontOptions[layout.greetingFontIndex
                            .clamp(0, brandCarFontOptions.length - 1)
                            .toInt()]
                        .name,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Text Color',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final colorValue in _greetingColors)
            _GreetingColorSwatch(
              color: Color(colorValue),
              selected: layout.greetingColorValue == colorValue,
              onTap: () => onColorChanged(colorValue),
            ),
          _RainbowColorSwatch(onSelected: onColorChanged),
        ],
      ),
    ],
  );
}

Future<int?> _showFontSelectionDialog(
  BuildContext context,
  int selectedFontIndex,
) => showDialog<int>(
  context: context,
  builder: (dialogContext) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    child: SizedBox(
      height: MediaQuery.sizeOf(dialogContext).height * .38,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  const Text(
                    'Select Font',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF39414C),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: brandCarFontOptions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final option = brandCarFontOptions[index];
                    final selected = index == selectedFontIndex;
                    return Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => Navigator.of(dialogContext).pop(index),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.green
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.name,
                                  style: TextStyle(
                                    fontFamily: option.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.green,
                                  size: 21,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

class _NicknameTextField extends StatefulWidget {
  const _NicknameTextField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_NicknameTextField> createState() => _NicknameTextFieldState();
}

class _NicknameTextFieldState extends State<_NicknameTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _NicknameTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLength: 18,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 16),
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        border: InputBorder.none,
        counterText: '',
        contentPadding: EdgeInsets.symmetric(vertical: 13),
        suffixIcon: Icon(Icons.edit_outlined, color: AppColors.muted),
      ),
    ),
  );
}

const _greetingColors = <int>[
  0xFFFFFFFF,
  0xFFFFB900,
  0xFFE53935,
  0xFF2588F5,
  0xFF00D99A,
];

class _GreetingColorSwatch extends StatelessWidget {
  const _GreetingColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected ? Border.all(color: AppColors.green, width: 2) : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}

class _RainbowColorSwatch extends StatelessWidget {
  const _RainbowColorSwatch({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final colorValue = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Choose text color'),
          content: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final colorValue in _extendedGreetingColors)
                _GreetingColorSwatch(
                  color: Color(colorValue),
                  selected: false,
                  onTap: () => Navigator.of(dialogContext).pop(colorValue),
                ),
            ],
          ),
        ),
      );
      if (colorValue != null) onSelected(colorValue);
    },
    child: Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF39414A)),
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFFF3B30),
              Color(0xFFFFCC00),
              Color(0xFF34C759),
              Color(0xFF00C7BE),
              Color(0xFF007AFF),
              Color(0xFFAF52DE),
              Color(0xFFFF3B30),
            ],
          ),
        ),
      ),
    ),
  );
}

const _extendedGreetingColors = <int>[
  0xFF000000,
  0xFFFFFFFF,
  0xFFFF3B30,
  0xFFFF9500,
  0xFFFFCC00,
  0xFF34C759,
  0xFF00C7BE,
  0xFF007AFF,
  0xFF5856D6,
  0xFFAF52DE,
];

class _CarImageChooser extends StatelessWidget {
  const _CarImageChooser({
    required this.selectedIndex,
    required this.isCustomImageSelected,
    required this.customImageBytes,
    required this.onSelected,
    required this.onAddImage,
  });

  final int selectedIndex;
  final bool isCustomImageSelected;
  final Uint8List? customImageBytes;
  final ValueChanged<int> onSelected;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 92,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: brandCarImageOptions.length + 1,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        if (index == brandCarImageOptions.length) {
          return Material(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: onAddImage,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: isCustomImageSelected
                        ? AppColors.green
                        : const Color(0xFF39414A),
                    width: isCustomImageSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: customImageBytes == null
                    ? const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.muted,
                        size: 30,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          customImageBytes!,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          );
        }
        final option = brandCarImageOptions[index];
        final selected = !isCustomImageSelected && index == selectedIndex;
        return Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected ? AppColors.green : const Color(0xFF39414A),
                  width: selected ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(option.icon, color: option.color, size: 44),
            ),
          ),
        );
      },
    ),
  );
}

class _BrandCarEditorTabs extends StatelessWidget {
  const _BrandCarEditorTabs({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Car Logo', 'Car Image', 'Text', 'Border'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF39414C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: index < 4 ? () => onTabSelected(index) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == selectedTab
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: index == selectedTab
                            ? AppColors.background
                            : AppColors.muted,
                        fontSize: 13,
                        fontWeight: index == selectedTab
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
