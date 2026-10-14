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
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
                child: Center(
                  child: Text(
                    affirmation.text,
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(affirmation.textColorValue),
                      fontFamily: 'Georgia',
                      fontSize: textSize,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
