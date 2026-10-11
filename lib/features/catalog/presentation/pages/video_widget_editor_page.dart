import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/presentation/pages/video_widget_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoWidgetEditorPage extends StatefulWidget {
  const VideoWidgetEditorPage({
    super.key,
    required this.videoPath,
    required this.videoName,
  });

  final String videoPath;
  final String videoName;

  @override
  State<VideoWidgetEditorPage> createState() => _VideoWidgetEditorPageState();
}

class _VideoWidgetEditorPageState extends State<VideoWidgetEditorPage> {
  late final VideoPlayerController _videoController;
  final List<Uint8List?> _frames = [];
  var _isLoading = true;
  var _isSaving = false;
  String? _loadError;
  int _totalDurationMs = 0;
  int _trimStartMs = 0;
  int _trimDurationMs = 0;
  double _timelineWidth = 1;
  _TrimDragMode? _dragMode;

  int get _trimEndMs => _trimStartMs + _trimDurationMs;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();
      _totalDurationMs = _videoController.value.duration.inMilliseconds;
      if (_totalDurationMs <= 0) {
        throw const FormatException('The selected video has no duration.');
      }
      _trimDurationMs = math.min(3000, _totalDurationMs);
      _videoController.addListener(_handleVideoProgress);
      await _videoController.setLooping(false);
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _loadTimelineFrames();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not open this video.';
      });
    }
  }

  Future<void> _loadTimelineFrames() async {
    const frameCount = 8;
    final frames = <Uint8List?>[];
    for (var index = 0; index < frameCount; index++) {
      final timeMs = _totalDurationMs <= 1
          ? 0
          : ((_totalDurationMs - 1) * index / (frameCount - 1)).round();
      try {
        frames.add(
          await VideoThumbnail.thumbnailData(
            video: widget.videoPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 180,
            timeMs: timeMs,
            quality: 45,
          ),
        );
      } catch (_) {
        frames.add(null);
      }
    }
    if (!mounted) return;
    setState(() {
      _frames
        ..clear()
        ..addAll(frames);
    });
  }

  void _handleVideoProgress() {
    if (!_videoController.value.isInitialized) return;
    final positionMs = _videoController.value.position.inMilliseconds;
    if (_videoController.value.isPlaying && positionMs >= _trimEndMs) {
      _videoController.pause();
      _videoController.seekTo(Duration(milliseconds: _trimStartMs));
    }
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayback() async {
    if (!_videoController.value.isInitialized) return;
    if (_videoController.value.isPlaying) {
      await _videoController.pause();
      return;
    }
    final positionMs = _videoController.value.position.inMilliseconds;
    if (positionMs < _trimStartMs || positionMs >= _trimEndMs) {
      await _videoController.seekTo(Duration(milliseconds: _trimStartMs));
    }
    await _videoController.play();
  }

  void _selectDuration(int seconds) {
    final requestedDurationMs = seconds * 1000;
    if (requestedDurationMs > _totalDurationMs) return;
    setState(() {
      _trimDurationMs = requestedDurationMs;
      _trimStartMs = math.min(_trimStartMs, _totalDurationMs - _trimDurationMs);
    });
    _videoController.pause();
    _videoController.seekTo(Duration(milliseconds: _trimStartMs));
  }

  void _startTimelineDrag(DragStartDetails details) {
    final startFraction = _trimStartMs / _totalDurationMs;
    final endFraction = _trimEndMs / _totalDurationMs;
    final pointerFraction = (details.localPosition.dx / _timelineWidth).clamp(
      0.0,
      1.0,
    );
    final handleTolerance = 24 / _timelineWidth;

    if ((pointerFraction - startFraction).abs() <= handleTolerance) {
      _dragMode = _TrimDragMode.start;
    } else if ((pointerFraction - endFraction).abs() <= handleTolerance) {
      _dragMode = _TrimDragMode.end;
    } else if (pointerFraction >= startFraction &&
        pointerFraction <= endFraction) {
      _dragMode = _TrimDragMode.window;
    } else {
      _dragMode =
          (pointerFraction - startFraction).abs() <
              (pointerFraction - endFraction).abs()
          ? _TrimDragMode.start
          : _TrimDragMode.end;
    }
  }

  void _updateTimelineDrag(DragUpdateDetails details) {
    final deltaFraction = details.delta.dx / _timelineWidth;
    var startFraction = _trimStartMs / _totalDurationMs;
    var endFraction = _trimEndMs / _totalDurationMs;
    final minLength = math.min(1000 / _totalDurationMs, 1.0);
    final maxLength = math.min(4000 / _totalDurationMs, 1.0);

    switch (_dragMode) {
      case _TrimDragMode.start:
        startFraction = (startFraction + deltaFraction).clamp(
          math.max(0.0, endFraction - maxLength),
          endFraction - minLength,
        );
      case _TrimDragMode.end:
        endFraction = (endFraction + deltaFraction).clamp(
          startFraction + minLength,
          math.min(1.0, startFraction + maxLength),
        );
      case _TrimDragMode.window:
        final length = endFraction - startFraction;
        startFraction = (startFraction + deltaFraction).clamp(
          0.0,
          1.0 - length,
        );
        endFraction = startFraction + length;
      case null:
        return;
    }

    setState(() {
      _trimStartMs = (startFraction * _totalDurationMs).round();
      _trimDurationMs = ((endFraction - startFraction) * _totalDurationMs)
          .round();
    });
  }

  void _finishTimelineDrag(DragEndDetails details) {
    _dragMode = null;
    _videoController.pause();
    _videoController.seekTo(Duration(milliseconds: _trimStartMs));
  }

  Future<void> _continue() async {
    if (_isSaving || _trimDurationMs <= 0) return;
    setState(() => _isSaving = true);
    await _videoController.pause();

    Uint8List? coverThumbnail;
    try {
      coverThumbnail = await VideoThumbnail.thumbnailData(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 640,
        timeMs: _trimStartMs,
        quality: 80,
      );
    } catch (_) {
      coverThumbnail = _nearestTimelineFrame();
    }
    coverThumbnail ??= _nearestTimelineFrame();

    if (!mounted) return;
    if (coverThumbnail == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not create a video preview.')),
        );
      return;
    }

    final didAddWidget = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VideoWidgetPreviewPage(
          videoPath: widget.videoPath,
          videoName: widget.videoName,
          videoStartMs: _trimStartMs,
          videoDurationMs: _trimDurationMs,
          videoThumbnail: coverThumbnail!,
        ),
      ),
    );
    if (!mounted) return;
    if (didAddWidget == true) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
    }
  }

  Uint8List? _nearestTimelineFrame() {
    if (_frames.isEmpty) return null;
    final fraction = _trimStartMs / _totalDurationMs;
    final index = (fraction * (_frames.length - 1)).round();
    return _frames[index];
  }

  @override
  void dispose() {
    _videoController.removeListener(_handleVideoProgress);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Edit Widget',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _buildVideoPreview(),
                  ),
                ),
              ),
              _buildDurationOptions(),
              const SizedBox(height: 22),
              _buildTimeline(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: _isLoading || _loadError != null || _isSaving
                      ? null
                      : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.green.withValues(
                      alpha: .35,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.background,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildVideoPreview() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Text(
          _loadError!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      );
    }

    final value = _videoController.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio,
                child: VideoPlayer(_videoController),
              ),
            ),
            Material(
              color: Colors.black.withValues(alpha: .52),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _togglePlayback,
                child: SizedBox.square(
                  dimension: 76,
                  child: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOptions() => Row(
    children: List.generate(4, (index) {
      final seconds = index + 1;
      final isAvailable = seconds * 1000 <= _totalDurationMs;
      final isSelected = (_trimDurationMs - seconds * 1000).abs() < 80;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
          child: _DurationOption(
            seconds: seconds,
            selected: isSelected,
            enabled: isAvailable && !_isLoading && _loadError == null,
            onTap: () => _selectDuration(seconds),
          ),
        ),
      );
    }),
  );

  Widget _buildTimeline() => LayoutBuilder(
    builder: (context, constraints) {
      _timelineWidth = constraints.maxWidth;
      final startFraction = _totalDurationMs == 0
          ? 0.0
          : _trimStartMs / _totalDurationMs;
      final endFraction = _totalDurationMs == 0
          ? 1.0
          : _trimEndMs / _totalDurationMs;

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _totalDurationMs == 0
              ? null
              : _startTimelineDrag,
          onHorizontalDragUpdate: _totalDurationMs == 0
              ? null
              : _updateTimelineDrag,
          onHorizontalDragEnd: _totalDurationMs == 0
              ? null
              : _finishTimelineDrag,
          child: SizedBox(
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Row(
                  children: List.generate(8, (index) {
                    final frame = index < _frames.length
                        ? _frames[index]
                        : null;
                    return Expanded(
                      child: frame == null
                          ? const ColoredBox(color: AppColors.surface)
                          : Image.memory(frame, fit: BoxFit.cover),
                    );
                  }),
                ),
                CustomPaint(
                  painter: _TrimSelectionPainter(
                    start: startFraction,
                    end: endFraction,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

enum _TrimDragMode { start, end, window }

class _DurationOption extends StatelessWidget {
  const _DurationOption({
    required this.seconds,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int seconds;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.selectedSurface : AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.green
                : const Color(0xFF39424A).withValues(alpha: .8),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            color: enabled
                ? Colors.white
                : AppColors.muted.withValues(alpha: .4),
            fontSize: 17,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class _TrimSelectionPainter extends CustomPainter {
  const _TrimSelectionPainter({required this.start, required this.end});

  final double start;
  final double end;

  @override
  void paint(Canvas canvas, Size size) {
    final left = (start * size.width).clamp(0.0, size.width);
    final right = (end * size.width).clamp(left, size.width);
    final outsidePaint = Paint()..color = Colors.black.withValues(alpha: .48);
    final selectionRect = Rect.fromLTRB(left, 0, right, size.height);

    canvas.drawRect(Rect.fromLTRB(0, 0, left, size.height), outsidePaint);
    canvas.drawRect(
      Rect.fromLTRB(right, 0, size.width, size.height),
      outsidePaint,
    );
    canvas.drawRect(
      selectionRect,
      Paint()..color = AppColors.green.withValues(alpha: .25),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        selectionRect.deflate(1.5),
        const Radius.circular(12),
      ),
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final handlePaint = Paint()
      ..color = AppColors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final handleTop = size.height * .28;
    final handleBottom = size.height * .72;
    canvas.drawLine(
      Offset(left + 3, handleTop),
      Offset(left + 3, handleBottom),
      handlePaint,
    );
    canvas.drawLine(
      Offset(right - 3, handleTop),
      Offset(right - 3, handleBottom),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrimSelectionPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}
