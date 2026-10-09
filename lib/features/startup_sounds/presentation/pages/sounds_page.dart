import 'package:carwidget/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';

class SoundsPage extends StatefulWidget {
  const SoundsPage({super.key});

  @override
  State<SoundsPage> createState() => _SoundsPageState();
}

class _SoundsPageState extends State<SoundsPage> {
  int selected = 0;
  final names = const ['Ignition', 'Neon Pulse', 'Midnight', 'Open Road'];
  final descriptions = const [
    'Classic start',
    'Electronic',
    'Soft ambient',
    'Bright & energetic',
  ];
  final icons = const [
    Icons.power_settings_new_rounded,
    Icons.graphic_eq_rounded,
    Icons.nights_stay_rounded,
    Icons.air_rounded,
  ];

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      const PageHeading(
        eyebrow: 'SET THE MOOD',
        title: 'Sounds',
        subtitle: 'Choose a sound to match your drive.',
      ),
      const SizedBox(height: 22),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: tileDecoration(),
        child: Column(
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.green,
              size: 72,
            ),
            const SizedBox(height: 10),
            Text(
              names[selected],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Selected · Audio preview unavailable',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Sound library', action: '4 sounds'),
      const SizedBox(height: 12),
      for (var index = 0; index < names.length; index++) ...[
        ListTile(
          onTap: () => setState(() => selected = index),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected == index
                  ? AppColors.green
                  : AppColors.transparent,
            ),
          ),
          tileColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.greenTile,
            child: Icon(icons[index], color: AppColors.green),
          ),
          title: Text(
            names[index],
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(descriptions[index]),
          trailing: Icon(
            selected == index
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            color: selected == index ? AppColors.green : AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}
