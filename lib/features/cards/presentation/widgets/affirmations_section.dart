import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/cards/data/models/affirmation_model.dart';
import 'package:carwidget/features/cards/presentation/pages/affirmation_settings_page.dart';
import 'package:carwidget/features/cards/presentation/widgets/affirmation_card_artwork.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart';
import 'package:flutter/material.dart';

class AffirmationsSection extends StatelessWidget {
  const AffirmationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final affirmations = buildDailyAffirmations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Affirmations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AffirmationsPage(affirmations: affirmations),
                  ),
                ),
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
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: affirmations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: 150,
              child: _AffirmationTile(affirmation: affirmations[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class AffirmationsPage extends StatelessWidget {
  const AffirmationsPage({super.key, required this.affirmations});

  final List<AffirmationModel> affirmations;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      title: const Text('Affirmations'),
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardSize = (constraints.maxWidth - 48 - 24) / 3;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              mainAxisExtent: cardSize,
            ),
            itemCount: affirmations.length,
            itemBuilder: (context, index) =>
                _AffirmationTile(affirmation: affirmations[index]),
          );
        },
      ),
    ),
  );
}

class _AffirmationTile extends StatelessWidget {
  const _AffirmationTile({required this.affirmation});

  final AffirmationModel affirmation;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openSettings(context, affirmation),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AffirmationCardArtwork(affirmation: affirmation, textSize: 14),
      ),
    ),
  );
}

Future<void> _openSettings(
  BuildContext context,
  AffirmationModel affirmation,
) async {
  final result = await Navigator.of(context).push<AffirmationModel>(
    MaterialPageRoute<AffirmationModel>(
      builder: (_) => AffirmationSettingsPage(affirmation: affirmation),
    ),
  );
  if (result != null) addAffirmationToMyWidgets(result);
}
