import 'package:carwidget/features/cards/data/models/affirmation_model.dart';
import 'package:flutter/material.dart';

class AffirmationCardArtwork extends StatelessWidget {
  const AffirmationCardArtwork({
    super.key,
    required this.affirmation,
    this.textSize = 15,
  });

  final AffirmationModel affirmation;
  final double textSize;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
    decoration: BoxDecoration(
      color: Color(affirmation.backgroundColorValue),
      borderRadius: BorderRadius.circular(25),
      border: affirmation.styleIndex == 1
          ? Border.all(
              color: Color(affirmation.textColorValue).withValues(alpha: .6),
              width: 1.5,
            )
          : null,
    ),
    child: Stack(
      children: [
        if (affirmation.styleIndex == 1)
          Positioned(
            top: -15,
            right: 0,
            child: Text(
              '“',
              style: TextStyle(
                color: Color(affirmation.textColorValue).withValues(alpha: .16),
                fontSize: 76,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (affirmation.styleIndex == 2)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Color(affirmation.textColorValue).withValues(alpha: .7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
            ),
          ),
        if (affirmation.styleIndex == 3)
          Positioned(
            top: 8,
            right: 4,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(
                    affirmation.textColorValue,
                  ).withValues(alpha: .18),
                  width: 5,
                ),
              ),
            ),
          ),
        if (affirmation.styleIndex == 4)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: Color(affirmation.textColorValue).withValues(alpha: .32),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        if (affirmation.styleIndex == 5)
          Positioned(
            bottom: 34,
            left: 12,
            right: 12,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Color(affirmation.textColorValue).withValues(alpha: .22),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        if (affirmation.styleIndex == 6)
          Positioned(
            top: 5,
            right: 2,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: Color(affirmation.textColorValue).withValues(alpha: .2),
            ),
          ),
        if (affirmation.styleIndex == 7)
          Positioned(
            bottom: 30,
            left: 2,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 32,
              color: Color(affirmation.textColorValue).withValues(alpha: .18),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            0,
            affirmation.styleIndex == 2 ? 7 : 0,
            0,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (affirmation.eyebrow != null) ...[
                Text(
                  affirmation.eyebrow!,
                  style: TextStyle(
                    color: Color(affirmation.textColorValue),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textStyle = TextStyle(
                      color: Color(affirmation.textColorValue),
                      fontFamily: 'Georgia',
                      height: 1.25,
                      fontStyle: affirmation.styleIndex == 6
                          ? FontStyle.italic
                          : FontStyle.normal,
                      fontWeight: FontWeight.w700,
                    );
                    final fittedTextSize = _fitAffirmationTextSize(
                      text: affirmation.text,
                      style: textStyle,
                      preferredSize: textSize,
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                      textScaler: MediaQuery.textScalerOf(context),
                      textDirection: Directionality.of(context),
                    );
                    return Center(
                      child: Text(
                        affirmation.text,
                        textAlign: affirmation.styleIndex == 4
                            ? TextAlign.left
                            : TextAlign.center,
                        style: textStyle.copyWith(fontSize: fittedTextSize),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  affirmation.formattedDate,
                  style: TextStyle(
                    color: Color(affirmation.textColorValue),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

double _fitAffirmationTextSize({
  required String text,
  required TextStyle style,
  required double preferredSize,
  required double maxWidth,
  required double maxHeight,
  required TextScaler textScaler,
  required TextDirection textDirection,
}) {
  var candidateSize = preferredSize;
  while (candidateSize > 7) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: candidateSize),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    if (painter.height <= maxHeight) return candidateSize;
    candidateSize -= .5;
  }
  return 7;
}
