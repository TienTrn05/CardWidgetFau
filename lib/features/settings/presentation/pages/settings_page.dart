import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = false;
  bool haptics = true;

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      const PageHeading(
        eyebrow: 'MAKE IT YOURS',
        title: 'Settings',
        subtitle: 'Tùy chỉnh trải nghiệm CarWidget.',
      ),
      const SizedBox(height: 24),
      const SectionTitle('Tùy chọn ứng dụng'),
      const SizedBox(height: 12),
      Container(
        decoration: tileDecoration(),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text('Thông báo'),
              subtitle: const Text('Tùy chọn giao diện xem trước'),
              secondary: const Icon(Icons.notifications_none_rounded),
              value: notifications,
              onChanged: (value) => setState(() => notifications = value),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile.adaptive(
              title: const Text('Phản hồi chạm'),
              subtitle: const Text('Tùy chọn giao diện xem trước'),
              secondary: const Icon(Icons.vibration_rounded),
              value: haptics,
              onChanged: (value) => setState(() => haptics = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Thông tin'),
      const SizedBox(height: 12),
      Container(
        decoration: tileDecoration(),
        child: const Column(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Về CarWidget'),
              subtitle: Text('Bản xem trước giao diện'),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.workspace_premium_outlined),
              title: Text('Premium'),
              subtitle: Text('Chưa tích hợp thanh toán'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Center(
        child: Text(
          'CarWidget · UI preview',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ),
    ],
  );
}
