import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/settings/data/widget_tutorial_content.dart';
import 'package:flutter/material.dart';

class WidgetTutorialPage extends StatefulWidget {
  const WidgetTutorialPage({super.key});

  @override
  State<WidgetTutorialPage> createState() => _WidgetTutorialPageState();
}

class _WidgetTutorialPageState extends State<WidgetTutorialPage> {
  int _selectedTab = 0;
  late final Future<WidgetTutorialContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = WidgetTutorialContent.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WidgetTutorialContent>(
    future: _contentFuture,
    initialData: WidgetTutorialContent.cached,
    builder: (context, snapshot) {
      final content = snapshot.data;
      return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: AppColors.background,
          centerTitle: true,
          title: Text(
            content?.title ?? '',
            style: const TextStyle(fontSize: 18),
          ),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
        ),
        body: SafeArea(
          child: content == null
              ? Center(
                  child: snapshot.hasError
                      ? const Text('Tutorial could not be loaded.')
                      : const Text('Loading tutorial...'),
                )
              : _buildContent(content),
        ),
      );
    },
  );

  Widget _buildContent(WidgetTutorialContent content) {
    if (content.tabs.isEmpty) {
      return const Center(child: Text('No tutorial tabs are available.'));
    }
    final selectedIndex = _selectedTab.clamp(0, content.tabs.length - 1);
    final selectedTab = content.tabs[selectedIndex];
    final hasNote = selectedTab.note != null && selectedTab.note!.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _TutorialTabs(
            tabs: content.tabs,
            selectedTab: selectedIndex,
            onSelected: (index) => setState(() => _selectedTab = index),
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: ValueKey(selectedTab.id),
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            itemCount: selectedTab.steps.length + (hasNote ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 28),
            itemBuilder: (context, index) {
              if (index == selectedTab.steps.length) {
                return Text(
                  '${content.noteLabel}: ${selectedTab.note}',
                  key: const ValueKey('tutorial-note'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                );
              }
              return _TutorialStep(
                number: index + 1,
                stepLabel: content.stepLabel,
                imagePlaceholderLabel: content.imagePlaceholderLabel,
                data: selectedTab.steps[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TutorialTabs extends StatelessWidget {
  const _TutorialTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<WidgetTutorialTab> tabs;
  final int selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selectedTab == index,
                child: Material(
                  color: selectedTab == index
                      ? AppColors.green
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        tabs[index].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedTab == index
                              ? AppColors.background
                              : AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.number,
    required this.stepLabel,
    required this.imagePlaceholderLabel,
    required this.data,
  });

  final int number;
  final String stepLabel;
  final String imagePlaceholderLabel;
  final WidgetTutorialStep data;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey('tutorial-step-$number'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$stepLabel $number: ',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: data.instruction),
          ],
        ),
        style: const TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
      ),
      for (
        var imageIndex = 0;
        imageIndex < data.images.length;
        imageIndex++
      ) ...[
        const SizedBox(height: 20),
        AspectRatio(
          key: ValueKey('tutorial-image-$number-${imageIndex + 1}'),
          aspectRatio: data.images[imageIndex].aspectRatio,
          child: data.images[imageIndex].asset != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    data.images[imageIndex].asset!,
                    fit: BoxFit.contain,
                  ),
                )
              : _TutorialImagePlaceholder(
                  label: data.images.length == 1
                      ? '$imagePlaceholderLabel $number'
                      : '$imagePlaceholderLabel $number.${imageIndex + 1}',
                  data: data.images[imageIndex],
                ),
        ),
      ],
    ],
  );
}

class _TutorialImagePlaceholder extends StatelessWidget {
  const _TutorialImagePlaceholder({required this.label, required this.data});

  final String label;
  final WidgetTutorialImage data;

  IconData get icon => switch (data.placeholderIcon) {
    'search' => Icons.search_rounded,
    'add' => Icons.add_circle_outline_rounded,
    'list' => Icons.list_alt_rounded,
    _ => Icons.image_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final lightImage = data.placeholderTone == 'light';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: lightImage ? const Color(0xFFEDEDF2) : const Color(0xFF414B5B),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 42,
            color: lightImage ? const Color(0xFF88909E) : AppColors.white,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: lightImage ? const Color(0xFF687382) : AppColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
