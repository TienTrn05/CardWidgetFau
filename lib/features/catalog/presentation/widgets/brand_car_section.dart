import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/cards/data/car_catalog.dart';
import 'package:carwidget/features/catalog/data/models/saved_widget_model.dart';
import 'package:carwidget/features/catalog/data/models/widget_type.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/editor/presentation/pages/brand_car_editor_page.dart';
import 'package:carwidget/features/editor/data/services/brand_car_layout_store.dart';
import 'package:carwidget/features/editor/domain/models/brand_car_layout.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart';
import 'package:flutter/material.dart';

class BrandCarSection extends StatelessWidget {
  const BrandCarSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Brand Car',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SeeAllButton(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BrandCarWidgetsPage(),
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
              itemCount: brandCarWidgetModels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox.square(
                dimension: cardSize,
                child: _BrandCarWidgetTile(widget: brandCarWidgetModels[index]),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class BrandCarWidgetsPage extends StatefulWidget {
  const BrandCarWidgetsPage({super.key});

  @override
  State<BrandCarWidgetsPage> createState() => _BrandCarWidgetsPageState();
}

class _BrandCarWidgetsPageState extends State<BrandCarWidgetsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late final Map<String, List<SavedWidgetModel>> _templatesByBrand = {
    for (final brand in carBrandNames)
      brand: List.generate(
        3,
        (index) => SavedWidgetModel(
          id: 'brand_catalog_${_brandSlug(brand)}_${index + 1}',
          label: brand.toUpperCase(),
          type: WidgetType.carLogoAndName,
        ),
      ),
  };

  @override
  void initState() {
    super.initState();
    final layouts = Map<String, BrandCarLayout>.of(brandCarLayouts.value);
    for (final templates in _templatesByBrand.values) {
      for (var index = 0; index < templates.length; index++) {
        final layoutId = brandCarDraftLayoutId(templates[index].id);
        layouts.putIfAbsent(layoutId, () => _brandCarTemplateLayout(index));
      }
    }
    brandCarLayouts.value = layouts;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredBrands => carBrandNames
      .where(
        (brand) =>
            brand.toLowerCase().contains(_searchQuery.trim().toLowerCase()),
      )
      .toList();

  void _scrollToLetter(
    String letter,
    Map<String, List<String>> brandsByLetter,
    List<String> letters,
    double cardWidth,
  ) {
    if (!_scrollController.hasClients) return;
    final index = letters.indexOf(letter);
    if (index < 0) return;
    final precedingHeight = letters.take(index).fold<double>(0, (height, key) {
      final brandCount = brandsByLetter[key]!.length;
      return height + 53 + brandCount * (cardWidth + 38);
    });
    final target = precedingHeight.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'Brand Car',
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search brand name',
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
                    borderSide: const BorderSide(color: Color(0xFF39424A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.green),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 68) / 3;
                final brands = _filteredBrands;
                if (brands.isEmpty) {
                  return const Center(
                    child: Text(
                      'No brands found',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                final brandsByLetter = <String, List<String>>{};
                for (final brand in brands) {
                  brandsByLetter
                      .putIfAbsent(brand[0].toUpperCase(), () => [])
                      .add(brand);
                }
                final letters = brandsByLetter.keys.toList();
                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 36, 24),
                      itemCount: letters.length,
                      itemBuilder: (context, index) {
                        final letter = letters[index];
                        return _BrandLetterSection(
                          letter: letter,
                          brands: brandsByLetter[letter]!,
                          cardWidth: cardWidth,
                          templatesByBrand: _templatesByBrand,
                        );
                      },
                    ),
                    if (_searchQuery.trim().isEmpty)
                      Positioned(
                        right: 3,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _BrandAlphabetRail(
                            letters: letters,
                            onLetterTap: (letter) => _scrollToLetter(
                              letter,
                              brandsByLetter,
                              letters,
                              cardWidth,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

String _brandSlug(String brand) => brand
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

BrandCarLayout _brandCarTemplateLayout(int index) => switch (index) {
  0 => const BrandCarLayout(
    greeting: WidgetElementPosition(-0.58, -0.62),
    brand: WidgetElementPosition(0.58, -0.62),
    car: WidgetElementPosition(0, 0.16),
    location: WidgetElementPosition(0.58, 0.78),
    brandScale: 0.72,
    carImageIndex: 0,
  ),
  1 => const BrandCarLayout(
    greeting: WidgetElementPosition(-0.58, -0.62),
    brand: WidgetElementPosition(0, -0.08),
    car: WidgetElementPosition(0, 0.5),
    location: WidgetElementPosition(0.58, -0.62),
    brandScale: 0.72,
    carImageIndex: 0,
  ),
  _ => const BrandCarLayout(
    greeting: WidgetElementPosition(-0.58, 0.62),
    brand: WidgetElementPosition(0, -0.72),
    car: WidgetElementPosition(0, -0.08),
    location: WidgetElementPosition(0.58, 0.78),
    brandScale: 0.72,
    carImageIndex: 0,
  ),
};

class _BrandCarGroup extends StatelessWidget {
  const _BrandCarGroup({
    required this.brand,
    required this.cardWidth,
    required this.templates,
  });

  final String brand;
  final double cardWidth;
  final List<SavedWidgetModel> templates;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          for (var index = 0; index < templates.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            SizedBox.square(
              dimension: cardWidth,
              child: _BrandCarWidgetTile(widget: templates[index]),
            ),
          ],
        ],
      ),
    ],
  );
}

class _BrandLetterSection extends StatelessWidget {
  const _BrandLetterSection({
    required this.letter,
    required this.brands,
    required this.cardWidth,
    required this.templatesByBrand,
  });

  final String letter;
  final List<String> brands;
  final double cardWidth;
  final Map<String, List<SavedWidgetModel>> templatesByBrand;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final brand in brands)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BrandCarGroup(
              brand: brand,
              cardWidth: cardWidth,
              templates: templatesByBrand[brand]!,
            ),
          ),
      ],
    ),
  );
}

class _BrandAlphabetRail extends StatelessWidget {
  const _BrandAlphabetRail({required this.letters, required this.onLetterTap});

  final List<String> letters;
  final ValueChanged<String> onLetterTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xE51A222D),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final letter in letters)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onLetterTap(letter),
            child: SizedBox(
              width: 16,
              height: 19,
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Color(0xFF1685FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(6, 0),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 4.5),
          child: Text(
            'See All',
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _BrandCarWidgetTile extends StatelessWidget {
  const _BrandCarWidgetTile({required this.widget});

  final SavedWidgetModel widget;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF20272D),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => showBrandCarWidgetEditor(context, widget),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF303940)),
        ),
        child: SavedWidgetArtwork(
          widget: widget,
          layoutId: brandCarDraftLayoutId(widget.id),
        ),
      ),
    ),
  );
}
