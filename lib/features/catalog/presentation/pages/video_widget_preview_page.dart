import 'dart:io';
import 'dart:typed_data';

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show addVideoWidgetToMyWidgets;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidgetPreviewPage extends StatefulWidget {
  const VideoWidgetPreviewPage({
    super.key,
    required this.videoPath,
    required this.videoName,
    required this.videoStartMs,
    required this.videoDurationMs,
    required this.videoThumbnail,
  });

  final String videoPath;
  final String videoName;
  final int videoStartMs;
  final int videoDurationMs;
  final Uint8List videoThumbnail;

  @override
  State<VideoWidgetPreviewPage> createState() => _VideoWidgetPreviewPageState();
}

class _VideoWidgetPreviewPageState extends State<VideoWidgetPreviewPage> {
  late final VideoPlayerController _videoController;
  var _isReady = false;
  var _isSaving = false;
  var _loadFailed = false;

  int get _trimEndMs => widget.videoStartMs + widget.videoDurationMs;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      final durationMs = _videoController.value.duration.inMilliseconds;
      final startMs = widget.videoStartMs.clamp(0, durationMs);
      await _videoController.seekTo(Duration(milliseconds: startMs));
      _videoController.addListener(_handlePlayback);
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  void _handlePlayback() {
    if (!_videoController.value.isInitialized) return;
    if (_videoController.value.isPlaying &&
        _videoController.value.position.inMilliseconds >= _trimEndMs) {
      _videoController.pause();
      _videoController.seekTo(Duration(milliseconds: widget.videoStartMs));
    }
    if (mounted) setState(() {});
  }

  Future<void> _togglePreview() async {
    if (!_isReady) return;
    if (_videoController.value.isPlaying) {
      await _videoController.pause();
      return;
    }
    final positionMs = _videoController.value.position.inMilliseconds;
    if (positionMs < widget.videoStartMs || positionMs >= _trimEndMs) {
      await _videoController.seekTo(
        Duration(milliseconds: widget.videoStartMs),
      );
    }
    await _videoController.play();
  }

  Future<void> _addToMyWidgets() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await _videoController.pause();
    addVideoWidgetToMyWidgets(
      videoPath: widget.videoPath,
      videoName: widget.videoName,
      videoStartMs: widget.videoStartMs,
      videoDurationMs: widget.videoDurationMs,
      videoThumbnail: widget.videoThumbnail,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Video preview'),
        content: const Text(
          'Preview the selected video segment. Add it to My Widgets when it looks right.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_handlePlayback);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Preview',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        tooltip: 'Preview information',
                        onPressed: _showInfo,
                        icon: const Icon(
                          Icons.info_rounded,
                          color: AppColors.green,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final previewSize = constraints.maxWidth
                        .clamp(0.0, constraints.maxHeight * .68)
                        .clamp(0.0, 420.0);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          dimension: previewSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  widget.videoThumbnail,
                                  fit: BoxFit.cover,
                                ),
                                if (_isReady)
                                  FittedBox(
                                    fit: BoxFit.cover,
                                    clipBehavior: Clip.hardEdge,
                                    child: SizedBox(
                                      width: _videoController.value.size.width,
                                      height:
                                          _videoController.value.size.height,
                                      child: VideoPlayer(_videoController),
                                    ),
                                  ),
                                if (!_isReady && !_loadFailed)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.green,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _PreviewButton(
                          isPlaying:
                              _isReady && _videoController.value.isPlaying,
                          enabled: _isReady,
                          onTap: _togglePreview,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: _isSaving ? null : _addToMyWidgets,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.green.withValues(
                      alpha: .45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
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
                          'Add to My Widget',
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
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.isPlaying,
    required this.enabled,
    required this.onTap,
  });

  final bool isPlaying;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              color: AppColors.green,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              isPlaying ? 'Pause Preview' : 'Preview',
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.muted,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
