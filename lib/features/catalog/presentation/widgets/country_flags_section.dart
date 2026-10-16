import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/country_flag_model.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/slide_right_transition.dart';
import 'package:carwidget/features/catalog/presentation/pages/country_flag_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/country_flag_artwork.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show addCountryFlagToMyWidgets;
import 'package:flutter/material.dart';

const _previewItemCount = 6;

class CountryFlagsSection extends StatelessWidget {
  const CountryFlagsSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Country Flags',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(6, 0),
            child: _SeeAllButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CountryFlagsPage(),
                ),
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
              itemCount: countryFlagModels.length < _previewItemCount
                  ? countryFlagModels.length
                  : _previewItemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox.square(
                dimension: cardSize,
                child: _CountryFlagTile(flag: countryFlagModels[index]),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class CountryFlagsPage extends StatefulWidget {
  const CountryFlagsPage({super.key});

  @override
  State<CountryFlagsPage> createState() => _CountryFlagsPageState();
}

class _CountryFlagsPageState extends State<CountryFlagsPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredFlags = countryFlagModels
        .where(
          (flag) => flag.name.toLowerCase().contains(
            _searchQuery.trim().toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Country Flags',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
              child: SizedBox(
                height: 46,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search country',
                    hintStyle: const TextStyle(color: AppColors.muted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252D33),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF39424A),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.green,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 48 - 24) / 3;
                  final itemHeight = cardWidth + 24;
                  if (filteredFlags.isEmpty) {
                    return const Center(
                      child: Text(
                        'No countries found',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      mainAxisExtent: itemHeight,
                    ),
                    itemCount: filteredFlags.length,
                    itemBuilder: (context, index) => _CountryFlagGridTile(
                      flag: filteredFlags[index],
                      cardWidth: cardWidth,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryFlagTile extends StatelessWidget {
  const _CountryFlagTile({required this.flag});

  final CountryFlagModel flag;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF252D33),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => _openCountryFlagEditor(context, flag),
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Semantics(
          label: '${flag.name} flag',
          child: CountryFlagArtwork(countryCode: flag.code),
        ),
      ),
    ),
  );
}

class _CountryFlagGridTile extends StatelessWidget {
  const _CountryFlagGridTile({required this.flag, required this.cardWidth});

  final CountryFlagModel flag;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: cardWidth,
    child: Column(
      children: [
        SizedBox.square(
          dimension: cardWidth,
          child: _CountryFlagTile(flag: flag),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 18,
          child: Text(
            flag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

void _openCountryFlagEditor(BuildContext context, CountryFlagModel flag) {
  showSlideRightDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: CountryFlagEditorPage(
        model: flag,
        onAdd: (result) => addCountryFlagToMyWidgets(
          flag,
          borderGradientIndex: result.borderGradientIndex,
          borderOpacity: result.borderOpacity,
        ),
      ),
    ),
  );
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
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
  );
}
