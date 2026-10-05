import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';

class WidgetsPage extends StatefulWidget {
  const WidgetsPage({super.key});

  @override
  State<WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<WidgetsPage> {
  int selected = 0;
  final names = const [
    'Night Drive',
    'Minimal Clock',
    'Road Trip',
    'Electric Mood',
  ];
  final icons = const [
    Icons.speed_rounded,
    Icons.access_time_rounded,
    Icons.route_rounded,
    Icons.bolt_rounded,
  ];

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      const PageHeading(
        eyebrow: 'YOUR DASHBOARD',
        title: 'Widgets',
        subtitle: 'Chọn giao diện đồng hành trên mỗi chuyến đi.',
      ),
      const SizedBox(height: 22),
      SectionTitle(
        'Đang xem trước',
        action: '${selected + 1} / ${names.length}',
      ),
      const SizedBox(height: 12),
      Container(
        height: 190,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF373F2D), panel]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CARWIDGET',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(icons[selected], color: lime, size: 58),
                const Spacer(),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '24°',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      'READY TO GO',
                      style: TextStyle(
                        color: lime,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              names[selected],
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Khám phá mẫu', action: 'Chạm để xem'),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: names.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.16,
        ),
        itemBuilder: (context, index) => InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => selected = index),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: tileDecoration(selected: selected == index),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icons[index],
                  size: 36,
                  color: index.isEven ? lime : Colors.white,
                ),
                Text(
                  names[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
