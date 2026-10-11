import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/widget_type.dart';
import 'package:carwidget/features/catalog/presentation/pages/video_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show savedWidgetsListenable, showSavedWidgetPreview;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoWidgetsSection extends StatelessWidget {
  const VideoWidgetsSection({super.key});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SavedWidgetModel>>(
        valueListenable: savedWidgetsListenable,
        builder: (context, widgets, _) {
          final videoWidgets = widgets
              .where((widget) => widget.type == WidgetType.video)
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Video Widgets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _SeeAllButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VideoWidgetsPage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardSize = carPlayWidgetPreviewSize(
                    context,
                    constraints.maxWidth,
                  );
                  return SizedBox(
                    height: cardSize,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: videoWidgets.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => SizedBox.square(
                        dimension: cardSize,
                        child: index == 0
                            ? const _AddVideoWidgetTile()
                            : _VideoWidgetTile(widget: videoWidgets[index - 1]),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
}

class VideoWidgetsPage extends StatelessWidget {
  const VideoWidgetsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'Video Widgets',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ValueListenableBuilder<List<SavedWidgetModel>>(
        valueListenable: savedWidgetsListenable,
        builder: (context, widgets, _) {
          final videoWidgets = widgets
              .where((widget) => widget.type == WidgetType.video)
              .toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              final cardSize = carPlayWidgetPreviewSize(
                context,
                constraints.maxWidth - 48,
              );
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  mainAxisExtent: cardSize,
                ),
                itemCount: videoWidgets.length + 1,
                itemBuilder: (context, index) => Center(
                  child: SizedBox.square(
                    dimension: cardSize,
                    child: index == 0
                        ? const _AddVideoWidgetTile()
                        : _VideoWidgetTile(widget: videoWidgets[index - 1]),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        child: Text(
          'See All',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

class _VideoWidgetTile extends StatelessWidget {
  const _VideoWidgetTile({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF252D33),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => showSavedWidgetPreview(context, widget),
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _VideoThumbnail(widget: widget),
      ),
    ),
  );
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF252D33),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (widget.videoThumbnail != null)
          Image.memory(widget.videoThumbnail!, fit: BoxFit.cover)
        else
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.green,
              size: 48,
            ),
          ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 8,
          child: Text(
            widget.videoName ?? widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black, blurRadius: 5)],
            ),
          ),
        ),
      ],
    ),
  );
}

class _AddVideoWidgetTile extends StatelessWidget {
  const _AddVideoWidgetTile();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => _pickVideo(context),
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        foregroundPainter: const _VideoWidgetDashedBorderPainter(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: .12,
                      child: Container(
                        width: 76,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF087453),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -.12,
                      child: Container(
                        width: 76,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.background,
                          size: 38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Widget',
                style: TextStyle(color: AppColors.muted, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _pickVideo(BuildContext context) async {
    try {
      final selectedVideo = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
      if (selectedVideo == null || !context.mounted) return;

      final wasAdded = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VideoWidgetEditorPage(
            videoPath: selectedVideo.path,
            videoName: selectedVideo.name,
          ),
        ),
      );
      if (!context.mounted || wasAdded != true) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Video added to My Widgets.')),
        );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the video library.')),
        );
    }
  }
}

class _VideoWidgetDashedBorderPainter extends CustomPainter {
  const _VideoWidgetDashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(24),
        ).deflate(1.5),
      );
    final paint = Paint()
      ..color = AppColors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final dashEnd = (distance + 8).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, dashEnd), paint);
        distance += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
