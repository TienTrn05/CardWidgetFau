import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/ui/car_ui.dart';
import 'package:carwidget/features/settings/data/app_icon_preference.dart';
import 'package:flutter/material.dart';

class ChangeIconPage extends StatelessWidget {
  const ChangeIconPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: const Text('Change icon'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          ValueListenableBuilder<int>(
            valueListenable: AppIconPreference.selected,
            builder: (context, selected, _) => LayoutBuilder(
              builder: (context, constraints) {
                final size = (constraints.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (
                      var index = 0;
                      index < appIconPreviewAssets.length;
                      index++
                    )
                      SizedBox(
                        width: size,
                        height: size,
                        child: _IconChoice(
                          index: index,
                          selected: selected == index,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose a Home Screen icon. The first option restores the original icon.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    ),
  );
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.index, required this.selected});

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: index == 0 ? 'Original icon' : 'Icon $index',
    selected: selected,
    button: true,
    child: InkWell(
      key: ValueKey('app-icon-$index'),
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        try {
          await AppIconPreference.choose(index);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not change the app icon.')),
            );
          }
        }
      },
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.white : AppColors.subtleBorder,
            width: selected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(selected ? 3 : 1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  appIconPreviewAssets[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              if (selected)
                const Positioned(
                  right: 8,
                  bottom: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.white,
                    child: Icon(
                      Icons.check,
                      color: AppColors.background,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
