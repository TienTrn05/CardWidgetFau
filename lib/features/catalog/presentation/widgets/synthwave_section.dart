import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/features/catalog/data/models/synthwave_model.dart';
import 'package:carwidget/features/catalog/presentation/pages/synthwave_editor_page.dart';
import 'package:carwidget/features/catalog/presentation/widgets/carplay_preview_metrics.dart';
import 'package:carwidget/features/catalog/presentation/widgets/slide_right_transition.dart';
import 'package:carwidget/features/catalog/presentation/widgets/synthwave_artwork.dart';
import 'package:carwidget/features/my_widgets/presentation/widgets/my_widgets_section.dart'
    show addSynthwaveToMyWidgets;
import 'package:flutter/material.dart';

class SynthwaveSection extends StatelessWidget {
  const SynthwaveSection({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Synthwave',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(6, 0),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SynthwavePage(),
                  ),
                ),
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
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final size = carPlayWidgetPreviewSize(context, constraints.maxWidth);
          return SizedBox(
            height: size,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: synthwaveModels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => SizedBox.square(
                dimension: size,
                child: _SynthwaveTile(model: synthwaveModels[index]),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class SynthwavePage extends StatefulWidget {
  const SynthwavePage({super.key});

  @override
  State<SynthwavePage> createState() => _SynthwavePageState();
}

class _SynthwavePageState extends State<SynthwavePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final models = synthwaveModels
        .where(
          (item) =>
              item.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Synthwave',
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
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search synthwave',
                  hintStyle: const TextStyle(color: AppColors.muted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.muted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF252D33),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: models.isEmpty
                  ? const Center(
                      child: Text(
                        'No synthwave widgets found',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 48 - 24) / 3;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 14,
                                mainAxisExtent: width + 24,
                              ),
                          itemCount: models.length,
                          itemBuilder: (context, index) => Column(
                            children: [
                              SizedBox.square(
                                dimension: width,
                                child: _SynthwaveTile(model: models[index]),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 18,
                                child: Text(
                                  models[index].name,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
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

class _SynthwaveTile extends StatelessWidget {
  const _SynthwaveTile({required this.model});
  final SynthwaveModel model;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF252D33),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: () => showSlideRightDialog<void>(
        context: context,
        builder: (_) => Dialog.fullscreen(
          backgroundColor: AppColors.background,
          child: SynthwaveEditorPage(
            model: model,
            onAdd: (result) => addSynthwaveToMyWidgets(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SynthwaveArtwork(synthwaveId: model.id),
        ),
      ),
    ),
  );
}
