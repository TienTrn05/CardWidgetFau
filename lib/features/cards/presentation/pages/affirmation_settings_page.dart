import 'dart:math' as math;

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/cards/data/models/affirmation_model.dart';
import 'package:carwidget/features/cards/presentation/widgets/affirmation_card_artwork.dart';
import 'package:carwidget/features/settings/presentation/widgets/tutorial_sheet.dart';
import 'package:flutter/material.dart';

class AffirmationSettingsPage extends StatefulWidget {
  const AffirmationSettingsPage({
    super.key,
    required this.affirmation,
    this.isEditing = false,
  });

  final AffirmationModel affirmation;
  final bool isEditing;

  @override
  State<AffirmationSettingsPage> createState() =>
      _AffirmationSettingsPageState();
}

class _AffirmationSettingsPageState extends State<AffirmationSettingsPage> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.affirmation.text,
  );
  late int _textColorValue = widget.affirmation.textColorValue;
  late int _backgroundColorValue = widget.affirmation.backgroundColorValue;

  static const _colors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFFFB900),
    Color(0xFFE92D2D),
    Color(0xFF2186FF),
    Color(0xFF00E99A),
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_refreshPreview)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Preview',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
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
          ),
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardSize = math.min(
                  280.0,
                  math.min(
                    constraints.maxWidth * .72,
                    math.max(0.0, constraints.maxHeight - 72),
                  ),
                );
                final affirmation = _currentAffirmation();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: cardSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF59616A),
                            width: 1.5,
                          ),
                        ),
                        child: AffirmationCardArtwork(
                          affirmation: affirmation,
                          textSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _showPreview,
                      icon: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.green,
                      ),
                      label: const Text('Preview'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SettingsLabel('Content'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _textController,
                            minLines: 2,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.3,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF3B414C),
                              suffixIcon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF9CA3AD),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 17),
                          const _SettingsLabel('Text Color'),
                          const SizedBox(height: 9),
                          _ColorOptions(
                            selectedValue: _textColorValue,
                            colors: _colors,
                            onSelected: (color) => setState(
                              () => _textColorValue = color.toARGB32(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _SettingsLabel('Background Color'),
                          const SizedBox(height: 9),
                          _ColorOptions(
                            selectedValue: _backgroundColorValue,
                            colors: _colors,
                            onSelected: (color) => setState(
                              () => _backgroundColorValue = color.toARGB32(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        widget.isEditing ? 'Save Changes' : 'Add to My Widget',
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

  AffirmationModel _currentAffirmation() => widget.affirmation.copyWith(
    text: _textController.text,
    textColorValue: _textColorValue,
    backgroundColorValue: _backgroundColorValue,
  );

  void _refreshPreview() => setState(() {});

  void _save() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter affirmation text.')),
        );
      return;
    }
    Navigator.of(
      context,
    ).pop(_currentAffirmation().copyWith(text: text, date: DateTime.now()));
  }

  void _showPreview() => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox.square(
        dimension: 280,
        child: AffirmationCardArtwork(
          affirmation: _currentAffirmation(),
          textSize: 18,
        ),
      ),
    ),
  );

  void _showInfo() => showTutorialSheet(context);
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 19,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _ColorOptions extends StatelessWidget {
  const _ColorOptions({
    required this.selectedValue,
    required this.colors,
    required this.onSelected,
  });

  final int selectedValue;
  final List<Color> colors;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 10,
    children: [
      for (final color in colors)
        _ColorSwatch(
          color: color,
          selected: color.toARGB32() == selectedValue,
          onTap: () => onSelected(color),
        ),
      _ColorSwatch(
        selected: false,
        rainbow: true,
        onTap: () async {
          final color = await showDialog<Color>(
            context: context,
            builder: (_) => const _ExtendedColorPicker(),
          );
          if (color != null) onSelected(color);
        },
      ),
    ],
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.selected,
    required this.onTap,
    this.color = Colors.transparent,
    this.rainbow = false,
  });

  final Color color;
  final bool selected;
  final bool rainbow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rainbow ? null : color,
            gradient: rainbow
                ? const SweepGradient(
                    colors: [
                      Color(0xFFFF2929),
                      Color(0xFFFFD829),
                      Color(0xFF36E84F),
                      Color(0xFF25DDF5),
                      Color(0xFF5542F5),
                      Color(0xFFFF35D0),
                      Color(0xFFFF2929),
                    ],
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

class _ExtendedColorPicker extends StatelessWidget {
  const _ExtendedColorPicker();

  static const _palette = <Color>[
    Color(0xFF111827),
    Color(0xFF4B5563),
    Color(0xFFFFFFFF),
    Color(0xFF8B4513),
    Color(0xFFFFB900),
    Color(0xFFFF6B35),
    Color(0xFFE92D2D),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF2186FF),
    Color(0xFF00C8D7),
    Color(0xFF00A86B),
    Color(0xFF00E99A),
  ];

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: const Text('Choose a Color'),
    content: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in _palette)
          _ColorSwatch(
            color: color,
            selected: false,
            onTap: () => Navigator.of(context).pop(color),
          ),
      ],
    ),
  );
}
