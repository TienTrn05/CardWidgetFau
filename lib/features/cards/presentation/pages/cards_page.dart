import 'package:carwidget/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  int selected = 0;
  final titles = const ['Drive Beyond', 'City Lights', 'Weekend Escape'];
  final captions = const [
    'THE JOURNEY IS YOURS',
    'AFTER DARK',
    'FIND YOUR WAY',
  ];

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      const PageHeading(
        eyebrow: 'EXPRESS YOURSELF',
        title: 'Cards',
        subtitle: 'A little personality for every journey.',
      ),
      const SizedBox(height: 24),
      for (var index = 0; index < titles.length; index++) ...[
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() => selected = index),
          child: Container(
            height: 188,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected == index
                    ? AppColors.green
                    : AppColors.transparent,
                width: 2,
              ),
              gradient: AppGradients.gold,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        captions[index],
                        style: const TextStyle(
                          color: AppColors.background,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected == index
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 22,
                      color: AppColors.background,
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 36,
                  color: AppColors.background,
                ),
                const SizedBox(height: 8),
                Text(
                  titles[index],
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      const Text(
        'Tap a card to preview it.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    ],
  );
}
