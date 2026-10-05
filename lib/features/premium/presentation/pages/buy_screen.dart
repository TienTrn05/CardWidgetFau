import 'package:flutter/material.dart';
import 'package:carwidget/core/ui/car_ui.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  int plan = 0;

  void showPurchaseNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium'),
        content: const Text(
          'Thanh toán chưa được kết nối. Bạn có thể khám phá giao diện mà không phát sinh giao dịch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, size) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.maxHeight - 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Brand(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Bỏ qua Premium',
                      onPressed: widget.onContinue,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Center(
                  child: HeroPreview(size: size.maxWidth.clamp(240.0, 360.0)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Make every drive\nyour own.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cá nhân hóa màn hình xe với widget, âm thanh và card mang dấu ấn của bạn.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 22),
                const Feature(
                  icon: Icons.widgets_rounded,
                  label: 'Widget theo phong cách của bạn',
                ),
                const Feature(
                  icon: Icons.graphic_eq_rounded,
                  label: 'Âm thanh khởi động cảm hứng',
                ),
                const Feature(
                  icon: Icons.style_rounded,
                  label: 'Card cho từng hành trình',
                ),
                const SizedBox(height: 22),
                for (var index = 0; index < 2; index++) ...[
                  ListTile(
                    onTap: () => setState(() => plan = index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: plan == index ? lime : panel),
                    ),
                    tileColor: panel,
                    title: Text(
                      index == 0 ? 'Premium hàng năm' : 'Premium trọn đời',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Giá sẽ được cung cấp từ cửa hàng'),
                    trailing: Icon(
                      plan == index
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: plan == index ? lime : muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: showPurchaseNotice,
                    style: FilledButton.styleFrom(
                      backgroundColor: lime,
                      foregroundColor: ink,
                    ),
                    child: const Text(
                      'Mua Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: widget.onContinue,
                    child: const Text('Khám phá ứng dụng'),
                  ),
                ),
                const Center(
                  child: Text(
                    'Bản xem trước · Chưa tích hợp thanh toán',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
