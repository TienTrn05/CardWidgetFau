import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/presentation/pages/video_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show
        SavedWidgetArtwork,
        addVideoWidgetToLibrary,
        removeVideoWidgetFromLibrary,
        showVideoWidgetPreview,
        videoWidgetsListenable;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VideoWidgetsSection extends StatelessWidget {
  const VideoWidgetsSection({super.key});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SavedWidgetModel>>(
        valueListenable: videoWidgetsListenable,
        builder: (context, widgets, _) {
          final videoWidgets = widgets;
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
        valueListenable: videoWidgetsListenable,
        builder: (context, widgets, _) {
          final videoWidgets = widgets;
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
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: SizedBox.square(
                        dimension: cardSize,
                        child: const _AddVideoWidgetTile(),
                      ),
                    );
                  }

                  final videoWidget = videoWidgets[index - 1];
                  return Center(
                    child: SizedBox.square(
                      dimension: cardSize,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _VideoWidgetTile(widget: videoWidget),
                          ),
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Material(
                              color: const Color(0xCC080D12),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => removeVideoWidgetFromLibrary(
                                  videoWidget.id,
                                ),
                                child: const SizedBox.square(
                                  dimension: 25,
                                  child: Icon(Icons.close_rounded, size: 17),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(6, 0),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.5, vertical: 4.5),
          child: Text(
            'See All',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
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
      onTap: () => showVideoWidgetPreview(context, widget),
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SavedWidgetArtwork(widget: widget),
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
      ),
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
                width: 56,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: .12,
                      child: Container(
                        width: 50,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF087453),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -.12,
                      child: Container(
                        width: 50,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.background,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Widget',
                style: TextStyle(color: Colors.white, fontSize: 18),
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

      final localVideoPath = await LocalStateStore.instance.importVideo(
        selectedVideo.path,
      );
      if (!context.mounted) return;

      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => VideoWidgetEditorPage(
            videoPath: localVideoPath,
            videoName: selectedVideo.name,
            onAddVideoWidget: (startMs, durationMs, thumbnail) {
              addVideoWidgetToLibrary(
                videoPath: localVideoPath,
                videoName: selectedVideo.name,
                videoStartMs: startMs,
                videoDurationMs: durationMs,
                videoThumbnail: thumbnail,
              );
            },
          ),
        ),
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
      ..strokeWidth = 1.2;

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
