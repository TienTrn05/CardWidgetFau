import 'package:carwidget/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

Future<void> showTutorialSheet(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.82,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Close tutorial',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(height: 8),
          const Text(
            'How to Add Widget to CarPlay?',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: const [
                _VideoPlaceholder(),
                SizedBox(height: 20),
                _GuideStep(
                  number: '1',
                  text: 'When parked, open Settings on your iPhone.',
                ),
                _GuideStep(
                  number: '2',
                  text: 'Go to General, then CarPlay, and select your car.',
                ),
                _GuideStep(
                  number: '3',
                  text: 'Open Widgets and tap Add Widgets.',
                ),
                SizedBox(height: 8),
                Text(
                  'CarWidget will appear in this list after its iOS widget extension is added.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    ),
  ),
);

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, color: AppColors.green, size: 58),
          SizedBox(height: 10),
          Text('Video walkthrough coming soon'),
        ],
      ),
    ),
  );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.green,
          child: Text(
            number,
            style: const TextStyle(color: AppColors.background),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    ),
  );
}
