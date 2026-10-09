import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/logo_widget_model.dart';
import 'package:carwidget/features/catalog/presentation/pages/logo_widget_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/logo_widget_content.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show addLogoWidgetToMyWidgets;
import 'package:flutter/material.dart';

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
              itemCount: logoWidgetModels.length,
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
                  final cardSize = carPlayWidgetPreviewSize(
                    context,
                    constraints.maxWidth - 48,
                  );
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
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 18,
                      mainAxisExtent: cardSize,
                    ),
                    itemCount: filteredLogos.length,
                    itemBuilder: (context, index) => Center(
                      child: SizedBox.square(
                        dimension: cardSize,
                        child: _LogoTile(model: filteredLogos[index]),
                      ),
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
      onTap: () => showDialog<void>(
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
      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
        child: Text(
          'See All',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
