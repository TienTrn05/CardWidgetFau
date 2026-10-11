import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:flutter/material.dart';

class LogoWidgetTileContent extends StatelessWidget {
  const LogoWidgetTileContent({super.key, required this.model});

  final LogoWidgetModel model;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(child: LogoArtwork(model: model)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 20,
          child: Center(
            child: Text(
              model.nameLogo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class LogoArtwork extends StatelessWidget {
  const LogoArtwork({super.key, required this.model});

  final LogoWidgetModel model;

  @override
  Widget build(BuildContext context) {
    final imageAsset = model.imageAsset;
    if (imageAsset != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _LogoMark(model: model),
        ),
      );
    }
    return _LogoMark(model: model);
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.model});

  final LogoWidgetModel model;

  @override
  Widget build(BuildContext context) {
    final isAbarth = model.id.startsWith('logo_abarth');
    final isAcura = model.id.startsWith('logo_acura');
    final accent = isAbarth
        ? const Color(0xFFE9C900)
        : isAcura
        ? const Color(0xFFBFC9D5)
        : AppColors.green;

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isAbarth)
              Icon(Icons.shield_rounded, color: accent, size: 94)
            else if (isAcura)
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 2),
                ),
              )
            else
              Container(
                width: 102,
                height: 54,
                decoration: BoxDecoration(
                  border: Border.all(color: accent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  model.symbol,
                  style: TextStyle(
                    color: isAbarth ? Colors.black : accent,
                    fontSize: model.symbol.length > 3 ? 15 : 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
