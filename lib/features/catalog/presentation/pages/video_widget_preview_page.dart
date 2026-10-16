import 'dart:io';
import 'dart:typed_data';

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/settings/presentation/widgets/tutorial_sheet.dart';
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
    required this.onAddVideoWidget,
  });

  final String videoPath;
  final String videoName;
  final int videoStartMs;
  final int videoDurationMs;
  final Uint8List videoThumbnail;
  final void Function(int startMs, int durationMs, Uint8List thumbnail)
  onAddVideoWidget;

  @override
  State<VideoWidgetPreviewPage> createState() => _VideoWidgetPreviewPageState();
}

class _VideoWidgetPreviewPageState extends State<VideoWidgetPreviewPage> {
  late final VideoPlayerController _videoController;
  var _isReady = false;
  var _isSaving = false;
  var _loadFailed = false;
  var _isRestarting = false;
  var _isDisposed = false;

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
      await _videoController.setVolume(0);
      await _videoController.setLooping(false);
      final durationMs = _videoController.value.duration.inMilliseconds;
      final startMs = widget.videoStartMs.clamp(0, durationMs);
      await _videoController.seekTo(Duration(milliseconds: startMs));
      _videoController.addListener(_handlePlayback);
      if (!mounted) return;
      setState(() => _isReady = true);
      await _videoController.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  void _handlePlayback() {
    if (_isDisposed || !mounted) return;
    if (!_videoController.value.isInitialized) return;
    if (_videoController.value.isPlaying &&
        _videoController.value.position.inMilliseconds >= _trimEndMs &&
        !_isRestarting) {
      _restartTrimmedPlayback();
    }
    if (mounted) setState(() {});
  }

  Future<void> _restartTrimmedPlayback() async {
    if (_isDisposed || !mounted || _isRestarting) return;
    _isRestarting = true;
    try {
      await _videoController.pause();
      if (_isDisposed || !mounted) return;
      await _videoController.seekTo(
        Duration(milliseconds: widget.videoStartMs),
      );
      if (!_isDisposed && mounted && !_isSaving) {
        await _videoController.play();
      }
    } catch (_) {
      // The controller can finish an in-flight operation as the page closes.
    } finally {
      _isRestarting = false;
    }
  }

  Future<void> _addToMyWidgets() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await _videoController.pause();
    widget.onAddVideoWidget(
      widget.videoStartMs,
      widget.videoDurationMs,
      widget.videoThumbnail,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showInfo() => showTutorialSheet(context);

  @override
  void dispose() {
    _isDisposed = true;
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
                    final previewSize =
                        editorWidgetPreviewSize(constraints) * .9;
                    return Center(
                      child: SizedBox.square(
                        dimension: previewSize,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
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
                                    height: _videoController.value.size.height,
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
