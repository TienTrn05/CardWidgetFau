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
  final colors = const [
    Color(0xFFADCF51),
    Color(0xFF819ED6),
    Color(0xFFFFA879),
  ];

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      const PageHeading(
        eyebrow: 'EXPRESS YOURSELF',
        title: 'Cards',
        subtitle: 'Một chút cá tính cho mỗi hành trình.',
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
                color: selected == index ? lime : Colors.transparent,
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors[index].withValues(alpha: .84),
                  colors[index].withValues(alpha: .25),
                  panel,
                ],
              ),
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
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.directions_car_filled_rounded, size: 36),
                const SizedBox(height: 8),
                Text(
                  titles[index],
                  style: const TextStyle(
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
        'Chạm vào card để chọn mẫu xem trước.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}
