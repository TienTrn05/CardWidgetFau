import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/presentation/pages/logo_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/slide_right_transition.dart';
import 'package:carwidget/features/catalog/presentation/widgets/logo_widget_content.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show addLogoWidgetToMyWidgets;
import 'package:flutter/material.dart';

const _previewItemCount = 6;

class LogosSection extends StatelessWidget {
  const LogosSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Logos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SeeAllButton(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const LogosPage())),
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
              itemCount: logoWidgetModels.length < _previewItemCount
                  ? logoWidgetModels.length
                  : _previewItemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox.square(
                dimension: cardSize,
                child: _LogoTile(model: logoWidgetModels[index]),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class LogosPage extends StatefulWidget {
  const LogosPage({super.key});

  @override
  State<LogosPage> createState() => _LogosPageState();
}

class _LogosPageState extends State<LogosPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredLogos = logoWidgetModels
        .where(
          (model) => model.nameLogo.toLowerCase().contains(
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
          'Logos',
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
                    hintText: 'Search logo name',
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
                  if (filteredLogos.isEmpty) {
                    return const Center(
                      child: Text(
                        'No logos found',
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
                    itemCount: filteredLogos.length,
                    itemBuilder: (context, index) => _LogoGridTile(
                      model: filteredLogos[index],
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

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.model});

  final LogoWidgetModel model;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF252D33),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => _openLogoEditor(context, model),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF303940)),
        ),
        child: LogoWidgetTileContent(model: model),
      ),
    ),
  );
}

class _LogoGridTile extends StatelessWidget {
  const _LogoGridTile({required this.model, required this.cardWidth});

  final LogoWidgetModel model;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: cardWidth,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLogoEditor(context, model),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            SizedBox.square(
              dimension: cardWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF252D33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF303940)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: LogoArtwork(model: model),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: Text(
                model.nameLogo,
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
      ),
    ),
  );
}

void _openLogoEditor(BuildContext context, LogoWidgetModel model) {
  showSlideRightDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: LogoWidgetEditorPage(
        model: model,
        onAdd: (result) => addLogoWidgetToMyWidgets(
          model,
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
