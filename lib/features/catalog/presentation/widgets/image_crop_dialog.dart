import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carwidget/app/theme/app_theme.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

Future<Uint8List?> showImageCropDialog(
  BuildContext context,
  Uint8List imageBytes,
) => showDialog<Uint8List>(
  context: context,
  barrierDismissible: false,
  builder: (_) => Dialog.fullscreen(
    backgroundColor: AppColors.background,
    child: _ImageCropDialog(imageBytes: imageBytes),
  ),
);

class _ImageCropDialog extends StatefulWidget {
  const _ImageCropDialog({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<_ImageCropDialog> {
  ui.Image? _originalImage;
  ui.Image? _image;
  Rect _cropRect = Rect.zero;
  Size _viewportSize = Size.zero;
  double _scale = 1;
  double _gestureStartScale = 1;
  Offset _imageOffset = Offset.zero;
  int _rotationQuarterTurns = 0;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    if (_image != _originalImage) _image?.dispose();
    _originalImage?.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _scale;
  }

  void _handleScaleUpdate(
    ScaleUpdateDetails details,
    ui.Image image,
    Size viewportSize,
    Rect cropRect,
  ) {
    final nextScale = (_gestureStartScale * details.scale)
        .clamp(1.0, 5.0)
        .toDouble();
    final imageScale = _baseImageScale(image, viewportSize) * nextScale;
    final renderedWidth = image.width * imageScale;
    final renderedHeight = image.height * imageScale;
    final centeredLeft = (viewportSize.width - renderedWidth) / 2;
    final centeredTop = (viewportSize.height - renderedHeight) / 2;
    final nextOffset = _imageOffset + details.focalPointDelta;
    final left = (centeredLeft + nextOffset.dx)
        .clamp(cropRect.right - renderedWidth, cropRect.left)
        .toDouble();
    final top = (centeredTop + nextOffset.dy)
        .clamp(cropRect.bottom - renderedHeight, cropRect.top)
        .toDouble();

    setState(() {
      _scale = nextScale;
      _imageOffset = Offset(left - centeredLeft, top - centeredTop);
    });
  }

  double _baseImageScale(ui.Image image, Size viewportSize) => math
      .max(viewportSize.width / image.width, viewportSize.height / image.height)
      .toDouble();

  void _resetCrop() {
    if (_isRotating) return;
    final previousImage = _image;
    setState(() {
      _image = _originalImage;
      _rotationQuarterTurns = 0;
      _scale = 1;
      _imageOffset = Offset.zero;
    });
    if (previousImage != null && previousImage != _originalImage) {
      previousImage.dispose();
    }
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() {
      _originalImage = frame.image;
      _image = frame.image;
    });
  }

  Future<void> _rotateImageBy(int quarterTurns) async {
    final originalImage = _originalImage;
    if (originalImage == null || _isRotating) return;

    final turns = (_rotationQuarterTurns + quarterTurns) % 4;
    final nextTurns = turns < 0 ? turns + 4 : turns;
    setState(() => _isRotating = true);

    ui.Image? rotatedImage;
    try {
      if (nextTurns != 0) {
        final rotatedWidth = nextTurns.isOdd
            ? originalImage.height
            : originalImage.width;
        final rotatedHeight = nextTurns.isOdd
            ? originalImage.width
            : originalImage.height;
        final recorder = ui.PictureRecorder();
        Canvas(recorder)
          ..translate(rotatedWidth / 2, rotatedHeight / 2)
          ..rotate(nextTurns * math.pi / 2)
          ..drawImage(
            originalImage,
            Offset(-originalImage.width / 2, -originalImage.height / 2),
            Paint()..filterQuality = FilterQuality.high,
          );
        final picture = recorder.endRecording();
        rotatedImage = await picture.toImage(rotatedWidth, rotatedHeight);
        picture.dispose();
      }

      if (!mounted) {
        rotatedImage?.dispose();
        return;
      }

      final previousImage = _image;
      setState(() {
        _rotationQuarterTurns = nextTurns;
        _image = rotatedImage ?? originalImage;
        _scale = 1;
        _imageOffset = Offset.zero;
        _isRotating = false;
      });
      if (previousImage != null && previousImage != originalImage) {
        previousImage.dispose();
      }
    } catch (_) {
      rotatedImage?.dispose();
      if (!mounted) return;
      setState(() => _isRotating = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not rotate this image.')),
        );
    }
  }

  Future<void> _chooseCrop(Rect cropRect, Size viewportSize) async {
    final image = _image;
    if (image == null) return;

    try {
      final imageScale = _baseImageScale(image, viewportSize) * _scale;
      final renderedWidth = image.width * imageScale;
      final renderedHeight = image.height * imageScale;
      final renderedLeft =
          (viewportSize.width - renderedWidth) / 2 + _imageOffset.dx;
      final renderedTop =
          (viewportSize.height - renderedHeight) / 2 + _imageOffset.dy;
      final sourceSide = math.min(cropRect.width, cropRect.height) / imageScale;
      final sourceLeft = ((cropRect.left - renderedLeft) / imageScale)
          .clamp(0.0, image.width - sourceSide)
          .toDouble();
      final sourceTop = ((cropRect.top - renderedTop) / imageScale)
          .clamp(0.0, image.height - sourceSide)
          .toDouble();
      final sourceRect = Rect.fromLTWH(
        sourceLeft,
        sourceTop,
        sourceSide,
        sourceSide,
      );
      const outputSize = 1024;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        sourceRect,
        const Rect.fromLTWH(0, 0, 1024, 1024),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(outputSize, outputSize);
      picture.dispose();
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      croppedImage.dispose();
      if (byteData == null) {
        throw StateError('Could not encode the cropped image.');
      }

      if (mounted) {
        Navigator.of(context).pop(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not crop this image.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.background,
    child: Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: _image == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportSize = constraints.biggest;
                      final cropSize = math.min(
                        viewportSize.width - 36,
                        viewportSize.height * .62,
                      );
                      final cropRect = Rect.fromCenter(
                        center: Offset(
                          viewportSize.width / 2,
                          viewportSize.height / 2,
                        ),
                        width: cropSize,
                        height: cropSize,
                      );
                      _viewportSize = viewportSize;
                      _cropRect = cropRect;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: (details) => _handleScaleUpdate(
                              details,
                              _image!,
                              viewportSize,
                              cropRect,
                            ),
                            child: ClipRect(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Positioned(
                                    left:
                                        (viewportSize.width -
                                                _image!.width *
                                                    _baseImageScale(
                                                      _image!,
                                                      viewportSize,
                                                    ) *
                                                    _scale) /
                                            2 +
                                        _imageOffset.dx,
                                    top:
                                        (viewportSize.height -
                                                _image!.height *
                                                    _baseImageScale(
                                                      _image!,
                                                      viewportSize,
                                                    ) *
                                                    _scale) /
                                            2 +
                                        _imageOffset.dy,
                                    width:
                                        _image!.width *
                                        _baseImageScale(_image!, viewportSize) *
                                        _scale,
                                    height:
                                        _image!.height *
                                        _baseImageScale(_image!, viewportSize) *
                                        _scale,
                                    child: RawImage(
                                      image: _image,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _CropScrimPainter(cropRect),
                            ),
                          ),
                          Positioned(
                            left: cropRect.left,
                            top: cropRect.top,
                            width: cropRect.width,
                            height: cropRect.height,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: const _CropFramePainter(),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            left: 12,
                            right: 12,
                            child: IgnorePointer(
                              child: Text(
                                'Drag or pinch to adjust the crop',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .82),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        _CropToolbar(
          onCancel: () => Navigator.of(context).pop(),
          onRotateLeft: () => _rotateImageBy(-1),
          onReset: _resetCrop,
          onRotateRight: () => _rotateImageBy(1),
          onChoose: () => _chooseCrop(_cropRect, _viewportSize),
          isReady: _image != null && !_isRotating,
        ),
      ],
    ),
  );
}

class _CropToolbar extends StatelessWidget {
  const _CropToolbar({
    required this.onCancel,
    required this.onRotateLeft,
    required this.onReset,
    required this.onRotateRight,
    required this.onChoose,
    required this.isReady,
  });

  final VoidCallback onCancel;
  final VoidCallback onRotateLeft;
  final VoidCallback onReset;
  final VoidCallback onRotateRight;
  final VoidCallback onChoose;
  final bool isReady;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF252D33),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Rotate left',
                onPressed: isReady ? onRotateLeft : null,
                icon: Transform.flip(
                  flipX: true,
                  child: const Icon(CupertinoIcons.crop_rotate, size: 29),
                ),
              ),
              IconButton(
                tooltip: 'Reset crop',
                onPressed: isReady ? onReset : null,
                icon: const Icon(Icons.refresh_rounded, size: 27),
              ),
              IconButton(
                tooltip: 'Rotate right',
                onPressed: isReady ? onRotateRight : null,
                icon: const Icon(CupertinoIcons.crop_rotate, size: 29),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isReady ? onChoose : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.green,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Choose'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CropScrimPainter extends CustomPainter {
  const _CropScrimPainter(this.cropRect);

  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);
    canvas.drawPath(path, Paint()..color = const Color(0x99000000));
  }

  @override
  bool shouldRepaint(covariant _CropScrimPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}

class _CropFramePainter extends CustomPainter {
  const _CropFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, edgePaint);

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    const cornerLength = 34.0;
    canvas
      ..drawLine(Offset.zero, const Offset(cornerLength, 0), cornerPaint)
      ..drawLine(Offset.zero, const Offset(0, cornerLength), cornerPaint)
      ..drawLine(
        Offset(size.width, 0),
        Offset(size.width - cornerLength, 0),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width, 0),
        Offset(size.width, cornerLength),
        cornerPaint,
      )
      ..drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height),
        cornerPaint,
      )
      ..drawLine(
        Offset(0, size.height),
        Offset(0, size.height - cornerLength),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height),
        cornerPaint,
      )
      ..drawLine(
        Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength),
        cornerPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _CropFramePainter oldDelegate) => false;
}
