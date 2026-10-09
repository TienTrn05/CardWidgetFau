import 'dart:typed_data';

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/editor/presentation/widgets/brand_car_border_style.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_image_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/brand_car_font_options.dart';
import 'package:carwidget/features/catalog/presentation/widgets/image_crop_dialog.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showBrandCarWidgetEditor(BuildContext context, SavedWidgetModel widget) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: BrandCarEditorPage(
        model: widget,
        layoutId: brandCarDraftLayoutId(widget.id),
      ),
    ),
  );
}

Future<void> openSavedBrandCarWidgetEditor(
  BuildContext context,
  SavedWidgetModel widget,
) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(
    builder: (_) => BrandCarEditorPage(
      model: widget,
      layoutId: widget.layoutId ?? widget.id,
      isSavedWidget: true,
    ),
  ),
);

class BrandCarEditorPage extends StatefulWidget {
  const BrandCarEditorPage({
    super.key,
    required this.model,
    required this.layoutId,
    this.isSavedWidget = false,
  });

  final SavedWidgetModel model;
  final String layoutId;
  final bool isSavedWidget;

  @override
  State<BrandCarEditorPage> createState() => _BrandCarEditorPageState();
}

class _BrandCarEditorPageState extends State<BrandCarEditorPage> {
  var _selectedTab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  widget.isSavedWidget ? 'Edit Widget' : 'Preview',
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
                      onPressed: () =>
                          resetBrandCarWidgetLayout(widget.layoutId),
                      icon: const Icon(Icons.restart_alt_rounded, size: 21),
                    ),
                    IconButton(
                      tooltip: 'About this widget',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          content: Text(
                            widget.isSavedWidget
                                ? 'Changes update this widget in My Widgets and your CarPlay preview.'
                                : 'Add this car design to My Widgets to use it in your CarPlay preview.',
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
                final previewSize = editorWidgetPreviewSize(constraints);
                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox.square(
                          dimension: previewSize,
                          child: BrandCarPreviewFrame(
                            layoutId: widget.layoutId,
                            contentPadding: EdgeInsets.zero,
                            child: SavedWidgetArtwork(
                              widget: widget.model,
                              isEditable: true,
                              layoutId: widget.layoutId,
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
              model: widget.model,
              layoutId: widget.layoutId,
              isSavedWidget: widget.isSavedWidget,
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
    required this.model,
    required this.layoutId,
    required this.isSavedWidget,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final SavedWidgetModel model;
  final String layoutId;
  final bool isSavedWidget;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.025, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(selectedTab),
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
                              model.label,
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
                            onGradientChanged: (value) =>
                                setBrandCarBorderGradient(layoutId, value),
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
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    if (!isSavedWidget) {
                      addBrandCarWidgetToMyWidgets(model);
                    }
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isSavedWidget ? 'Save Changes' : 'Add to My Widget',
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
    required this.onGradientChanged,
    required this.onOpacityChanged,
  });

  final BrandCarLayout layout;
  final ValueChanged<int?> onGradientChanged;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Border Gradient',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _BorderGradientSwatch(
            colors: null,
            selected: layout.borderGradientIndex == null,
            onTap: () => onGradientChanged(null),
          ),
          for (var index = 0; index < logoBorderGradients.length; index++)
            _BorderGradientSwatch(
              colors: logoBorderGradients[index],
              opacity: layout.borderOpacity,
              selected: layout.borderGradientIndex == index,
              onTap: () => onGradientChanged(index),
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

class _BorderGradientSwatch extends StatelessWidget {
  const _BorderGradientSwatch({
    required this.colors,
    required this.selected,
    required this.onTap,
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
          color: colors == null ? AppColors.surface : null,
          shape: BoxShape.circle,
          gradient: colors == null
              ? null
              : LinearGradient(
                  colors: colors!
                      .map((color) => color.withValues(alpha: opacity))
                      .toList(),
                ),
        ),
        child: colors == null
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            alignment: Alignment(-1 + 2 * selectedTab / (labels.length - 1), 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var index = 0; index < labels.length; index++)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            color: index == selectedTab
                                ? AppColors.background
                                : AppColors.muted,
                            fontSize: 13,
                            fontWeight: index == selectedTab
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          child: Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
