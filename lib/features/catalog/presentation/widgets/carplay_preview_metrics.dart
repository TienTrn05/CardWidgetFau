import 'dart:math' as math;

import 'package:flutter/material.dart';

double carPlayWidgetPreviewSize(BuildContext context, double previewWidth) {
  final contentWidth = previewWidth - 16;
  final railWidth = contentWidth * .17;
  final availableCardWidth = (contentWidth - railWidth - 21) / 2;
  final screenBasedSize = MediaQuery.sizeOf(context).width * .4;
  return math.min(screenBasedSize, availableCardWidth);
}

double editorWidgetPreviewSize(BoxConstraints constraints) => math.min(
  math.max(0.0, constraints.maxWidth - 24),
  math.max(0.0, constraints.maxHeight - 24),
);
