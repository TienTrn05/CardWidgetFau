import 'package:carwidget/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PageScroll extends StatelessWidget {
  const PageScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
    children: children,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 11,
          letterSpacing: 2.3,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, height: 1.45),
      ),
    ],
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.directions_car_filled_rounded,
        size: 25,
        color: AppColors.green,
      ),
      SizedBox(width: 9),
      Text(
        'CARWIDGET',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.7,
          fontSize: 16,
        ),
      ),
    ],
  );
}

class Feature extends StatelessWidget {
  const Feature({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, color: AppColors.green, size: 21),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

class HeroPreview extends StatelessWidget {
  const HeroPreview({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * .83,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size * .8,
          height: size * .8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.greenHalo,
          ),
        ),
        Transform.rotate(
          angle: -.13,
          child: Container(
            width: size * .74,
            height: size * .56,
            decoration: tileDecoration(),
            child: const Center(
              child: Icon(
                Icons.speed_rounded,
                color: AppColors.green,
                size: 88,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 6,
          child: Container(
            width: size * .41,
            height: size * .34,
            padding: const EdgeInsets.all(12),
            decoration: tileDecoration(selected: true),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppColors.green,
                  size: 38,
                ),
                SizedBox(height: 5),
                Text(
                  'DRIVE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(width: 8),
      if (action != null)
        Text(
          action!,
          style: const TextStyle(color: AppColors.green, fontSize: 12),
        ),
    ],
  );
}

BoxDecoration tileDecoration({bool selected = false}) => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(22),
  border: Border.all(
    color: selected ? AppColors.green : AppColors.subtleBorder,
  ),
);
